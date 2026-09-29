<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 07 — Models, Mocks & Mappers

## Repo-specific placeholders

- `{{APP_SOURCE_ROOT}}` — module source root that holds the feature packages plus the shared `models/` and `services/` packages (the app's main source dir).

Example domain types (`Profile`, `Suggestion`, `NowState`, …) and the feature name `Now` used below are **illustrative, not repo config** — nothing here is product-specific.

Implements `UZF-8` (State and domain Models hold domain types only) and `UZF-17` (wire / persistence types cross the boundary through a Mapper); tightened for Jetpack Compose + Hilt by `KT-18`–`KT-21`.

## Model (`KT-21` implements `UZF-8`)

- Domain types only: `data class <Name>(...)` (or a `@freezed`-style value type if the project standardizes on one).
- **No framework annotations** from Retrofit, Room, `kotlinx.serialization`, or Hilt. Those belong on the `Response`, `Entity`, or DI types — never on the domain Model (`UZF-8`).
- One model per file. The file name matches the class name.

```kotlin
// {{APP_SOURCE_ROOT}}/models/Profile.kt
data class Profile(
    val id: String,
    val firstName: String,
    val email: String,
    val avatarUrl: String?,
    val updatedAt: Long,
)
```

## Response (`KT-19` implements `UZF-17`)

- `@Serializable data class <Name>Response(...)` lives under `{{APP_SOURCE_ROOT}}/models/network/` (or a service package `{{APP_SOURCE_ROOT}}/services/<x>/`).
- Field names **mirror the wire format**; never rename them in the type — use `@SerialName(...)` to bridge a wire name to an idiomatic Kotlin property.
- Serialization uses `kotlinx.serialization`; the Retrofit boundary is wired with the `kotlinx-serialization-converter`.
- The Service maps `Response → Model` via the Mapper. **Features never see Responses.**

## Entity (`KT-19` implements `UZF-17`)

- `@Entity` Room types live next to their DAO under `{{APP_SOURCE_ROOT}}/services/storage/`.
- Same boundary rule: **features never see Entities.** The DAO returns Entities; the Service maps `Entity → Model`.

## Mapper (`KT-20` implements `UZF-17`)

- `class <Name>Mapper @Inject constructor() { … }` — Hilt-injected, never constructed inline — exposing three functions: `toDomain`, `fromDomain`, `toException`.
- All three are **pure**. `toException` may pattern-match on `IOException`, `HttpException`, and the domain `…Error` hierarchy to produce the recovery-oriented domain `…Exception`.

```kotlin
class ProfileMapper @Inject constructor() {
    fun toDomain(response: ProfileResponse): Profile = /* pure */
    fun fromDomain(model: Profile): ProfileResponse = /* pure */
    fun toException(throwable: Throwable): ProfileException = when (throwable) {
        is IOException   -> ProfileException.Network()
        is HttpException -> /* branch on code → Unauthorized / NotFound / Unknown */
        else             -> ProfileException.Unknown()
    }
}
```

## Error vs. Exception (`KT-20` implements `UZF-8`)

Two distinct sealed hierarchies bracket the failure path:

- **`sealed class <Feature>Error : Throwable()`** — the raw, *thrown* side. Lower layers surface failures through `Result<T>` returned by Services (reducers never throw).
- **`sealed class <Feature>Exception(val message: String, val recoverable: Boolean)`** — the domain-facing side that `State` holds. Cases mirror UX recovery paths: `Network`, `Unauthorized`, `NotFound`, `Unknown`.

The translation `Throwable` / `<Feature>Error → <Feature>Exception` happens in **`Mapper.toException`**, called inside the reducer at the boundary. `State` never holds a `Throwable` or a `Response<…>` — the Mapper must already have produced a domain `Exception` or a domain `Model` (`UZF-8`).

`<Feature>Exception` lives in the same file as the Model or in `<Feature>Exception.kt`.

## Mock fixtures — ≥ 7 per Model (`KT-18`)

Every domain Model exposes a `companion object` with **at least seven `mock*` variants**. The fixtures live in the same file as the model, banded with a `// region Mocks` marker so a Detekt rule can strip them from production builds if desired.

```kotlin
data class Profile(/* … */) {
    companion object {
        // region Mocks
        val mockHappy:       Profile = Profile(/* … */)
        val mockNoAvatar:    Profile = Profile(/* … */, avatarUrl = null)
        val mockLongName:    Profile = Profile(/* … */, firstName = "a".repeat(40))
        val mockNonAscii:    Profile = Profile(/* … */, firstName = "Émilie")
        val mockOld:         Profile = Profile(/* … */, updatedAt = 1_000_000L)
        val mockEmptyEmail:  Profile = Profile(/* … */, email = "")
        val mockJustUpdated: Profile = Profile(/* … */, updatedAt = System.currentTimeMillis())
        // endregion
    }
}
```

Variants must cover: **happy / empty / long / non-ASCII / missing-optional / stale-timestamp / just-updated.**

## State mocks (`KT-18`)

Per feature, a `<Feature>Mocks.kt` file produces the canned `State` variants:

```kotlin
object NowMocks {
    val idleState            = NowState()
    val loadingState         = NowState(load = LoadState.Loading)
    val loadedState          = NowState(load = LoadState.Loaded(listOf(Suggestion.mockHappy, Suggestion.mockLongName)))
    val erroredState         = NowState(load = LoadState.Failed(NowException.Network()))
    val partiallyLoadedState = NowState(load = LoadState.Loaded(listOf(Suggestion.mockHappy)))
}
```

`@Preview`s and Paparazzi snapshot tests consume `NowMocks`, and the domain `mock*` fixtures feed unit tests (`UZF-18`). **Do not construct `State` inline in previews or tests.**

## Forbidden

- Models with **fewer than 7** `mock*` fixtures.
- Mocks scattered across test files instead of a model's `companion object`.
- A feature constructing `State` **inline** in a preview or test instead of via `<Feature>Mocks`.
- A `Throwable` (or `<Feature>Error`) stored inside `<Feature>State`. Always translate to `<Feature>Exception` at the boundary via `Mapper.toException`.
- A `data class <Feature>State` containing a `Throwable` or a Retrofit `Response<…>` — wrong layer; the Mapper should have produced an `Exception` or a domain `Model`.
- Domain Models tagged with `@Serializable`, `@Entity`, or `@SerialName` — those annotations go on the `Response` / `Entity` types, never on the domain Model.
