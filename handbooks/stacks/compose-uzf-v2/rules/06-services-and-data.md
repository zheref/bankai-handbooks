<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 06 — Services, Repositories & the Data Layer

## Repo-specific placeholders

- `{{DI_FRAMEWORK}}` — the stack's dependency-injection framework (e.g. Hilt). Its
  binding annotations (`@Inject`, `@Binds`, module classes) are the concrete idiom used below.
- Otherwise **none** — this rule carries no repo-specific paths, hosts, targets, or product
  names. The example domain types (`SuggestionService`, `Suggestion`, `EnvironmentProvider`, …)
  are illustrative, not repo config.

Implements `UZF-16` (external systems behind a DI'd Service with a stub; Repository as the only
stateful service-tier artifact) and `UZF-17` (wire types translated by a Mapper), tightened for
Kotlin/Compose by `KT-10` (Service shape), `KT-19` (wire primitives) / `KT-20` (Mapper) and `KT-12`
(synchronous Providers).

## Service (`KT-10` implements `UZF-16`)

Every external system — network, storage, sensors, third-party SDKs, `Context`-bound system
frameworks — is wrapped behind an interface whose operations suspend and return `Result`:

```kotlin
interface <X>Service {
    suspend fun <op>(...): Result<…>
}
```

- **Two implementations minimum** per Service:
  - `class Live<X>Service @Inject constructor(...) : <X>Service` — the production binding.
  - `class Stubbed<X>Service(scenario: …) : <X>Service` — the test/preview binding. It exposes a
    `sealed class Scenario` so tests and previews can pick happy / empty / throws variants
    deterministically. A Service that ships **Live-only is incomplete**.
- Bound via `{{DI_FRAMEWORK}}`: `@Binds` in a `services/<X>/<X>ServiceModule.kt`.
- **Stateless.** No caches, no in-flight tracking, no mutable fields. If you need any of that,
  promote the concern to a Repository.
- The Service — not feature code — is responsible for translating thrown errors into `Result`
  (`runCatching { … }` lives here, never in a Producer or reducer; see Forbidden).

```kotlin
interface SuggestionService {
    suspend fun loadForNow(): Result<List<Suggestion>>
}

class LiveSuggestionService @Inject constructor(
    private val api:    SuggestionApi,
    private val mapper: SuggestionMapper,
) : SuggestionService {
    override suspend fun loadForNow(): Result<List<Suggestion>> = runCatching {
        api.fetchForNow().map(mapper::toDomain)
    }
}

class StubbedSuggestionService(
    private val scenario: Scenario = Scenario.Happy(emptyList()),
) : SuggestionService {
    sealed class Scenario {
        data class Happy(val items: List<Suggestion>) : Scenario()
        data class Throws(val error: Throwable)       : Scenario()
    }
    override suspend fun loadForNow(): Result<List<Suggestion>> = when (val s = scenario) {
        is Scenario.Happy  -> Result.success(s.items)
        is Scenario.Throws -> Result.failure(s.error)
    }
}
```

### Promote helper objects to a Service (`KT-10`)

Application-specific stores, resolvers, and "helper objects" that play the role of a Service
**must** be promoted to `interface <X>Service` form. Naming like `…Store`, `…Resolver`, or
`…Holder` is reserved for `Provider`-tier synchronous helpers (see Providers below). When you find
a bare data class or helper injected into a Feature by hand:

- If it **suspends or touches I/O** → make it a `…Service` (interface + `Live` + `Stubbed`).
- If it is **synchronous and cheap** → make it a `…Provider`.
- Never leave it as an un-abstracted constructor argument.

## Repository (`UZF-16`)

- A class-based coordinator across **two or more** Services, `{{DI_FRAMEWORK}}`-bound.
- The **only** service-tier type allowed to hold state — caches, dedupe, in-flight token-refresh
  tracking — and only when the coordination genuinely requires it.
- **Empty / placeholder Repositories are forbidden.** Delete them until they have a real
  coordination job.
- When a Repository does hold state, document it inline at the field:
  `// State holder: dedup pending fetches.`

## Provider (`KT-12`)

- A `…Provider` returns values **synchronously**: `fun current(): X`. Anything that could suspend
  or block must be a Service instead.
- Reducers **may** call Providers (they are cheap and synchronous). Reducers **may not** call
  Services (which suspend and are expensive).
- Examples: `EnvironmentProvider`, `IntegrationAvailabilityProvider`, `ClockProvider`.

## Api / Database / Endpoint / Query / Mutation (`KT-19`)

These are the raw wire/persistence primitives. They are **wrapped by a Service before any feature
code uses them**:

| Primitive | Shape |
| --- | --- |
| `interface <X>Api` | Retrofit network interface |
| `class <X>Database` | Room `@Database` wrapper |
| `<X>Endpoint` | a `sealed interface` — introduce **only** when route enumeration is needed app-wide |
| `@Query suspend fun …Query(...)` | DAO read |
| `@Upsert` / `@Insert` / `@Delete suspend fun …Mutation(...)` | DAO write (prefer `@Upsert` over manual insert + update) |

- Prefer `kotlinx.serialization` for `…Response` types and Retrofit's
  `kotlinx-serialization-converter` at the boundary.
- **No feature code imports `retrofit2.*` or `androidx.room.*`** (nor `android.content.SharedPreferences`).
  These stay behind the Service tier; a Detekt/Konsist rule enforces it outside `services/`.

## Mapper (`KT-20` implements `UZF-17`)

A DI-registered class that owns the translation between wire and domain, with three functions:

- `fun toDomain(<X>Response): <X>Model`
- `fun fromDomain(<X>Model): <X>Response`
- `fun toException(t: Throwable): <X>Exception`

- Lives next to the model under `models/`.
- Reducers and Producers translate a `Throwable` into a `<Feature>Exception` **via the Mapper**,
  never by hand. Reducers never throw: every `Throwable` surfaces through the `Result<T>` a Service
  returns and is mapped to an `…Exception` at the integration point.
- Keep the type families separated across the boundary: a domain `<X>Model` never gets a
  serialization (`@Serializable`) conformance, and a wire `<X>Response` never leaks a UI/domain
  concern. Wire errors normalize to `sealed class …Error : Throwable()`; feature-facing failures
  are `sealed class …Exception(message, recoverable)`.
- Domain models ship their own `mock*` companion fixtures (≥ 7 variants — happy, empty, long,
  non-ASCII, missing optional fields, stale-timestamp, just-updated) in a `// region Mocks` band,
  so Services' `Stubbed` scenarios and previews consume real fixtures rather than inline literals.

## DI module layout

- Prefer **one `{{DI_FRAMEWORK}}` module per feature folder**, named `<Feature>Module.kt`.
- Cross-feature wiring — Retrofit / OkHttp clients, Room `@Database` instances — lives in a shared
  `library/di/` package, not inside a feature.

## Forbidden

- Feature code that imports `retrofit2.*`, `androidx.room.*`, or `android.content.SharedPreferences`
  (`KT-19`).
- A `Repository` with no body / no behavior (`UZF-16`).
- A `Service` without a `Stubbed` impl — Live-only is incomplete (`KT-10`).
- A `Service` that holds mutable state — move the state into a Repository (`KT-10` / `UZF-16`).
- Inline `Result.failure(…)` / `runCatching { … }` blocks in features. The Service owns translation
  to `Result` (`KT-10`).
- A `…Store` / `…Resolver` / `…Holder` injected directly into a Feature without an
  `interface …Service` or `interface …Provider` abstraction (`KT-10`).
- A reducer that calls a Service, or a Provider that suspends/blocks (`KT-12`).
