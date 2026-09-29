<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# UZF Architecture Overview — Jetpack Compose

**Applies to:** every Android + Jetpack Compose feature in {{PROJECT_NAME}}.

## Repo-specific placeholders

- `{{PROJECT_NAME}}` — the product these rules govern. Illustrative example: `Acme`.
- `{{UZF_RUNTIME_ROOT}}` — the shared module/package that holds the UZF base abstractions (the `Feature<State, Event, UiEffect>` base class, `Outcome`, `Sink`, `Effect` typealiases, `Environment`, dispatchers) plus cross-feature Hilt wiring. Illustrative example: `library` (base class under `library/uzf/`, cross-feature modules under `library/di/`).

---

UZF (Unidirectional Z Flow) is the application architecture for all upcoming and existing Jetpack Compose features in {{PROJECT_NAME}}. It is **not** TCA, **not** MVVM-without-rules, and **not** "MVI from a blog post." Its core rules are non-negotiable and are documented below, then refined across the sibling rule files. Hilt, Coroutines, `StateFlow`, Retrofit, and Room are the canonical stack primitives (Compose BOM 2025.01+, Kotlin 2.0+); they are part of the architecture, not per-product choices.

> **v2 corrections.** This canon incorporates findings from a real UZF-aligned Compose codebase. The two rules that most often bend in the wild are tightened here: **`UiEffect` travels on a `SharedFlow`, never a `Channel`** (KT-9), and **domain `Effect` and view-tier `UiEffect` are separate sealed types** (KT-9). A pragmatic base class (e.g. a shared `Feature<State, Event, UiEffect>`) is explicitly allowed as long as it preserves every rule below (KT-3).

## The flow (canonical)

```
User taps    ─▶ Page.onEvent(Event)             [or `store.send(Event)` from a Screen]
              ─▶ <Name>Feature.onEvent(Event)    [final on the base — `send` is an alias]
              ─▶ reduce(state, event): Outcome<State, Event, UiEffect>   [100 % pure]
                    │
                    ├─▶ UpdatedState / Both       → Shifter (State.with…())
                    │                                └─▶ new State ─▶ StateFlow ─▶ Page recomposes
                    │
                    └─▶ NewEffect / Both          → Effect<E, U>          (FlowEffect or ThunkEffect)
                            └─▶ viewModelScope.launch { effect.run(sink) }
                                    ├─▶ Service.operation() → Result<T>
                                    │       └─▶ sink.dispatch(OnXxxCompleted(result))
                                    │               └─▶ <Name>Feature.onEvent(...) → reduce(...) again
                                    │
                                    └─▶ sink.signal(UiEffect.NavigateToX) → SharedFlow → Screen routes
```

Everything funnels through the one `onEvent` entry point and back into it (UZF-7). **View-tier** side effects (navigate, show a snackbar/toast) travel on a **separate** `SharedFlow<…UiEffect>` — they never live in `State`, and the reducer never emits them. Emission happens inside a `ThunkEffect` body via the `Sink` (KT-9).

## The core rules every contributor must hold

1. **One `Feature` per screen** (UZF-7, KT-3). Named `<Name>Feature` (e.g. `SuggestionsFeature`), `@HiltViewModel`-annotated, obtained in Compose via `hiltViewModel()` — **never** `remember { … }`. It derives from the canonical, project-agnostic base class `Feature<State, Event, UiEffect>` (in the shared `{{UZF_RUNTIME_ROOT}}` module). A per-product base name is allowed only if it preserves every rule here and introduces no hidden state (no implicit `_state.value = …` shortcuts). The `Feature` suffix is required for new code; grandfathered `…ViewModel` classes must be renamed when materially edited.

2. **One canonical entry point: `onEvent(event)`** (KT-5). `final` on the base class. The base also exposes `fun send(event) = onEvent(event)` as a view-layer-friendly alias — pages/screens call `store.send(Event.UserDidTap…)`, where `store` is the subclass instance. Subclasses implement only `protected fun reduce(state, event): Outcome<State, Event, UiEffect>`. **No public mutator methods** — no `setX(...)`, `markY(...)`, `clearZ(...)`; every mutation is an `Event` case. Two `onEvent`-style entry points on one Feature is forbidden.

3. **State is a `data class`, exposed as `StateFlow`** (KT-4). Built from a `MutableStateFlow(initialState)`. Read from Compose with `collectAsStateWithLifecycle()` — **never** plain `collectAsState()`. Wire-format types (`…Response`, raw JSON) never enter `State`; map to a domain Model first (UZF-8).

4. **The reducer is 100 % pure** (KT-5, UZF-13). `reduce(state, event)` returns `Outcome<State, Event, UiEffect>`, which has exactly four cases:
   - `Idle` — nothing happens.
   - `UpdatedState(newState)` — state replaced; no effect.
   - `NewEffect(effect)` — effect launched; state unchanged.
   - `Both(newState, effect)` — state replaced **and** effect launched.

   Built via factory functions that read naturally:

   ```kotlin
   is OnAppeared              -> outcome(state.withLoading(), producer.loadSuggestions())
   is OnSuggestionsLoaded     -> updatedState(state.withSuggestions(event.items))
   is UserDidAcceptSuggestion -> newEffect(producer.markAccepted(event.id))
   is UserDidTapEdit          -> newEffect(producer.navigateToEdit(event.id))
   is UserDidTapDismiss       -> idle
   ```

   No `viewModelScope`, no `signal(...)`, no `tryEmit(...)`, no I/O, no `Throwable` thrown. The reducer **describes**; it does not **perform**. Reducers never throw — all failures surface as `Result<T>` from Services and are translated to a `…Exception` via a Mapper (UZF-14). Reducers may read a synchronous `…Provider`, but never call a `…Service` (KT-12).

5. **Shifters** live in `<Feature>Shifters.kt` (KT-6): `fun State.with…(): State = copy(...)`, one concern per Shifter. Reducers call Shifters instead of writing inline `copy(...)` / `updateState { it.copy(...) }`.

6. **Selectors** live in `<Feature>Selectors.kt` (KT-7): top-level `fun select…(state): X`, consumed in Compose via `remember(state) { derivedStateOf { select…(state) } }` to scope recomposition.

7. **Producers** live in `<Feature>Producer.kt` (KT-8, UZF-12): `@Inject`-constructed classes whose public methods return an **effect factory** — either:
   - `FlowEffect<Event>` (`typealias FlowEffect<E> = Flow<E>`) — preferred; stream-style, composes with cancellation; **cannot signal `UiEffect`s**.
   - `ThunkEffect<Event, UiEffect>` (`typealias ThunkEffect<E, U> = suspend (Sink<E, U>) -> Unit`) — preferred when the body branches imperatively and/or must signal a `UiEffect`. The `Sink` exposes `dispatch(event)` and `signal(uiEffect)`.

   Method names are **plain verbs** — no `produce…` prefix (the class suffix already means "effect factory"): `producer.loadSuggestions()`, `producer.navigateToEdit(id)`, `producer.markAccepted(id)`. **No I/O lives outside a Producer**, and reducers never build effects inline — they call `producer.x(...)` and wrap the result via the overloaded `newEffect(...)` / `outcome(state, ...)` factories. Effects run in `viewModelScope` and dispatch result events back into the same `onEvent` — they never set state directly.

8. **`UiEffect` is a separate `sealed interface`** (KT-9), distinct from the domain `Effect`, exposed as a `SharedFlow<…UiEffect>` with `replay = 0`, `extraBufferCapacity ≥ 1`, `onBufferOverflow = DROP_OLDEST`. It is **only** for one-shot view-tier signals (navigation, snackbars, toasts). **Never a `Channel`** — Channels are cold and drop emissions while no collector is attached, the classic "ghost navigation after process death." **Emitted only via `sink.signal(uiEffect)` inside a `ThunkEffect` body** — navigation is a one-line Producer thunk: `fun navigateToEdit(id): ThunkEffect<Event, UiEffect> = { sink -> sink.signal(NavigateToEdit(id)) }`. Domain `Effect` (produces Events, stays in the system) and view `UiEffect` (exits the system) must never share a sealed type.

## Supporting rules folded in from the v2 canon

- **Pages are stateless; Screens are stateful** (KT-1). `@Composable fun …Page(state, onEvent, modifier)` renders and is snapshot-/preview-testable. `@Composable fun …Screen(...)` is the stateful wrapper that hoists the Feature (`hiltViewModel()`), collects `State` and the `UiEffect` `SharedFlow`, and routes effects.
- **Pages are navigation-free and DI-free** (KT-2). A Page never imports `androidx.navigation` and never calls `hiltViewModel()`; a `@Composable` that does either is a Screen, not a Page. Pages take nothing beyond `(state, onEvent, modifier)`.
- **≥ 3 `@Preview` per Page + Paparazzi snapshots** (KT-13). Cover idle / loading / loaded / errored; Paparazzi tests run hermetically on the JVM (no emulator) and mirror the previews.
- **Services are interfaces with real impls** (KT-10). `interface …Service` + `Live…Service` (Hilt-bound via `@Binds`) + a `Stubbed…Service` for tests. Network wraps a Retrofit `Api`; storage wraps a Room `Dao`; system access wraps `Context`-bound APIs. `…Store` / `…Resolver` / `…Holder` helpers that suspend or hit I/O must be promoted to `…Service` interfaces.
- **Repositories coordinate ≥ 2 Services** (KT-11). A Repository is the only service-tier type allowed to hold state, and only when strictly required (caches, in-flight token dedupe). Empty/placeholder Repositories are forbidden — delete them.
- **Providers are sync-only** (KT-12). A `…Provider` returns values synchronously (`fun current(): Value`). Anything that can suspend or block is a `…Service`. Reducers may call Providers; reducers may not call Services.
- **Theme is configured once at app root** (KT-14). `MaterialTheme` is set up once; an app `object AppTheme { … }` vends design tokens. Components read tokens through the theme — never hard-coded colors, sizes, or typography.
- **Navigation is routed, never called from logic** (KT-15). Navigation goes through a `NavigationService` interface or callbacks passed into `…Screen(onNavigateTo… = …)`. The Feature emits a `UiEffect`; the Screen maps it to a `NavController` call. Reducers never touch `NavController`.
- **No global event buses for feature concerns** (KT-16). A global `Toast`/`Snackbar` `SharedFlow` is allowed **only** for orphan app-wide singletons with no UI parent (e.g. an auth-refresh worker) or telemetry hooks. Anything raised inside a Feature or Producer travels on that feature's `UiEffect`.
- **One Hilt module per feature** (KT-17). `<Feature>Module.kt`, `@Module @InstallIn(SingletonComponent::class)`. Cross-feature wiring (Retrofit, OkHttp, Room DB instances) lives under `{{UZF_RUNTIME_ROOT}}/di`.
- **A `Mocks.kt` per feature** (KT-18). `<Feature>Mocks.kt` produces canned `State` variants (`loadingState`, `loadedState`, `erroredState`, `partiallyLoadedState`) consumed by previews and tests — never construct `State` inline in a preview. Domain models additionally ship `mock*` fixtures (≥ 7 variants: happy, empty, long, non-ASCII, missing-optional, stale-timestamp, just-updated) (UZF-18).

## Folder layout per feature

Every artifact for a feature is **co-located** in one folder (UZF-6) — cognitive locality beats layering purity, even though each file is formally a different layer.

```
<module-root>/features/<feature>/
    <Feature>Page.kt           # stateless @Composable (state, onEvent, modifier)   (KT-1, KT-2)
    <Feature>Screen.kt         # stateful wrapper: hoists the Feature, collects UiEffect   (KT-1)
    <Feature>Feature.kt        # @HiltViewModel class extending Feature<State,Event,UiEffect>   (KT-3)
    <Feature>State.kt          # data class State + sealed Event + sealed UiEffect   (KT-4, KT-9)
    <Feature>Shifters.kt       # fun State.with…() = copy(...)                        (KT-6)
    <Feature>Selectors.kt      # top-level fun select…(state)                          (KT-7)
    <Feature>Producer.kt       # @Inject class, plain-verb effect-factory methods      (KT-8)
    <Feature>Mocks.kt          # canned State variants for previews & tests            (KT-18)
    <Feature>Module.kt         # Hilt @Module @InstallIn(SingletonComponent::class)    (KT-17)
```

The canonical UZF base (`Feature<…>`, `Outcome`, `Sink`, `Effect`) and cross-feature Hilt wiring live in the shared `{{UZF_RUNTIME_ROOT}}` module, not in any feature folder.

## Hard "never"s — memorize these

1. **Never** set `_state.value` from inside `reduce(...)`, or run `viewModelScope.launch { _state.value = … }` outside an Effect. State changes happen only at the `onEvent` integration point. (KT-4, KT-5.)
2. **Never** add a public mutator method (`setX`, `markY`, `clearZ`) or a second `onEvent`-style entry to a Feature. Model it as an `Event` case. (KT-5.)
3. **Never** instantiate a Feature in a Composable (`remember { MyFeature() }`). Features are always `hiltViewModel()`-injected. (KT-3.)
4. **Never** put a service call, `Retrofit`/`Room` I/O, or a `Throwable` throw inside a reducer. Producers do I/O; failures come back as `Result<T>` → `…Exception`. (KT-8, UZF-13, UZF-14.)
5. **Never** put a wire-format type (`…Response`, raw JSON) or a `Throwable` into `State`. Map first. (UZF-8, KT-4.)
6. **Never** expose `UiEffect` on a `Channel`/`receiveAsFlow()`, or with `replay = 1`. Use `SharedFlow(replay = 0, DROP_OLDEST)`. (KT-9.)
7. **Never** mix domain `Effect` and view-tier `UiEffect` in the same sealed type. (KT-9.)
8. **Never** emit a `UiEffect` from a reducer. Emit only via `sink.signal(...)` inside a `ThunkEffect`. (KT-9.)
9. **Never** call `Toast.makeText(...)` from a `@Composable`, or touch `NavController` from a reducer. Emit a `UiEffect` and let the Screen route it. (KT-15, KT-16.)
10. **Never** let a Page take more than `(state, onEvent, modifier)` or import `androidx.navigation`; never call `hiltViewModel()` in something called a "Page." (KT-1, KT-2.)
11. **Never** ship a `@Composable` Page with fewer than 3 `@Preview`s, or hard-code colors/sizes/typography in a Page. (KT-13, KT-14.)
12. **Never** inject a `…Store` / `…Resolver` / `…Holder` into a Feature without an `interface …Service` or `interface …Provider`; never leave an empty `…Repository`. (KT-10, KT-11.)
13. **Never** use `LiveData`, `runBlocking` (outside tests), or `GlobalScope.launch` in new code. (KT-4.)
14. **Never** change architecture rules (suffixes, layering, artifact responsibilities) locally, and **never hand-edit the generated `.claude/rules/` mirror.** This handbook in `bankai-handbooks` is the canonical source (CON-13); propose changes as a PR there (G4 — the human merges) and let the mirror generator regenerate every surface's mirror.

## Glossary at a glance (UZF ↔ Jetpack Compose)

| UZF | Jetpack Compose |
| --- | --- |
| Feature | `@HiltViewModel class …Feature : ViewModel()` (or a thin subclass of the shared `Feature<…>` base) |
| State | `data class …State(...)` exposed as `StateFlow` |
| Event | `sealed interface …Event` |
| **UiEffect** | **`sealed interface …UiEffect` exposed as `SharedFlow(replay = 0, DROP_OLDEST)`** — distinct from domain Effect |
| Reducer | `protected fun reduce(state, event): Outcome<…>` on the Feature; `onEvent` is `final` on the base; 100 % pure |
| Outcome | `sealed interface Outcome<S, E, U>` with `Idle`, `UpdatedState(s)`, `NewEffect(e)`, `Both(s, e)`; built via `idle`, `updatedState(s)`, `newEffect(...)`, `outcome(s, ...)` |
| Sink | `interface Sink<E, U> { dispatch(E); signal(U) }` — handed to every ThunkEffect by the base |
| FlowEffect | `typealias FlowEffect<E> = Flow<E>` — stream-style return; cannot signal UiEffects |
| ThunkEffect | `typealias ThunkEffect<E, U> = suspend (Sink<E, U>) -> Unit` — imperative return; can dispatch events and signal UiEffects |
| Effect (wrapper) | `sealed interface Effect<E, U>` with `OfFlow` / `OfThunk`; reducers never construct directly — use `newEffect(...)` overloads |
| Shifter | `fun State.with…(): State = copy(...)` |
| Selector | top-level `fun select…(state): X` |
| Producer | `@Inject` class whose methods return `FlowEffect` / `ThunkEffect` |
| Service | `interface …Service` + `Live…` + `Stubbed…` impls, Hilt-bound |
| Operation | `suspend fun …()` on a Service/Dao |
| Api | Retrofit `interface …Api` |
| Database | Room `@Database class …Database` |
| Query / Mutation | `@Query` read / `@Upsert` `@Insert` `@Delete` write on a `@Dao` |
| Repository | coordinates ≥ 2 Services; the only service-tier type allowed state |
| Provider | `@Inject` class with **synchronous** reads only (`fun current(): Value`) |
| Mapper | class with `toDomain`, `fromDomain`, `toException` |
| Model / Response | domain `data class` / `@Serializable data class …Response` |
| Exception | `sealed class …Exception(message, recoverable)` |
| Theme | `object AppTheme { … }` over a `MaterialTheme` wrapper |
| Environment | `enum class Environment { DEBUG, TEST, LIVE, PRODUCTION }` |
| Result | `kotlin.Result<T>` |
| Task | `Job` from `kotlinx.coroutines`, optionally wrapped |

When in doubt, re-read this file. Every other rule file in this handbook is a refinement of the rules above.
