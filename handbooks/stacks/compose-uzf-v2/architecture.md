# Stack: `compose-uzf-v2` — Jetpack Compose + UZF Architecture Handbook

Concrete UZF bindings for **Android Jetpack Compose, Kotlin 2.1+, Hilt,
Coroutines/Flow, Supabase/Ktor + Room**, under **UZF v2**. Sasuke cites these as
`KT-{n}`. They **implement** the cross-platform rules in
[`../../uzf-core.md`](../../uzf-core.md) (`UZF-{n}`) with Compose/Kotlin specifics —
a `KT-{n}` rule may tighten but never contradict its `UZF-{n}` parent.

Reference implementation: a live, private Android product recorded in the consumer
registry (its rules + the `SYNTHESIS_JETPACK_COMPOSE_v2` conception doc). Existing `…ViewModel` classes are grandfathered
but must be renamed to `…Feature` when materially edited. Rule numbers are
append-only.

---

## A. The Feature (Interactor) & event loop (implements UZF-1, UZF-2, UZF-12)

**KT-1 — One `Feature` subclass per screen.** `<Name>Feature`, `@HiltViewModel`,
inheriting the project-agnostic `Feature<State, Event, UiEffect>` base from
`library/uzf/`; obtained in Composables via `hiltViewModel()`. Never
`remember { …Feature() }`.

**KT-2 — Single `onEvent(event)` entry point.** `onEvent` (and its view-layer alias
`send`) are `final` on the base; subclasses implement only
`protected fun reduce(state, event)`. There is exactly one entry point — no
`setX(...)`/`markY(...)`/`clearZ(...)` and no second `onEvent`-style method.

**KT-3 — `reduce` is 100% pure and returns an `Outcome`.** `reduce` returns
`Outcome<State, Event, UiEffect>` (`Idle` / `UpdatedState` / `NewEffect` / `Both`,
built via the `idle`/`updatedState`/`newEffect`/`outcome` factories — never
hand-constructed). No `viewModelScope`, no `signal`, no I/O, no `_state.value =`
inside `reduce`.

## B. State, Shifters, Selectors (implements UZF-8, UZF-9, UZF-10, UZF-11)

**KT-4 — State is an immutable `data class` exposed as `StateFlow`.** `val`-only,
domain types only (never `Throwable`, `Response<…>`, `Job`, or mutable
collections). Read in Compose with `collectAsStateWithLifecycle()`, never plain
`collectAsState()`.

**KT-5 — Shifters are `State.with…()` copy functions.** In `<Name>Shifters.kt`:
`fun State.with…(): State = copy(...)`, one concern each, `with…`/`as…` prefixes.
No inline `copy(...)` in `reduce`. Shifters read no clock/random/env/service.

**KT-6 — Selectors are top-level `select…(state)` functions.** In
`<Name>Selectors.kt`, consumed in Compose via
`remember(state) { derivedStateOf { select…(state) } }` to scope recomposition.

## C. Effects, Producers & UiEffect (implements UZF-3, UZF-13, UZF-14, UZF-15)

**KT-7 — Producers are injected effect factories.** `<Name>Producer.kt`,
`@Inject`, plain-verb methods returning `FlowEffect<E>` (`Effect.OfFlow`) or
`ThunkEffect<E,U>` (`Effect.OfThunk`, a `suspend (Sink<E,U>) -> Unit`). No I/O at
construction; never touch Retrofit/Room/SharedPreferences/`Context` outside a
Producer.

**KT-8 — Effects run in `viewModelScope` and dispatch back through `onEvent`.** An
effect never sets `_state.value` directly; it calls `sink.dispatch(On…Completed(result))`.
Producers never throw — failures are `Result.failure` dispatched as a single
`On…Completed(Result)` event (success/failure encoded in the `Result`, per UZF-3),
translated to `<Name>Exception` via a Mapper inside `reduce`.

**KT-9 — `UiEffect` is a separate sealed type on a `MutableSharedFlow(replay = 0,
extraBufferCapacity = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)`.**
Navigation, snackbars, and toasts are `UiEffect`s, **never** State, never a
`Channel`, never `replay >= 1`. Emitted only via `sink.signal(...)`
inside a `ThunkEffect`; a `FlowEffect` cannot signal (its `U = Nothing`). The
Screen consumes `uiEffects` via `LaunchedEffect` and routes them to callbacks;
`reduce` never calls a `NavController` and Composables never call
`Toast.makeText(...)`.

## D. Page/Screen split (implements UZF-4, UZF-5)

**KT-10 — Pages are stateless; Screens are the stateful wrapper.** `@Composable fun
<Name>Page(state, onEvent, modifier)` — **exactly** those params — is pure,
preview- and Paparazzi-testable, and imports no `androidx.navigation.*`/
`androidx.hilt.*`/`androidx.lifecycle.*`/`dagger.*`/`Context`. `@Composable fun
<Name>Screen(...)` is the only Hilt/lifecycle/nav touchpoint: it `hiltViewModel()`s
the Feature (named `store`), `collectAsStateWithLifecycle()`s the state, routes
`uiEffects` to callbacks, and passes `store::send`.

**KT-11 — ≥3 `@Preview` per Page, from `<Name>Mocks`.** Loading / loaded / errored
variations minimum, built from `<Name>Mocks.kt` (never inline `State` in a
preview/test). Hard-coded colors/sizes/typography in any Page/Fragment are
forbidden — read tokens from `object AppTheme` via `MaterialTheme`.

## E. Services, data & DI (implements UZF-16, UZF-17)

**KT-12 — Services are interfaces with ≥2 impls, Hilt-bound.** `interface
<X>Service { suspend fun …: Result<…> }` + `Live<X>Service @Inject` + a
`Stubbed<X>Service` (with a `sealed class Scenario`), bound via `@Binds` in an
`@InstallIn(SingletonComponent::class)` module. Services are **stateless**; state
lives only in a `Repository` (empty Repositories forbidden). A synchronous
`Provider` (`fun current(): X`) is the only service-tier type `reduce` may read.
Feature code never imports `retrofit2.*`/`androidx.room.*`/`SharedPreferences`.

**KT-13 — Wire ↔ domain via Mapper; Room/Retrofit at the boundary.** Network →
Ktor/Retrofit `Api` returning `@Serializable data class …Response`; storage → Room
`@Dao` with `…Query` (`@Query`) and `…Mutation` (`@Upsert/@Insert/@Delete`)
operations over `@Entity`. A Mapper (`toDomain`/`fromDomain`/`toException`)
converts. Domain models carry no `@Serializable`/`@Entity`/`@SerialName`.

## F. Testing (implements UZF-18, UZF-19, UZF-20)

**KT-14 — JUnit5 + Turbine + Paparazzi.** ≥3 tests per Shifter/Selector/
Producer-method/Mapper-fn/reducer-arm; the Feature is tested through Turbine on
state + `uiEffects`; each Page has Paparazzi snapshots matching its `@Preview`
count; ≥7 mocks per domain model (happy/empty/long/non-ASCII/missing-optional/
stale/fresh) in a `companion object`. Forbidden: Robolectric, `runBlocking` (use
`runTest`), inline-`State` tests, and tests hitting Retrofit/Room without a
`Stubbed` boundary.

## G. Anti-patterns (auto-reject)

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
| UiEffect | `sealed interface …UiEffect` on `MutableSharedFlow(replay=0, extraBufferCapacity=1, onBufferOverflow=DROP_OLDEST)` |
| Reducer | `protected fun reduce(state, event): Outcome<…>` |
| Shifter | `fun State.with…(): State = copy(...)` |
| Selector | top-level `fun select…(state): X` |
| Producer | `@Inject class …Producer` → `FlowEffect`/`ThunkEffect` |
| Effect | suspend lambda run in `viewModelScope` |
| Wrapper / renderer | `…Screen` (stateful) / `…Page` (stateless) |
| Service | `interface …Service` + `Live…`/`Stubbed…`, Hilt-bound |
| Result / Exception | `kotlin.Result<T>` / `sealed class …Exception(message, recoverable)` |
