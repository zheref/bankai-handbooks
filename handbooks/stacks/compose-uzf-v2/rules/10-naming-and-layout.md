<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 10 — Naming and Layout

The file-suffix taxonomy, folder tree, and case-prefix conventions that make a
Compose UZF codebase greppable and predictable. This is the operational expansion
of the naming/layout rules coded in [`../architecture.md`](../architecture.md)
(`KT-{n}`) and the cross-platform concepts in
[`../../../uzf-core.md`](../../../uzf-core.md) (`UZF-{n}`).

## Repo-specific placeholders

- `{{CORE_FRAMEWORK}}` — the pure-Kotlin/JVM domain module (no Android imports)
  vending domain models, mappers, and business logic. Illustrative example: `AcmeCore`.
- `{{APP_PACKAGE}}` — the Android application's base package (the `src/main/java/…`
  path segment). Illustrative example: the app's root package.

(Domain-flavored names in examples — `Now`, `Suggestion`, `Endeavor`,
`Environment` — are illustrative, not repo config. `Hilt`, `Room`, `Retrofit`,
`AppDatabase`, `AppTheme` name the stack's fixed toolchain, not a product value.)

---

## Top-level module layout

```
<root>/
    app/                                 # Android application module
        src/main/java/{{APP_PACKAGE}}/
            features/<feature>/          # one folder per top-level screen (singular)
            library/                     # shared infrastructure (dispatchers, env)
            library/uzf/                 # project-agnostic UZF runtime (see below)
            library/di/                  # cross-cutting Hilt modules
            services/<x>/                # external-system wrappers
            models/                      # domain models + mocks + mappers
            ui/theme/                    # AppTheme, MaterialTheme wrapper
    {{CORE_FRAMEWORK}}/                  # pure-Kotlin/JVM domain (no Android imports)
```

> `library/uzf/` is **project-agnostic** — it contains only the runtime primitives
> every feature loop is built on: the `Feature<State, Event, UiEffect>` base class,
> `Outcome`, `Effect` (`OfFlow`/`OfThunk`), `Sink`, and the type aliases
> (`FlowEffect`, `ThunkEffect`, `Dispatch`, `EventStream`). Anything
> product-specific — services, theme, environment, DI wiring — lives **outside**
> `library/uzf/`. (`UZF-6`; base class per `KT-3`.)

## Per-feature layout (canonical)

A feature's wrapper, renderer, state, and effect machinery are **co-located** in a
single folder, even though each is formally a different layer — cognitive locality
beats layering purity (`UZF-6`).

```
features/<feature>/
    <Feature>Page.kt          # stateless @Composable (state, onEvent, modifier)   KT-1
    <Feature>Screen.kt        # stateful wrapper: hoists Feature, routes UiEffect   KT-1
    <Feature>Feature.kt       # @HiltViewModel : Feature<State, Event, UiEffect>    KT-3
    <Feature>State.kt         # State + Event + UiEffect (three sealed/data types)  KT-4/KT-9
    <Feature>Shifters.kt      # State.with…() copy functions                        KT-6
    <Feature>Selectors.kt     # top-level select…(state) functions                  KT-7
    <Feature>Producer.kt      # injected effect factory                             KT-8
    <Feature>Mapper.kt        # only if the feature has feature-local mapping        KT-20
    <Feature>Mocks.kt         # canned State variants for previews + tests           KT-18
    <Feature>Module.kt        # per-feature Hilt module                              KT-17
    fragments/                # @Composable Fragments (optional, stateless)          KT-1
    adapters/                 # @Composable Adapters (optional, list cells)          KT-1
```

The folder name is the feature name **without** any suffix and always **singular**:
`features/now/`, never `features/nows/` and never `features/nowPage/`.

## Type and file suffixes (greppable)

Every suffix is load-bearing: it lets a human or a Detekt/Konsist rule locate an
artifact by name alone.

| Concept | Suffix | Example | Canon |
| --- | --- | --- | --- |
| Feature subclass (class) | `Feature` | `NowFeature` | `UZF-1`, `KT-3` |
| Page (stateless composable) | `Page` | `NowPage` | `UZF-4`, `KT-1` |
| Screen (stateful composable) | `Screen` | `NowScreen` | `UZF-4`, `KT-1` |
| Fragment (composable) | `Fragment` | `EditNowFragment` | `UZF-4`, `KT-1` |
| Adapter (composable list cell) | `Adapter` | `SuggestionRowAdapter` | `UZF-5`, `KT-1` |
| State (data class) | `State` | `NowState` | `UZF-8`, `KT-4` |
| Event (sealed interface) | `Event` | `NowEvent` | `UZF-2`, `KT-5` |
| UiEffect (sealed interface) | `UiEffect` | `NowUiEffect` | `UZF-4`, `KT-9` |
| Exception (class) | `Exception` | `NowException` | `UZF-3`, `KT-20` |
| Service (interface) | `Service` | `SuggestionService` | `UZF-16`, `KT-10` |
| Live impl | `Live<X>Service` | `LiveSuggestionService` | `UZF-16`, `KT-10` |
| Stubbed impl | `Stubbed<X>Service` | `StubbedSuggestionService` | `UZF-16`, `KT-10` |
| Repository | `Repository` | `EndeavorRepository` | `UZF-16`, `KT-11` |
| Api (Retrofit/Ktor) | `Api` | `SuggestionApi` | `UZF-17`, `KT-19` |
| Database (Room) | `Database` | `AppDatabase` | `UZF-17`, `KT-19` |
| Provider (sync-only) | `Provider` | `EnvironmentProvider` | `KT-12` |
| Mapper | `Mapper` | `NowMapper` | `UZF-17`, `KT-20` |
| Response (wire type) | `Response` | `SuggestionResponse` | `UZF-8`, `UZF-17`, `KT-19` |
| Entity (Room) | `Entity` | `SuggestionEntity` | `UZF-17`, `KT-19` |
| Endpoint | `Endpoint` | `SuggestionEndpoint` | `UZF-17`, `KT-19` |
| Mocks file | `Mocks` | `NowMocks.kt` | `KT-18`, `KT-22` |
| Shifters file | `Shifters` | `NowShifters.kt` | `UZF-10`, `KT-6` |
| Selectors file | `Selectors` | `NowSelectors.kt` | `UZF-11`, `KT-7` |
| Producer file | `Producer` | `NowProducer.kt` | `UZF-15`, `KT-8` |
| Hilt module | `Module` | `NowModule.kt`, `RoomModule.kt` | `KT-17` |

## Event case prefixes (sealed interface, `UZF-2`, `KT-5`)

Events name **intent or signal**, never mechanism. Never name an event by what it
does (`fetchSuggestions`, `loadData`); name it by who fired it or what happened
(`UserDidPullToRefresh`, `OnSuggestionsLoaded`).

- `UserDid…` — user intent (`UserDidPressSubmit`, `UserDidTapEdit`).
- `On…` — system / lifecycle signal (`OnAppeared`, `OnConnectivityChanged`).
- `On…Completed` / `On…Failed` — effect resolution. Success **and** failure are
  unified in a single completion event carrying a `Result` (`UZF-3`):
  `OnFetchCompleted(Result<…>)`.
- `Child…Delegated…` — a child feature talking back to its parent
  (`ChildAuthDelegatedSignOut`).

## Shifter function prefixes (`UZF-10`, `KT-6`)

Shifters are extension functions on `State` returning a new `State` via `copy(...)`,
one concern each, living in `<Feature>Shifters.kt`. They read no clock, random,
env, or service.

- `with…` — the typical case (`withLoading`, `withProfile`, `withSuggestions`).
- `as…` — a type-level / identity re-shape transform (`asLoaded`, `asEmpty`).

## Selector function prefix (`UZF-11`, `KT-7`)

Selectors are top-level, pure, derived-only functions in `<Feature>Selectors.kt`,
consumed in Compose via `remember(state) { derivedStateOf { select…(state) } }`.

- `select…` — `selectVisibleSuggestions`, `selectFullName`. A boolean selector
  reads as a statement: `selectShouldShowEmptyState`.

## Producer method naming (`UZF-15`, `KT-8`)

Producers are injected classes (`class <Feature>Producer @Inject constructor(...)`)
whose public methods return effect factories — `FlowEffect<Event>` (preferred,
stream-style, cannot signal UiEffects) or `ThunkEffect<Event, UiEffect>` (imperative,
can `dispatch` events and `signal` UiEffects via its `Sink`).

- **Methods are plain verbs — no `produce…` prefix.** The `Producer` class suffix
  already conveys "effect factory," so call sites read `producer.loadSuggestions()`,
  `producer.markAccepted(id)`, `producer.navigateToEdit(id)`.
- Reducers never build effects inline; they call `producer.x(...)` and wrap the
  result via the `newEffect(...)` / `outcome(state, ...)` factories.

## Mocks and fixtures (`KT-18`, `KT-22`)

- Every feature folder carries a `<Feature>Mocks.kt` producing **canned `State`
  variants** — `loadingState`, `loadedState`, `erroredState`, `partiallyLoadedState`.
  Previews and Paparazzi/JUnit tests consume these; never construct `State` inline
  in a preview or test.
- Domain models ship with `mock*` companion fixtures (**≥7 variants**) in the same
  file as the model, marked with a `// region Mocks` band so they can be stripped
  from production if desired. Variants must include: happy, empty, long, non-ASCII,
  missing-optional-fields, stale-timestamp, and just-updated.

## Hilt module placement (`KT-17`)

- One Hilt module per feature folder, named `<Feature>Module.kt`.
- Cross-feature wiring (Retrofit/OkHttp, Room `Database` instances, app-wide
  singletons) lives in `library/di/`.
- DI modules live **only** in `library/di/` or a feature folder — nowhere else.

## Provider vs. Service naming (`KT-12`)

`…Provider` is reserved for **synchronous, sync-only** helpers (`fun current(): X`)
that a reducer may read directly. Anything that could suspend or hit I/O must be a
`…Service` (interface + `Live…` + `Stubbed…`, Hilt-bound), which a reducer may
**not** call. Ad-hoc helper names like `…Store`, `…Resolver`, or `…Holder` are
allowed **only** for that Provider tier; an application-specific helper that plays
the role of a Service must be promoted to an `interface …Service` before it can be
injected into a Feature.

## Forbidden

- Renaming a `<Name>Feature` subclass to `<Name>ViewModel` or `<Name>Interactor`
  (legacy). New code uses the `Feature` suffix. (`KT-3`.)
- Putting Shifters, Selectors, or Producers in the same file as the `Feature`
  subclass — each has its own suffixed file. (`KT-6`, `KT-7`, `KT-8`.)
- Plural feature folders (`features/nows/`). Always singular (`features/now/`).
- Suffixing a feature **folder** (`features/nowPage/`) — suffixes are for files;
  folders are the bare PascalCase-free feature name.
- DI modules outside `library/di/` or a feature folder. (`KT-17`.)
- Cross-feature imports — features are isolated; shared logic goes to `library/`,
  `models/`, or `{{CORE_FRAMEWORK}}`. (`UZF-6`.)
- Passing an application-specific helper object into a Feature without an
  `interface …Service` or sync `…Provider` abstraction. (`KT-10`.)
