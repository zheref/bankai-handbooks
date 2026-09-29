<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 04 — Producers, Effects & UiEffects

## Repo-specific placeholders

- `{{APP_SOURCE_ROOT}}` — app source root that holds the feature packages (`…Screen`/`…Page`/`…Feature`/`…Producer`). The feature sample names below (`Suggestions…`, `SuggestionService`, `SuggestionId`) are illustrative, not product literals.

Implements `UZF-12` (reducers pure, no inline effects), `UZF-13` (no
service/persistence/clock calls from a reducer), `UZF-14` (effects resolve a
`Result`, never throw), `UZF-15` (Producers are state-free factories), `UZF-3`
(one completion event carries a `Result`), and `UZF-16` (external systems sit
behind DI'd Services); bound to Compose by `KT-8` (Producers, and effects
running in `viewModelScope` and dispatching back through `onEvent`), and `KT-9`
(`UiEffect` is a separate `SharedFlow` type).

## What a Producer is (`KT-8`, `UZF-15`)

A Producer is an `@Inject`-constructed class that lives in `<Feature>Producer.kt`.
It holds **zero mutable state** and depends only on Services, Repositories,
Providers, and Mappers. It performs **no I/O at construction time** — every public
method is a **factory** that returns an effect the reducer will later run
(`UZF-15`). Reducers never build effects inline; they always call a Producer
method (`KT-8`, `UZF-12`).

Each public method returns one of two effect forms:

- **`FlowEffect<<Feature>Event>`** (alias for `Flow<Event>`) — a cold flow that
  dispatches one or more Events back into the loop. Stream-style, composes with
  cancellation. **Cannot signal UiEffects** (its `U = Nothing`).
- **`ThunkEffect<<Feature>Event, <Feature>UiEffect>`** (alias for
  `suspend (Sink<Event, UiEffect>) -> Unit`) — an imperative suspend lambda handed
  a `Sink<Event, UiEffect>` that can `dispatch(event)` **and/or** `signal(uiEffect)`.

**Method names are plain verbs.** No `produce…` prefix — the class suffix already
conveys "effect factory." Write `producer.loadSuggestions()`, never
`producer.produceLoadSuggestions()`.

```kotlin
// {{APP_SOURCE_ROOT}}/suggestions/SuggestionsProducer.kt
class SuggestionsProducer @Inject constructor(
    private val service:    SuggestionService,
    private val acceptance: SuggestionAcceptanceService,
) {
    // FlowEffect — "fetch then dispatch one event"
    fun loadSuggestions(): FlowEffect<SuggestionsEvent> = flow {
        emit(SuggestionsEvent.OnSuggestionsLoaded(service.load()))
    }

    // FlowEffect — stream from an observable source
    fun streamSuggestions(): FlowEffect<SuggestionsEvent> = service.observe()
        .map { SuggestionsEvent.OnSuggestionsLoaded(Result.success(it)) }

    // ThunkEffect — imperative, with both Event dispatch and UiEffect signaling
    fun navigateToEdit(id: SuggestionId): ThunkEffect<SuggestionsEvent, SuggestionsUiEffect> = { sink ->
        sink.signal(SuggestionsUiEffect.NavigateToEdit(id))
    }

    // ThunkEffect — imperative, dispatch-only (still takes a Sink; just doesn't signal)
    fun markAccepted(id: SuggestionId): ThunkEffect<SuggestionsEvent, SuggestionsUiEffect> = { sink ->
        acceptance.mark(id).onFailure { sink.dispatch(SuggestionsEvent.OnAcceptFailed(it)) }
    }
}
```

Reducers call Producer methods directly and pass the result to `newEffect(...)` or
`outcome(state, ...)` — overload resolution picks the right wrapper for Flow vs
Thunk (`KT-8`):

```kotlin
is OnAppeared              -> outcome(state.withLoading(), producer.loadSuggestions())
is UserDidAcceptSuggestion -> newEffect(producer.markAccepted(event.id))
is UserDidTapEdit          -> newEffect(producer.navigateToEdit(event.id))
```

### Producer rules

1. **`@Inject`-constructed, state-free.** Dependencies are Services, Repositories,
   Providers, and Mappers only — never the whole `State` (`UZF-15`). A Producer
   holds no mutable field.
2. **Every method is a factory** returning `FlowEffect<E>` or
   `ThunkEffect<E, U>` — never a bare `suspend fun`, a `Job`, or a `Deferred`, and
   never work that runs at construction time.
3. **Failures are dispatched, never thrown.** A failing operation surfaces as a
   completion Event carrying `Result.failure(...)` — success and failure unify into
   a single `On…Completed(Result<Success, …Exception>)` event (`UZF-3`, `UZF-14`).
   **Producers never throw out of the lambda / flow.** The raw `Throwable` is
   translated to a typed `<Feature>Exception` via a Mapper inside `reduce`, not in
   the Producer.
4. **Cancellation is the only silent exit** (`UZF-14`). The Producer relies on
   `viewModelScope` cancelling the collector (for a `FlowEffect`) or the suspending
   body (for a `ThunkEffect`). Producers do **not** expose their own `Job` handles.
5. **No boundary access inside a Producer.** A Producer never touches
   `SharedPreferences`, Retrofit, Room, or `Context` directly — those go through a
   `…Service` / `…Provider` interface (`UZF-13`, `UZF-16`).
6. **Test the Producer method directly** with stubbed Services — its Flow/Thunk
   output is asserted via Turbine on the dispatched Events (and, for a Thunk, its
   `Sink` signals) (`UZF-18`).

### When to use FlowEffect vs ThunkEffect

| Situation | Form |
| --- | --- |
| Single I/O call → single event | `FlowEffect` via `flow { emit(...) }` |
| Stream / observable source (Room `Flow`, a realtime remote listener) | `FlowEffect` returning the source's `Flow` mapped to events |
| Multiple sequential I/O steps with branching | `ThunkEffect` (imperative is clearer than nested flow operators) |
| Need to signal a UiEffect (navigate, snackbar) | **`ThunkEffect`** — only thunks can call `sink.signal(...)` |
| Side-effect-only (write then no event) | `ThunkEffect` with an empty dispatch path |
| Conditional dispatches (dispatch *if* X) | `ThunkEffect` (early returns read better than `filter { … }` on a Flow) |

If in doubt, default to `FlowEffect`. Switch to `ThunkEffect` when you need
imperative branching, UiEffect signaling, or both.

## Effect — the internal wrapper (`KT-8`)

- `Effect<E, U>` is the internal **sealed** wrapper holding either a
  `FlowEffect<E>` (`Effect.OfFlow`, with `U = Nothing`) or a
  `ThunkEffect<E, U>` (`Effect.OfThunk`).
- Reducers **never** construct `Effect.OfFlow` / `Effect.OfThunk` directly — the
  `newEffect(...)` / `outcome(...)` factory overloads do it. Hand-constructing an
  `Effect.*` in a reducer is forbidden.
- The `Feature` base class's runtime knows how to execute either form. Both run
  inside `viewModelScope`, and both dispatch result Events back into the same
  `onEvent` entry point — an effect never sets `_state.value` directly (`KT-8`).

## UiEffect (`KT-9`)

- File: `<Feature>State.kt` (alongside `State` and `Event`).
- Type: `sealed interface <Feature>UiEffect` with cases like `NavigateToX(...)`,
  `ShowSnackbar(String)`. It is **only** for navigation, snackbars, toasts, and
  other one-shot view-tier signals.
- Exposed by the `Feature` base class as `uiEffects: SharedFlow<UiEffect>`, backed
  by a `MutableSharedFlow(replay = 0, extraBufferCapacity ≥ 1,
  onBufferOverflow = BufferOverflow.DROP_OLDEST)`. A small positive buffer (e.g. 8)
  is fine; the invariant is `replay = 0`.
  - **Do not use a `Channel`** for UiEffect. Channels are cold and miss emissions
    while no collector is attached — a frequent source of "ghost" navigations after
    process death. `SharedFlow` with `DROP_OLDEST` is the safe default.
  - **`replay >= 1` is forbidden** — it replays the most recent effect on every
    screen re-entry (a duplicate navigation / snackbar).
- **Emitted only from inside a `ThunkEffect` body via `sink.signal(uiEffect)`.**
  The reducer never emits UiEffects directly — it *requests* one by returning a
  Thunk that does. `sink.signal(...)` outside a thunk body is forbidden.
- Domain-level `Effect` (the `FlowEffect` / `ThunkEffect` a Producer returns) and
  view-tier `UiEffect` are different concepts: domain Effects produce Events;
  UiEffects exit the system. They must never share a sealed type (`KT-9`).

Consumed in the Screen — the stateful wrapper routes each `UiEffect` to a
callback; the reducer never calls a `NavController` and a Composable never calls
`Toast.makeText(...)` (`KT-9`, rule below):

```kotlin
LaunchedEffect(store) {
    store.uiEffects.collect { effect ->
        when (effect) {
            is SuggestionsUiEffect.NavigateToEdit -> onNavigateToEdit(effect.id)
            is SuggestionsUiEffect.ShowSnackbar   -> onShowSnackbar(effect.message)
        }
    }
}
```

Navigation is a Screen-level concern routed through an injected `NavigationService`
interface or, with Compose Navigation, callbacks passed into the Screen
(`…Screen(onNavigateToEdit = …)`). The Feature emits a `UiEffect`; the Screen maps
it to the callback / `NavController` call. Reducers never call `NavController`
directly.

### Modeling pure navigation as a Producer method

The cleanest pattern for "user tap → navigation" is a Producer method that returns
a one-line thunk:

```kotlin
fun navigateToEdit(id: SuggestionId): ThunkEffect<SuggestionsEvent, SuggestionsUiEffect> = { sink ->
    sink.signal(SuggestionsUiEffect.NavigateToEdit(id))
}
```

The reducer side stays a single line:
`is UserDidTapEdit -> newEffect(producer.navigateToEdit(event.id))`. This keeps
**all side effects (including view-tier signals) behind the Producer boundary**,
which is exactly what UZF wants (`UZF-12`, `UZF-15`).

## Forbidden

- Producer methods named `produce…`. Drop the prefix; use plain verbs.
- Producer methods that return anything other than `FlowEffect<E>` or
  `ThunkEffect<E, U>`. No bare `suspend fun`, no `Job`, no `Deferred` (`KT-8`).
- Producers eagerly running I/O at construction time. Always return a factory
  (`UZF-15`).
- Producers that throw instead of dispatching a failure event (`UZF-14`).
- Producers that touch `SharedPreferences`, Retrofit, Room, or `Context`
  directly. They go through `…Service` / `…Provider` interfaces (`UZF-13`,
  `UZF-16`).
- Emitting a UiEffect from a `FlowEffect` — it can't (`Effect.OfFlow` has
  `U = Nothing`). Use a Thunk.
- Calling `sink.signal(...)` from outside a thunk body.
- Mixing domain `Effect` and view `UiEffect` in the same sealed type (`KT-9`).
- `Channel<UiEffect>` for view effects (must be `SharedFlow`, per the ghost-nav
  rationale above).
- `replay >= 1` on the UiEffect `SharedFlow`.
- Constructing `Effect.OfFlow(...)` / `Effect.OfThunk(...)` by hand in reducers
  (use `newEffect(...)` / `outcome(...)`).
- Routing a feature's view-tier signal through a **global** toast/snackbar
  `SharedFlow` bus. Anything raised from inside a Feature or a Producer travels
  through that feature's own `UiEffect`; a global bus is acceptable **only** for
  errors raised by app-wide singletons with no UI parent (e.g. an auth-refresh
  worker) or telemetry hooks.
- Calling `Toast.makeText(...)` from a `@Composable`. Emit a
  `UiEffect.ShowSnackbar(...)` and let the Screen show it via a `SnackbarHost`.
