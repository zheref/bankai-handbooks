# Stack: `compose-uzf-v2` — Jetpack Compose + UZF Architecture Handbook

Concrete UZF bindings for **Android Jetpack Compose, Kotlin 2.1+, Hilt,
Coroutines/Flow, Supabase/Ktor + Room**, under **UZF v2**. Sasuke cites these as
`KT-{n}`, from the one registry below. They **implement** the cross-platform rules in
[`../../uzf-core.md`](../../uzf-core.md) (`UZF-{n}`) with Compose/Kotlin specifics —
a `KT-{n}` rule may tighten but never contradict its `UZF-{n}` parent.

Reference implementation: a live, private Android product recorded in the consumer
registry (its rules + the `SYNTHESIS_JETPACK_COMPOSE_v2` conception doc). Existing `…ViewModel` classes are grandfathered
but must be renamed to `…Feature` when materially edited. Rule numbers are
append-only.

---

## KT-n rule registry (canonical)

This file is the stack's **one append-only `KT-{n}` list**. The bold rules below are the registry:
one id, one meaning, never renumbered, never reused. The rule files under [`rules/`](rules/) expand
these ids and cite them; they mint none. A new Compose rule takes the next free number here
(`KT-30` onward).

*Numbering note (re-pointed at `v0.13`, zheref/bankai-handbooks#11).* Up to `v0.12` this file's bold
rules carried an older numbering, `KT-1`…`KT-14`, while `rules/README.md` held the canonical
`KT-1`…`KT-29` registry. Under the same id the two gave different meanings. The registry's numbering
was kept and moved here, so no rule file's citation changed. A citation read against this file
before `v0.13` maps as follows:

| Old id (this file, ≤ `v0.12`) | Registry id now |
|---|---|
| `KT-1` Feature subclass | `KT-3` |
| `KT-2` single `onEvent` entry point, `KT-3` pure `reduce` | `KT-5` |
| `KT-4` State | `KT-4` (unchanged) |
| `KT-5` Shifters | `KT-6` |
| `KT-6` Selectors | `KT-7` |
| `KT-7` Producers, `KT-8` effects | `KT-8` |
| `KT-9` `UiEffect` | `KT-9` (unchanged) |
| `KT-10` Page/Screen split | `KT-1`, `KT-2` |
| `KT-11` previews and hard-coded design values | `KT-13`, `KT-14` |
| `KT-12` Services, Repositories, Providers | `KT-10`, `KT-11`, `KT-12`, `KT-19` |
| `KT-13` Mapper and the wire/storage boundary | `KT-19`, `KT-20`, `KT-21` |
| `KT-14` testing | `KT-22`, `KT-18` |

The history of how the three earlier local numberings were reconciled into this sequence stays in
[`rules/README.md` → *KT-n numbering collision*](rules/README.md#kt-n-numbering-collision--how-it-was-resolved).

## A. Renderer and Feature (implements UZF-1, UZF-4, UZF-7)

**KT-1 — Pages are stateless; Screens are the stateful wrapper.** A feature with UI is a
stateless `@Composable fun <Name>Page(state, onEvent, modifier)` (a passive renderer, preview-
and Paparazzi-testable) plus a stateful `@Composable fun <Name>Screen(...)`. The Screen is the
only Hilt/lifecycle/nav touchpoint: it `hiltViewModel()`s the Feature (named `store`),
`collectAsStateWithLifecycle()`s the state, routes `uiEffects` to callbacks, passes
`store::send`, and carries no layout. Unlike SwiftUI `SW-1`, `…Page.kt` is kept.

**KT-2 — Pages are navigation- and DI-free.** A Page's parameters are **exactly**
`(state, onEvent, modifier)`, and it imports no `androidx.navigation.*`/`androidx.hilt.*`/
`androidx.lifecycle.*`/`dagger.*`/`Context`. A `@Composable` that calls `hiltViewModel()` or
navigates is a Screen, not a Page.

**KT-3 — One `Feature` subclass per screen.** `<Name>Feature`, `@HiltViewModel`,
inheriting the project-agnostic `Feature<State, Event, UiEffect>` base from
`library/uzf/`; obtained in Composables via `hiltViewModel()`. Never
`remember { …Feature() }` or `viewModel()`.

## B. State and the event loop (implements UZF-2, UZF-8, UZF-9, UZF-12, UZF-13)

**KT-4 — State is an immutable `data class` exposed as `StateFlow`.** `val`-only,
domain types only (never `Throwable`, `Response<…>`, `Job`, or mutable
collections). Read in Compose with `collectAsStateWithLifecycle()`, never plain
`collectAsState()`.

**KT-5 — A single `onEvent(event)` entry point, and a 100% pure `reduce` that returns an
`Outcome`.** `onEvent` (and its view-layer alias `send`) are `final` on the base; subclasses
implement only `protected fun reduce(state, event)`. There is exactly one entry point — no
`setX(...)`/`markY(...)`/`clearZ(...)` and no second `onEvent`-style method. `reduce` returns
`Outcome<State, Event, UiEffect>` (`Idle` / `UpdatedState` / `NewEffect` / `Both`, built via
the `idle`/`updatedState`/`newEffect`/`outcome` factories — never hand-constructed). No
`viewModelScope`, no `signal`, no I/O, no `_state.value =` inside `reduce`.

## C. Shifters and Selectors (implements UZF-10, UZF-11)

**KT-6 — Shifters are `State.with…()` copy functions.** In `<Name>Shifters.kt`:
`fun State.with…(): State = copy(...)`, one concern each, `with…`/`as…` prefixes.
No inline `copy(...)` or `updateState {}` in `reduce`. Shifters read no clock/random/env/service.

**KT-7 — Selectors are top-level `select…(state)` functions.** In
`<Name>Selectors.kt`, consumed in Compose via
`remember(state) { derivedStateOf { select…(state) } }` to scope recomposition.

## D. Effects, Producers and UiEffect (implements UZF-3, UZF-4, UZF-14, UZF-15)

**KT-8 — Producers are injected effect factories; effects run in `viewModelScope` and dispatch
back through `onEvent`.** `<Name>Producer.kt`, `@Inject`, plain-verb methods returning
`FlowEffect<E>` (`Effect.OfFlow`) or `ThunkEffect<E,U>` (`Effect.OfThunk`, a
`suspend (Sink<E,U>) -> Unit`). No I/O at construction; never touch
Retrofit/Room/SharedPreferences/`Context` outside a Producer. An effect never sets
`_state.value` directly; it calls `sink.dispatch(On…Completed(result))`. Producers never
throw — failures are `Result.failure` dispatched as a single `On…Completed(Result)` event
(success/failure encoded in the `Result`, per UZF-3), translated to `<Name>Exception` via a
Mapper inside `reduce`.

**KT-9 — `UiEffect` is a separate sealed type on a `MutableSharedFlow(replay = 0,
extraBufferCapacity ≥ 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)`.**
Navigation, snackbars, and toasts are `UiEffect`s, **never** State, never a
`Channel`, never `replay >= 1`. Emitted only via `sink.signal(...)`
inside a `ThunkEffect`; a `FlowEffect` cannot signal (its `U = Nothing`). The
Screen consumes `uiEffects` via `LaunchedEffect` and routes them to callbacks.

## E. Services, Repositories and Providers (implements UZF-16)

**KT-10 — Services are interfaces with ≥2 impls, Hilt-bound.** `interface
<X>Service { suspend fun …: Result<…> }` + `Live<X>Service @Inject` + a
`Stubbed<X>Service` (with a `sealed class Scenario`), bound via `@Binds`. Services are
**stateless**. Helper `…Store`/`…Resolver`/`…Holder` objects that suspend or hit I/O are
promoted to a Service.

**KT-11 — Repositories coordinate ≥2 Services.** A Repository holds the only service-tier
mutable state, and only when strictly required. Empty (single-Service pass-through)
Repositories are forbidden.

**KT-12 — Providers are synchronous-only.** A `Provider` (`fun current(): X`) is the only
service-tier type `reduce` may read; a reducer never calls a Service.

## F. Previews, theme, navigation and signals (implements UZF-4, UZF-18, UZF-26)

**KT-13 — ≥3 `@Preview` per Page, from `<Name>Mocks`.** Loading / loaded / errored
variations minimum, built from `<Name>Mocks.kt` (never inline `State` in a
preview/test), mirrored 1:1 by Paparazzi snapshots.

**KT-14 — Theme is applied once at the root.** `MaterialTheme`/`AppTheme` is set up once;
colors, sizes and typography come from the theme (`object AppTheme`), never hard-coded in a
Page or Fragment.

**KT-15 — Navigation is routed, never called from logic.** Navigation goes through a
`NavigationService` or a Screen callback (`UiEffect` → callback); `reduce` never touches a
`NavController`.

**KT-16 — No global event buses for feature concerns.** View-tier signals (including
`Toast`/`Snackbar`) travel on the feature's `UiEffect` and are routed by the Screen;
Composables never call `Toast.makeText(...)`. Narrow carve-out: orphan app-wide singletons
with no UI parent, and cross-cutting telemetry.

## G. DI layering and mocks (implements UZF-18)

**KT-17 — One Hilt module per feature folder.** `<Feature>Module.kt`; cross-feature and infra
wiring (Retrofit/OkHttp/Room DB) lives in `library/di/`.

**KT-18 — A `<Feature>Mocks.kt` per feature, and ≥7 `mock*` fixtures per domain Model.**
The Mocks file vends canned `State` variants; every domain Model ships ≥7 fixtures
(happy/empty/long/non-ASCII/missing-optional/stale/fresh) in a `// region Mocks`
(Detekt-strippable) band. State is built from Mocks, never inline.

## H. The wire and storage boundary (implements UZF-8, UZF-17)

**KT-19 — Wire and persistence types live behind a Service.** Network → Ktor/Retrofit `Api`
returning `@Serializable data class …Response`; storage → Room `@Dao` with `…Query`
(`@Query`) and `…Mutation` (`@Upsert/@Insert/@Delete`) operations over `@Entity`; an
`Endpoint`. Feature code never imports `retrofit2.*`/`androidx.room.*`/`SharedPreferences`.

**KT-20 — Wire ↔ domain via a Mapper.** A DI-registered pure class with
`toDomain`/`fromDomain`/`toException`; a raw `…Error : Throwable()` translates to a domain
`…Exception(message, recoverable)` at the boundary — reducers never throw.

**KT-21 — Domain Models hold domain types only.** No `@Serializable`/`@Entity`/`@SerialName`
on a domain Model (they belong on `Response`/`Entity`); one model per file.

## I. Testing (implements UZF-18, UZF-19, UZF-20)

**KT-22 — JUnit5 + Turbine + Paparazzi.** ≥3 tests per Shifter/Selector/
Producer-method/Mapper-fn/reducer-arm and per Feature `Event`; the Feature is tested through
Turbine on state + `uiEffects`; each Page has Paparazzi snapshots matching its `@Preview`
count. Forbidden: Robolectric, `runBlocking` (use `runTest`), inline-`State` tests, tests
hitting Retrofit/Room without a `Stubbed` boundary, a long-lived `@Ignore`, and
`BuildConfig.DEBUG` test-outcome branching.

## J. Hilt and coroutines (implements UZF-16)

**KT-23 — Hilt bootstrap.** A `@HiltAndroidApp {{PROJECT_NAME}}Application` and a single
`@AndroidEntryPoint` Activity hosting the Compose tree.

**KT-24 — Binding conventions.** `@InstallIn`-scoped modules, `@Binds` over `@Provides`,
`@Singleton` only where required; a `Stubbed` impl is swapped in via `@TestInstallIn`; no
empty modules.

**KT-25 — Constructor injection only.** No field injection, no Service Locator.

**KT-26 — Structured concurrency only.** No `LiveData`, no `runBlocking` outside tests, no
`GlobalScope.launch`, no `viewModelScope.launch { service.x() }` inside a Feature.

**KT-27 — Key one-shot effects on a real `LaunchedEffect` key.** Never `LaunchedEffect(true)`
or `LaunchedEffect(Unit)`.

## K. Runtime and feature docs (implements UZF-6, UZF-21, UZF-23)

**KT-28 — The UZF runtime stays portable.** `Feature`, `Outcome`, `Effect`
(`OfFlow`/`OfThunk`), `Sink` and the `FlowEffect`/`ThunkEffect`/`Dispatch` aliases live under
`{{UZF_RUNTIME_ROOT}}/uzf` and stay product-agnostic.

**KT-29 — Feature docs name no Compose/Kotlin framework identifier.** No `@HiltViewModel`,
`@Composable`, `StateFlow`, `Feature`, `Outcome`, `Producer`, `ThunkEffect`, … in a feature
doc; tests live under `{{TEST_TARGET}}`/`{{ANDROID_TEST_ROOT}}` and design tokens under
`{{THEME_ROOT}}`, not in docs.

## L. Anti-patterns (auto-reject)

`_state.value =` from a subclass · overriding/shadowing `onEvent`/`send` · side
effects in `reduce` · extra public mutating methods on a Feature ·
`Channel<UiEffect>` or `SharedFlow(replay>=1)` for one-shot effects · mixing
domain `Effect` with view `UiEffect` · hand-constructing `Outcome.*`/`Effect.*` ·
a Page calling `hiltViewModel()` or importing nav/hilt · `collectAsState()` ·
`LaunchedEffect(true)`/`LaunchedEffect(Unit)` for keyed work · hard-coded design
values · `Toast`/`Snackbar` from a Composable · `LiveData` in new code ·
`runBlocking`/`GlobalScope.launch` · field injection / service locator · empty
Repository · `Throwable` in State.

## Glossary (UZF → Jetpack Compose)

| UZF | Jetpack Compose |
| --- | --- |
| Interactor / store | `@HiltViewModel class …Feature : Feature<State,Event,UiEffect>()` |
| State | `data class …State` exposed as `StateFlow` |
| Event | `sealed interface …Event` |
| UiEffect | `sealed interface …UiEffect` on `MutableSharedFlow(replay=0, extraBufferCapacity≥1, onBufferOverflow=DROP_OLDEST)` |
| Reducer | `protected fun reduce(state, event): Outcome<…>` |
| Shifter | `fun State.with…(): State = copy(...)` |
| Selector | top-level `fun select…(state): X` |
| Producer | `@Inject class …Producer` → `FlowEffect`/`ThunkEffect` |
| Effect | suspend lambda run in `viewModelScope` |
| Wrapper / renderer | `…Screen` (stateful) / `…Page` (stateless) |
| Service | `interface …Service` + `Live…`/`Stubbed…`, Hilt-bound |
| Result / Exception | `kotlin.Result<T>` / `sealed class …Exception(message, recoverable)` |

## Appendix — capture reader

Informative; it adds no `KT-{n}` id. Its `KT-{n}` citations are this file's
[registry](#kt-n-rule-registry-canonical) above. How a capture reader turns this stack's files into the rows a
spec folder is written from: file suffix → the UZF concept it holds (this handbook's glossary and
[`rules/10-naming-and-layout.md`](rules/10-naming-and-layout.md)) → the row kind it emits (the
kinds are [`../../spec/authoring.md` → *Capture row kinds*](../../spec/authoring.md#capture-row-kinds)).
Enumeration starts from the Gradle source sets the app module builds, never a filename glob
(`SP-14`).

| File suffix | UZF concept | Row kind emitted |
| --- | --- | --- |
| `…Screen.kt` | Stateful wrapper (`KT-1`, `UZF-4`) | `screen` |
| `…Page.kt` | Stateless renderer (`KT-1`, `UZF-4`) | `screen` — joins its wrapper's row, never a second count |
| `…Fragment.kt` | Child composable bound to a Feature (`KT-1`) | none — joins the screen that hosts it |
| `…Feature.kt` | Interactor: `@HiltViewModel class …Feature` (`KT-3`, `UZF-1`) | none of its own — its `reduce` arms are the evidence on the `event` rows |
| `…State.kt` | State (`KT-4`, `UZF-8`) | `state` |
| `…Event.kt` | Event (`UZF-2`; dispatched through `KT-5`'s `onEvent`) | `event` (one per case) |
| `…UiEffect.kt` | One-shot UI effect (`KT-9`) | `navigation` (one per case the Screen routes) |
| `…Shifters.kt` | Shifter (`KT-6`, `UZF-10`) | `shifter` (one per `with…` / `as…` function) |
| `…Selectors.kt` | Selector (`KT-7`, `UZF-11`) | `selector` (one per `select…` function) |
| `…Producer.kt` | Producer → Effect (`KT-8`, `UZF-15`) | `producer` |
| `…Service.kt` (with `Live…` / `Stubbed…`), `…Repository.kt`, `…Provider.kt`, `…Api.kt`, `…Database.kt` | Service / Repository / Provider (`KT-10`–`KT-12`, `KT-19`, `UZF-16`) | `service` — the `Stubbed…` double joins its service's row |
| `…Mapper.kt`, `…Response.kt`, `…Entity.kt`, `…Endpoint.kt`, `…Exception.kt`, domain models | Mapper, wire and storage types, exception (`KT-19`, `KT-20`, `UZF-17`) | `model` |
| the `{{FLAG_ENUM}}` registry | Feature flag (`UZF-22`) | `flag` (one per flag) |
| `…FeatureTest.kt`, `…ShiftersTest.kt`, `…SelectorsTest.kt`, `…ProducerTest.kt`, `…MapperTest.kt` | Declared tests (`UZF-18`) | `test` (one per test case) |
| `…PageSnapshotTest.kt` and its `src/test/snapshots/images/` | Visual evidence (`KT-22`, `UZF-26`) | `snapshot` (one per recorded state) |
| `…Adapter.kt` | List-cell composable | none — joins the `screen` that renders it |
| `…Mocks.kt`, `…Module.kt` | Canned state, Hilt wiring (`KT-17`, `KT-18`) | none |

String tables (`res/values*/strings.xml`) and analytics call sites carry no feature suffix; a
reader emits `strings` and `analytics` rows from the resources and call sites it reads, and says
which files it read.
