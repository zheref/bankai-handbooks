<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 03 — State, Shifters, Selectors

## Repo-specific placeholders

- `{{APP_PACKAGE}}` — the app's base Kotlin package that roots the feature packages (bound per repo; e.g. the reverse-DNS `…feature/<name>/` tree). The only genuinely product-specific literal in this rule; everything else is universal Kotlin/Compose API or an illustrative feature/domain name.

Implements `UZF-8`/`UZF-9` (State), `UZF-10` (Shifters), `UZF-11` (Selectors);
tightened for the Compose/`StateFlow` reducer by `KT-4`, `KT-6`, `KT-7`.

## State (`KT-4` implements `UZF-8`, `UZF-9`)

- Always a **single immutable `data class <Name>State(...)` per feature**. Properties are `val`-only — never `var` (`KT-4`).
- Exposed as `StateFlow<<Name>State>` built from a `MutableStateFlow`. Read in Compose with `collectAsStateWithLifecycle()`, **never** plain `collectAsState()` (`KT-4`).
- Immutable, and never holds a `Throwable`, `Response<…>`, `Job`, or a mutable collection (`KT-4`).
- Holds **domain types only** — `Profile?`, `List<Suggestion>`, `<Name>Exception?`. No DTOs, no Retrofit/Ktor responses, no `SharedPreferences` strings — those are mapped to domain types at the Service boundary (`UZF-8`; the Mapper contract is `KT-20`).
- A lifecycle (idle / loading / loaded / failed) is modeled as **one sealed type**, never as parallel `isLoading: Boolean` + `exception: …Exception?` fields — those can represent invalid combinations (e.g. "loaded AND failed" at once), which `UZF-9` forbids. Give the State a single `val load: LoadState` field; the `Loaded` case carries the data and the `Failed` case carries the exception, so they can never coexist (`UZF-9`; see `KT-6`).
- Lives in `<Name>State.kt` alongside `sealed interface <Name>Event` and `sealed interface <Name>UiEffect`.

```kotlin
// {{APP_PACKAGE}}/feature/now/NowState.kt
sealed interface LoadState {
    data object Idle : LoadState
    data object Loading : LoadState
    data class Loaded(val suggestions: List<Suggestion>) : LoadState
    data class Failed(val exception: NowException) : LoadState
}

data class NowState(
    val load: LoadState = LoadState.Idle,
    val profile: Profile? = null,
)
```

- **State is never constructed inline in previews or tests.** Canned variants (`loadingState`, `loadedState`, `erroredState`, `partiallyLoadedState`) live in `<Name>Mocks.kt`; previews and tests consume those (`KT-18`, `KT-22`).

## Shifters (`KT-6` implements `UZF-10`)

- File: `<Name>Shifters.kt`.
- Each Shifter is a **top-level extension function** `fun <Name>State.with…(args): <Name>State` (`KT-6`).
- Body is exactly `copy(...)` plus **pure derivations** of fields from `args`. No I/O, no `Clock.now()`, no randomness, and no reads of clock / random / environment / services (`KT-6`, `UZF-10`).
- **One concern per Shifter.** "Entering load mode" is one concern and fits in one Shifter, even though it replaces the whole `load` field (e.g. `copy(load = LoadState.Loading)`).

```kotlin
// {{APP_PACKAGE}}/feature/now/NowShifters.kt
fun NowState.withLoading(): NowState =
    copy(load = LoadState.Loading)

fun NowState.withSuggestions(items: List<Suggestion>): NowState =
    copy(load = LoadState.Loaded(items))

fun NowState.withException(exception: NowException): NowState =
    copy(load = LoadState.Failed(exception))
```

- **Never inline a `copy(...)` block inside `reduce` (or `onEvent`).** If you find yourself writing `updateState { it.copy(foo = bar) }`, extract a Shifter (`KT-6`). This is stricter than the mutating-reducer stacks: on Compose the copy **always** goes through a named Shifter, never inline.
- If a Shifter genuinely needs the current time or identity, pass it in as an `args` value — the Shifter stays pure (`UZF-10`).
- Test every Shifter with ≥ 3 cases (typical, boundary, no-op) (`KT-22` implements `UZF-18`).

## Selectors (`KT-7` implements `UZF-11`)

- File: `<Name>Selectors.kt`.
- **Top-level pure functions** `fun select…(state: <Name>State): X` (`KT-7`).
- Composed safely from other Selectors; **never** from `Clock`, `Random`, services, or Composable scope (`UZF-11`). State is the only input.
- In Compose, read Selectors through `derivedStateOf` so recomposition is scoped:

  ```kotlin
  val fullName by remember(state) { derivedStateOf { selectFullName(state) } }
  ```

- A Selector that is O(1) field-access (e.g. `state.profile?.email`) does **not** need to be extracted — call it inline. Extract when the expression is non-trivial or used in more than one place.
- Use `derivedStateOf` for any Selector that does **more than O(1) work**, so recomputation is memoized to the state it actually reads (`KT-7`).
- Test every Selector with ≥ 3 cases (`KT-22` implements `UZF-18`).

## Forbidden

- Mutating state from within a Selector or Shifter.
- Reading external state (system clock, random, environment, services) from a Shifter or Selector. Pass the dependency in as an `args` value if absolutely needed (`UZF-10`, `UZF-11`).
- `var` properties on the State `data class` (`KT-4`).
- Storing a `Throwable`, `Response<…>`, `Job`, or a mutable collection in State — wrong layer; the Mapper should have produced a domain `<Name>Exception` or Model (`KT-4`, `KT-20`).
- Inline `copy(...)` blocks in the reducer — extract a Shifter (`KT-6`).
- Inline complex expressions in Compose that should be Selectors (`KT-7`).
