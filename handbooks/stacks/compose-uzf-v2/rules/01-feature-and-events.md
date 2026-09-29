<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 01 — Feature & Events

## Repo-specific placeholders

- `{{UZF_RUNTIME_ROOT}}` — the common module root holding the UZF runtime (`{{UZF_RUNTIME_ROOT}}/uzf`, which houses the `Feature<…>` base class and its supporting types — `Outcome`, `Sink`, effect aliases) and cross-feature DI (`{{UZF_RUNTIME_ROOT}}/di`). Illustrative example: `library`.

(Feature/State/Event names in the snippets — `Suggestions`, `Auth` — are illustrative, not repo config. `@HiltViewModel`, `hiltViewModel()`, `StateFlow`, `SharedFlow`, `Result`, Retrofit/Room/`SharedPreferences` are universal Kotlin/Android/Compose API names and are never tokenized.)

Encodes the Compose realization of the UZF single-mutating-entry-point contract: every screen is one `@HiltViewModel` Feature whose only public mutating surface is `onEvent`, and whose logic is a pure `reduce`. The shared base class itself is specified in [`02-base-class.md`](02-base-class.md).

---

## The Feature (`KT-3`, `KT-5`)

**Hard rules**

- **One Feature = one screen.** The per-screen subclass is named `<Name>Feature` (e.g. `SuggestionsFeature`, `AuthFeature`) — **never** `…ViewModel`, `…Interactor`, or `…Store` for new code (`KT-3`). Existing `…ViewModel` classes are grandfathered but must be renamed to `…Feature` when materially edited.
- The subclass is annotated `@HiltViewModel`, scoped into Composables via `hiltViewModel()` (never `remember { … }`), and inherits the product-agnostic `Feature<State, Event, UiEffect>` base class from `{{UZF_RUNTIME_ROOT}}/uzf`. The base preserves the rules below — it may not introduce hidden state or an implicit `_state.value = …` shortcut (`KT-3`).
- The base class provides the public read-only surface: `state: StateFlow<State>` and `uiEffects: SharedFlow<UiEffect>`. These are the **only** public members besides the entry point (`KT-5`). Read `state` from Compose with `collectAsStateWithLifecycle()`, never plain `collectAsState()`.
- **Exactly one canonical mutating entry point: `fun onEvent(event: <Name>Event)`** (`KT-5`). The base class also exposes `fun send(event) = onEvent(event)` as a view-layer-friendly alias. Subclasses declare **neither** — both are inherited.
  - **Convention from the view layer:** hoist the Feature as `store` and call `store.send(Event.UserDidTap…)`.
  - Tests are free to call either `vm.onEvent(...)` or `vm.send(...)` — they are the same method.
- **No other public methods.** `setX`, `markY`, `clearZ`, `refresh`, `submit` — all of these are `Event` cases, not methods. If you find yourself adding a public mutator, model it as an `Event` instead (`KT-5`).

## Event naming (`UZF-2`)

Events are a `sealed interface <Feature>Event` with case prefixes:

| Source | Prefix | Example |
| --- | --- | --- |
| User intent (tap, swipe, type, drag) | `UserDid…` | `UserDidTapEdit`, `UserDidPullToRefresh` |
| System / lifecycle signal | `On…` | `OnAppeared`, `OnViewLoaded(id)` |
| Effect resolution (success + failure unified via `Result`, `UZF-3`) | `On…Completed` / `On…Failed` | `OnProfileFetchCompleted(Result<Profile>)` |
| Child feature talking back | `Child…Delegated…` | `ChildAuthDelegatedSignOut` |

Name an event by its **intent or source**, never by its mechanism — `UserDidPullToRefresh` / `OnProfileFetchCompleted`, not `fetchProfile` or `loadData` (`UZF-2`).

## Reducer body shape (`KT-5`)

`onEvent` is `final` on the base class. Subclasses implement only `protected fun reduce(state, event): Outcome<State, Event, UiEffect>`, which is **100 % pure** — it describes what should happen; it never performs it.

```kotlin
override fun reduce(state: SuggestionsState, event: SuggestionsEvent): Outcome<SuggestionsState, SuggestionsEvent, SuggestionsUiEffect> = when (event) {
    is SuggestionsEvent.OnAppeared              -> outcome(state.withLoading(), producer.loadSuggestions())
    is SuggestionsEvent.OnSuggestionsLoaded     -> event.result.fold(
        onSuccess = { updatedState(state.withSuggestions(it)) },
        onFailure = { updatedState(state.withException(mapper.toException(it))) },
    )
    is SuggestionsEvent.UserDidAcceptSuggestion -> newEffect(producer.markAccepted(event.id))
    is SuggestionsEvent.UserDidTapEdit          -> newEffect(producer.navigateToEdit(event.id))
    is SuggestionsEvent.UserDidTapDismiss       -> idle
}
```

`Outcome<S, E, U>` has exactly **four cases**, each with a natural-reading factory function:

| Case | Factory | Meaning |
| --- | --- | --- |
| `Idle` | `idle` | Nothing happens. |
| `UpdatedState(newState)` | `updatedState(s)` | State replaced; no effect. |
| `NewEffect(effect)` | `newEffect(...)` | Effect launched; state unchanged. |
| `Both(newState, effect)` | `outcome(s, ...)` | State replaced **and** an effect launched. |

These four cover every situation. Navigation, snackbars, and other one-shot view signals are **not** returned by the reducer directly: they are Producer thunks that call `sink.signal(...)`, and the reducer just returns `newEffect(producer.navigateToX(...))` (see `04-producers-effects-uieffects.md`). The base class's executor runs both `FlowEffect` and `ThunkEffect` forms transparently in `viewModelScope`, and every result event is dispatched back through the same `onEvent` entry point — the reducer never sets state directly.

## Forbidden (`KT-5`)

- Overriding `onEvent`. Define `reduce` instead.
- Setting `_state.value = …` directly from a subclass.
- Any `viewModelScope`, `signal(...)`, `tryEmit`, or I/O call from inside `reduce`. The reducer is pure — it describes, it does not perform.
- `runBlocking` (except in tests) or `GlobalScope.launch`.
- Calling Retrofit / Room / `SharedPreferences` from anywhere in the subclass. Those live behind Producers + Services (see `04`/`06`).
- Throwing from the reducer. Convert `Throwable`s via a Mapper to `<Feature>Exception` cases inside the reducer (`UZF-3`).
- More than one `onEvent` overload, or any additional public mutator method (`KT-5`) — there is exactly one entry point.
