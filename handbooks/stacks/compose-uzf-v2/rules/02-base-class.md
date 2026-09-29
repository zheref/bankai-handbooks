<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 02 — Base Class (`Feature`) + `Outcome` + `Effect` + `Sink`

Every project on this stack provides **one** shared, **project-agnostic** base class plus a
small algebraic-types module under `library/uzf/`. Every per-screen subclass inherits that base
class; every reducer returns the same `Outcome` shape. **The reducer is 100 % pure** — it has no
escape hatches (`KT-3`, `KT-5`, `KT-5`; implements `UZF-1`, `UZF-2`, `UZF-12`).

> The base class is called `Feature` (no product prefix). The concrete view-model class per
> screen is `<Name>Feature` (e.g. `HomeFeature`, `SettingsFeature`) and is obtained in Composables
> via `hiltViewModel()` — never `remember { <Name>Feature() }` (`KT-3`). From the view layer the
> convention is to hoist the subclass as `store` and call `store.send(Event.UserDidTap…)`; `send`
> is a one-line alias for `onEvent` exposed by the base class for ergonomic reasons (`KT-5`).

## Repo-specific placeholders

- `{{APP_PACKAGE}}` — the app's root Kotlin package; the `library/uzf/` runtime lives at
  `{{APP_PACKAGE}}.library.uzf` (illustrative: the app module's base package).
- `{{PROJECT_NAME}}` — product name, used only to illustrate the *forbidden* product-namespaced
  prefix that must never appear under `library/uzf/`.

---

## 1. The whole module at a glance

The runtime is portable: everything here compiles on a fresh Android Studio project with no
product code. It lives in one package.

```
library/uzf/
    Aliases.kt              # type aliases (FlowEffect, ThunkEffect, Dispatch, ...)
    Sink.kt                 # Sink<E, U> interface
    Effect.kt               # sealed Effect<E, U> wrapper
    Outcome.kt              # sealed Outcome<S, E, U> + factory functions
    Feature.kt              # the base class
```

---

## 2. Type aliases (`library/uzf/Aliases.kt`)

```kotlin
package {{APP_PACKAGE}}.library.uzf

import kotlinx.coroutines.flow.Flow

/** Function the runtime gives an effect to dispatch result events back into the loop. */
typealias Dispatch<E> = (E) -> Unit

/** Cold stream of events emitted by an effect. Producers return this for stream-style flows. */
typealias EventStream<E> = Flow<E>

/**
 * Producer-returned cold flow. Can only dispatch Events (no UiEffect signaling).
 * Use this when the effect is "fetch then emit one (or more) events."
 */
typealias FlowEffect<E> = Flow<E>

/**
 * Producer-returned imperative thunk. Receives a [Sink] so the body may dispatch Events
 * AND/OR signal UiEffects. Use this for branching imperative logic and for nav/snackbar.
 */
typealias ThunkEffect<E, U> = suspend (Sink<E, U>) -> Unit
```

The two producer return types (`FlowEffect` and `ThunkEffect`) are the only shapes a Producer may
return (`KT-8`; implements `UZF-13`).

---

## 3. `Sink<E, U>` — the runtime interface handed to thunks

```kotlin
package {{APP_PACKAGE}}.library.uzf

/**
 * Two-channel sink a thunk uses to talk back to the runtime:
 *   - [dispatch] feeds an Event back into the reducer loop.
 *   - [signal]   emits a one-shot UiEffect to the SharedFlow the View observes.
 *
 * Thunks that don't need UiEffect emission still take a Sink — they just never call `signal`.
 * The type system enforces correctness: if a Producer types its method
 * `ThunkEffect<MyEvent, Nothing>`, the Sink it receives is `Sink<MyEvent, Nothing>`,
 * and `signal(Nothing)` is uncallable because `Nothing` has no values.
 */
interface Sink<in E : Any, in U : Any> {
    fun dispatch(event: E)
    fun signal(uiEffect: U)
}
```

`dispatch` is the *only* way an effect feeds results back into the loop — it routes through
`onEvent`, never `_state.value` (`KT-8`; implements `UZF-14`). `signal` is the *only* way a
`UiEffect` leaves the system, and it is reachable exclusively from inside a `ThunkEffect`
(`KT-9`; implements `UZF-15`).

---

## 4. `Effect<E, U>` — the unified wrapper

```kotlin
package {{APP_PACKAGE}}.library.uzf

sealed interface Effect<out E : Any, out U : Any> {
    /** A FlowEffect cannot emit UiEffects — its U slot is Nothing. */
    data class OfFlow<E : Any>(val flow: FlowEffect<E>) : Effect<E, Nothing>

    /** A ThunkEffect can emit both Events and UiEffects via its Sink. */
    data class OfThunk<E : Any, U : Any>(val thunk: ThunkEffect<E, U>) : Effect<E, U>
}
```

Reducers never construct `Effect.OfFlow` / `Effect.OfThunk` directly — they use the overloaded
`newEffect(...)` / `outcome(...)` factories below (`KT-5`).

---

## 5. `Outcome<S, E, U>` — what every reducer returns

```kotlin
package {{APP_PACKAGE}}.library.uzf

sealed interface Outcome<out S : Any, out E : Any, out U : Any> {
    /** Nothing happens — state unchanged, no effect launched. */
    data object Idle : Outcome<Nothing, Nothing, Nothing>

    /** Replace the state. No effect launched. */
    data class UpdatedState<S : Any>(val state: S) : Outcome<S, Nothing, Nothing>

    /** Launch an effect. State unchanged. */
    data class NewEffect<E : Any, U : Any>(val effect: Effect<E, U>) : Outcome<Nothing, E, U>

    /** Replace the state AND launch an effect. */
    data class Both<S : Any, E : Any, U : Any>(
        val state: S,
        val effect: Effect<E, U>,
    ) : Outcome<S, E, U>
}

// ── Factory functions — these are what reducers call ─────────────────────────

val idle: Outcome<Nothing, Nothing, Nothing> = Outcome.Idle

fun <S : Any> updatedState(state: S): Outcome<S, Nothing, Nothing> =
    Outcome.UpdatedState(state)

fun <E : Any> newEffect(flow: FlowEffect<E>): Outcome<Nothing, E, Nothing> =
    Outcome.NewEffect(Effect.OfFlow(flow))

fun <E : Any, U : Any> newEffect(thunk: ThunkEffect<E, U>): Outcome<Nothing, E, U> =
    Outcome.NewEffect(Effect.OfThunk(thunk))

fun <S : Any, E : Any> outcome(state: S, flow: FlowEffect<E>): Outcome<S, E, Nothing> =
    Outcome.Both(state, Effect.OfFlow(flow))

fun <S : Any, E : Any, U : Any> outcome(state: S, thunk: ThunkEffect<E, U>): Outcome<S, E, U> =
    Outcome.Both(state, Effect.OfThunk(thunk))
```

`Outcome` has exactly four cases — `Idle`, `UpdatedState`, `NewEffect`, `Both` — and the set is
exhaustive; adding a fifth is forbidden (`KT-5`; implements `UZF-12`).

Variance makes the type math work: a `FlowEffect<HomeEvent>` becomes `Effect<HomeEvent, Nothing>`,
which is assignable to `Effect<HomeEvent, HomeUiEffect>` via the `out` modifier — so mixing Flow
and Thunk producer methods inside the same reducer's `when` is type-safe.

A reducer reads like English:

```kotlin
is OnAppeared              -> outcome(state.withLoading(), producer.loadSuggestions())
is OnSuggestionsLoaded     -> updatedState(state.withSuggestions(event.items))
is UserDidAcceptSuggestion -> newEffect(producer.markAccepted(event.id))
is UserDidTapEdit          -> newEffect(producer.navigateToEdit(event.id))   // UiEffect via Sink
is UserDidTapDismiss       -> idle
```

---

## 6. `Feature` base class

```kotlin
package {{APP_PACKAGE}}.library.uzf

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

abstract class Feature<State : Any, Event : Any, UiEffect : Any>(
    initialState: State,
) : ViewModel() {

    private val _state = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()

    private val _uiEffects = MutableSharedFlow<UiEffect>(
        replay              = 0,
        extraBufferCapacity = 8,
        onBufferOverflow    = BufferOverflow.DROP_OLDEST,
    )
    val uiEffects: SharedFlow<UiEffect> = _uiEffects.asSharedFlow()

    /** Sink threaded into every ThunkEffect. Wraps onEvent and the UiEffect SharedFlow. */
    private val sink = object : Sink<Event, UiEffect> {
        override fun dispatch(event: Event)        = onEvent(event)
        override fun signal(uiEffect: UiEffect)    { _uiEffects.tryEmit(uiEffect) }
    }

    /**
     * Pure reducer. Implement in subclasses. No I/O, no scope, no time, no random.
     * The reducer's job is to *describe* the new state and any effect; it does not perform.
     */
    protected abstract fun reduce(state: State, event: Event): Outcome<State, Event, UiEffect>

    /** Canonical entry point. Final — do not override. */
    fun onEvent(event: Event) {
        when (val o = reduce(state.value, event)) {
            Outcome.Idle             -> Unit
            is Outcome.UpdatedState  -> _state.value = o.state
            is Outcome.NewEffect     -> launch(o.effect)
            is Outcome.Both          -> { _state.value = o.state; launch(o.effect) }
        }
    }

    /**
     * View-layer-friendly alias for [onEvent]. Lets pages / screens read as
     * `store.send(Event.UserDidTap…)`, mirroring the TCA/Bloc ergonomics.
     * Semantically identical to [onEvent]; pick whichever reads better at the call site.
     */
    fun send(event: Event) = onEvent(event)

    private fun launch(effect: Effect<Event, UiEffect>) {
        when (effect) {
            is Effect.OfFlow  -> viewModelScope.launch { effect.flow.collect(::onEvent) }
            is Effect.OfThunk -> viewModelScope.launch { effect.thunk(sink) }
        }
    }
}
```

The base wires the whole loop: it holds the single `MutableStateFlow`, exposes state as a
read-only `StateFlow`, runs `reduce` at the one integration point, and executes both `FlowEffect`
and `ThunkEffect` forms transparently in `viewModelScope` — dispatching every result back through
`onEvent` (`KT-5`, `KT-5`, `KT-8`; implements `UZF-2`, `UZF-12`, `UZF-14`). The `UiEffect`
`SharedFlow` is configured `replay = 0`, `extraBufferCapacity ≥ 1`, `onBufferOverflow =
DROP_OLDEST` — never a `Channel`, never `replay ≥ 1` (`KT-9`; implements `UZF-15`).

### Why `tryEmit` is safe here

The `UiEffect` `SharedFlow` has `extraBufferCapacity = 8` and `onBufferOverflow = DROP_OLDEST`.
`tryEmit` always succeeds for SharedFlows configured with `DROP_OLDEST` — if the buffer is full,
the oldest unread element is dropped to make room. So `signal` is non-suspending and safe to call
from any context. (Using a `Channel` instead is forbidden: Channels are cold and miss emissions
while no collector is attached, a frequent source of "ghost" navigations after process death.)

### Why `send` exists alongside `onEvent`

Both methods do the same thing; `send` simply forwards to `onEvent`. The split is purely about
call-site ergonomics:

- **Pages / Screens** read better with `store.send(Event.UserDidTap…)` — the `store + send`
  vocabulary mirrors TCA / Bloc / Redux idiom and makes the intent ("ship this event into the
  loop") explicit.
- **Tests / Producers / internal callers** are free to use either. The dispatch sink wired into
  ThunkEffects calls `onEvent` directly because there is no view layer involved.

Adding a second public method does **not** widen the Feature's surface beyond the single-entry-point
rule (`KT-5`): both methods are inherited (subclasses declare neither), so the Feature
public-surface contract test — a Konsist / reflection check that a Feature subclass declares **no**
public functions of its own — still passes.

### Subclass shape

```kotlin
@HiltViewModel
class HomeFeature @Inject constructor(
    private val producer: HomeProducer,
    private val mapper:   HomeMapper,
) : Feature<HomeState, HomeEvent, HomeUiEffect>(initialState = HomeState()) {

    override fun reduce(state: HomeState, event: HomeEvent): Outcome<HomeState, HomeEvent, HomeUiEffect> = when (event) {
        is HomeEvent.OnAppeared              -> outcome(state.withLoading(), producer.loadSuggestions())
        is HomeEvent.OnSuggestionsLoaded     -> event.result.fold(
            onSuccess = { updatedState(state.withSuggestions(it)) },
            onFailure = { updatedState(state.withException(mapper.toException(it))) },
        )
        is HomeEvent.UserDidTapEdit          -> newEffect(producer.navigateToEdit(event.id))
        is HomeEvent.UserDidAcceptSuggestion -> newEffect(producer.markAccepted(event.id))
        is HomeEvent.UserDidTapDismiss       -> updatedState(state.withDismissedException())
    }
}
```

The reducer is **100 % pure** — no `viewModelScope`, no `signal`, no I/O, no time (`KT-5`). Every
side effect lives behind a Producer call, and every failure arrives as a single
`On…Completed(Result)` event translated to a `<Name>Exception` via the Mapper inside `reduce`
(`KT-8`; implements `UZF-3`). Subclasses are `@HiltViewModel`-annotated, `@Inject`-constructed, and
declare only `reduce` (`KT-3`).

---

## 7. Forbidden

- Overriding `onEvent` (or `send`) in a subclass. Define `reduce` instead (`KT-5`).
- Re-declaring `send` on a subclass — it's an inherited alias for `onEvent`. There is exactly one
  canonical entry point (`KT-5`).
- Touching `_state.value` directly from a subclass (`KT-5`).
- Calling anything on `viewModelScope` from inside `reduce`. The reducer is pure (`KT-5`).
- Calling `_uiEffects.tryEmit(...)` from anywhere outside the base class. UiEffects are emitted only
  via a thunk's `Sink` (`KT-9`).
- Constructing `Outcome.UpdatedState(...)` / `Outcome.NewEffect(...)` / `Outcome.Both(...)` by hand.
  Use the factory functions (`updatedState`, `newEffect`, `outcome`, `idle`) (`KT-5`).
- Constructing `Effect.OfFlow(...)` / `Effect.OfThunk(...)` directly inside a reducer. Use
  `newEffect(producer.x())` — overload resolution picks the right wrapper (`KT-5`, `KT-8`).
- Adding new cases to `Outcome` or `Effect`. The sets are exhaustive (`KT-5`).
- Adding extra public methods to the base class, or public mutating methods (`setX(...)`,
  `markY(...)`, `clearZ(...)`) to a subclass — model them as `Event` cases (`KT-5`).
- Putting project-specific code under `library/uzf/`: product-namespaced types (e.g.
  `{{PROJECT_NAME}}…`), app-module types, brand names, or domain types. The runtime is portable
  across projects — only `library/uzf/` content that compiles on a fresh Android Studio project may
  live here (`KT-3`).
