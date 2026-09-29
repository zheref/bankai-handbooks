<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 11 — Forbidden Patterns (quick reference)

Reject any PR or generated code that contains a pattern below. This file is the
**single greppable reject list** for the Compose UZF stack — every other rule file
points back here. Each entry is tagged with its parent cross-platform **`UZF-{n}`**
concept (where one exists) and the Compose/Kotlin stack binding **`KT-{n}`** (the
Compose analog of the SwiftUI `SW-{n}` codes). Codes are **stable and append-only** —
never renumber. A `KT-{n}` may tighten its `UZF-{n}` parent but never contradicts it.

## Repo-specific placeholders

| Token | Illustrative value | What it is |
| --- | --- | --- |
| `{{PROJECT_NAME}}` | `Acme` | Product/brand name; also the prefix of product-specific type names (`{{PROJECT_NAME}}ToastBus`, `{{PROJECT_NAME}}ViewModel`). |
| `{{UZF_RUNTIME_ROOT}}` | `library` | Common module root holding the portable UZF runtime (`{{UZF_RUNTIME_ROOT}}/uzf` — the base `Feature`, `Outcome`, `Sink`, effect typealiases) and cross-feature DI (`{{UZF_RUNTIME_ROOT}}/di`). The runtime subfolder must compile on a fresh Android-Studio project with no app-specific types. |

> A token that appears in a rule file MUST be listed here. Adding or renaming a token is
> a Naruto G4 change (keep the generator's substitution map in lockstep). Stack-standard
> libraries (Hilt, Compose, Coroutines, Retrofit, Room, Paparazzi, Turbine) are **not**
> tokenized — they are the stack, the same way TCA is fixed on the SwiftUI stack.

---

## Architecture

- Overriding `onEvent` (or `send`) in a subclass. Both are `final` on the `Feature` base — implement `reduce` instead. (KT-5)
- Re-declaring `send` on a `Feature` subclass. It is an inherited one-line alias for `onEvent`; subclasses must not shadow it. (KT-5)
- Subclass-declared public mutating methods on a `Feature` (`setX(...)`, `markY(...)`, `clearZ(...)`). Only the inherited `onEvent` / `send` entry points are allowed — model every mutator as an `Event` case. (KT-5)
- Any side effect (`viewModelScope`, `signal(...)`, `tryEmit(...)`, I/O, time, random) inside `reduce`. The reducer is 100 % pure — it describes an `Outcome`; it does not perform. (UZF-12, UZF-13, KT-5)
- `_state.value = …` from a subclass. State is replaced only at the base class's `onEvent` integration point. (UZF-15, KT-5)
- Emitting to `_uiEffects` (or any UiEffect stream) from anywhere outside the base class's `Sink` machinery. UiEffects are signaled only via a Producer-built `ThunkEffect`'s `Sink.signal(...)`. (UZF-15, KT-9)
- Product-specific code (brand type prefixes such as `{{PROJECT_NAME}}…`, domain types) under `{{UZF_RUNTIME_ROOT}}/uzf`. The runtime is portable — anything under `{{UZF_RUNTIME_ROOT}}/uzf` must compile on a fresh Android-Studio project with no app-specific types. (UZF-6, KT-28)
- A `sealed interface <Feature>Effect` enumerating domain effects. Domain Effects are anonymous `FlowEffect<E>` (`= Flow<E>`) or `ThunkEffect<E, U>` (`= suspend (Sink<E, U>) -> Unit`) factories returned by Producers — never an enum. (UZF-12, KT-8)
- Mixing view-tier `UiEffect` cases (navigate, snackbar, toast) with domain `Effect` cases in the same sealed type. Domain Effects produce Events; UiEffects exit the system. They are different concepts and different types. (KT-9)
- `Channel<UiEffect>.receiveAsFlow()` for one-shot view effects. Channels are cold and miss emissions while no collector is attached (a frequent source of "ghost" navigations after process death) — use `SharedFlow(replay = 0, extraBufferCapacity ≥ 1, onBufferOverflow = DROP_OLDEST)`. (KT-9)
- `SharedFlow<UiEffect>(replay = 1)` — must be `replay = 0`, or the most recent effect replays on every screen re-entry. (KT-9)
- Constructing `Outcome.UpdatedState(...)` / `Outcome.NewEffect(...)` / `Outcome.Both(...)` / `Effect.OfFlow(...)` / `Effect.OfThunk(...)` by hand. Use the factory functions (`idle`, `updatedState`, `newEffect`, `outcome`). (KT-5)
- Global event buses (e.g. `{{PROJECT_NAME}}ToastBus`, `AppToastBus`) emitted from feature code. A global toast/snackbar `SharedFlow` is allowed **only** for app-singleton emitters with no UI parent (auth-refresh workers, telemetry hooks). Feature code uses `<Feature>UiEffect`. (KT-16)
- Empty / placeholder Repositories. A Repository exists only when it actively coordinates ≥ 2 Services — delete it until it has a real job. (UZF-16, KT-11)
- `…Store`, `…Resolver`, `…Holder` data classes injected into Features without an interface abstraction. Promote to `interface …Service` (if it suspends or hits I/O) or `interface …Provider` (if it is synchronous and cheap). (UZF-16, KT-10)

## Compose

- `@Composable fun <Feature>Page(...)` taking anything other than `(state, onEvent, modifier)`. Extra inputs are props passed down by the Screen, never pulled from random callers. (UZF-4, KT-2)
- A Page that calls `hiltViewModel()`, `remember { MyFeature() }`, `viewModel<MyVM>()`, or otherwise instantiates/hoists the Feature. Hoisting belongs to the stateful `<Feature>Screen`, via `hiltViewModel<MyFeature>()`. (UZF-4, KT-2)
- A Page that imports `androidx.navigation.*` or `androidx.hilt.*`. Pages are stateless and navigation-free; the Screen owns those. (UZF-4, KT-2)
- `collectAsState()` — use `collectAsStateWithLifecycle()`. (KT-4)
- `LaunchedEffect(true)` or `LaunchedEffect(Unit)` for one-shot work that should be keyed. (KT-27)
- Hard-coded colors / sizes / typography in a Page or Fragment. Read design tokens via `AppTheme` / `MaterialTheme`. (KT-14)
- `Toast.makeText(...)` or `Snackbar` called from inside a Composable. Emit `UiEffect.ShowSnackbar(...)` and let the Screen host it via `SnackbarHost`. (KT-16)
- A Page without ≥ 3 `@Preview` Composables (idle / loading / loaded / errored variations); Paparazzi snapshots cover at least the three main states 1:1 with previews. (UZF-26, KT-13)

## Coroutines

- `runBlocking` outside test code. (KT-26)
- `GlobalScope.launch` anywhere. (KT-26)
- `viewModelScope.launch { service.x() }` from inside a `Feature`. Route I/O through a Producer; effects dispatch result events back into `onEvent` and never set state directly. (UZF-7, UZF-12, KT-8)

## Dependency injection

- `@HiltAndroidApp` not annotated on the `Application` class. (KT-23)
- Field injection (`@Inject lateinit var foo: Foo`). Use constructor injection. (KT-25)
- Service Locator (`object SuggestionServiceProvider.get()`). (KT-25)
- Manual ViewModel instantiation in Composables. (UZF-4, KT-3)
- Hilt modules that bind nothing. (KT-24)

## Data layer

- Feature code importing `retrofit2.*`, `androidx.room.*`, or `android.content.SharedPreferences`. I/O libraries stay behind a `…Service` interface (network → wrap a Retrofit `Api`; storage → wrap a Room `Dao`; system → wrap `Context`-bound APIs). (UZF-16, KT-19)
- A `Service` without a `Stubbed` impl. Every `interface …Service` ships a `Live…Service` (Hilt-bound) and a `Stubbed…Service` for tests. (UZF-16, KT-10)
- A `Service` holding mutable state. Move it to a Repository — the only service-tier type allowed to hold state, and only when required (caches, in-flight token-refresh deduping). (UZF-16, KT-10)
- Domain models annotated with `@Serializable`, `@Entity`, or `@SerialName`. Those annotations belong on `Response` / `Entity` types; map to a domain Model at the boundary. (UZF-8, UZF-17, KT-21)
- `Throwable` stored inside `State`. Reducers never throw; translate to `<Feature>Exception` via the Mapper. (UZF-8, KT-4)

## Models & mocks

- Domain models with < 7 `mock*` variants in the companion object. Variants must include happy, empty, long, non-ASCII, missing-optional-fields, stale-timestamp, and just-updated. (KT-18)
- Mocks defined inside test files instead of the model's `companion object` / a feature `…Mocks.kt`. (KT-18)
- A Page or test constructing `State` inline instead of via `<Feature>Mocks` (`loadingState`, `loadedState`, `erroredState`, `partiallyLoadedState`). (KT-18)

## Testing

- Robolectric for unit-test layers. Use Paparazzi (hermetic, JVM, no emulator) + plain JUnit. (KT-22)
- Tests gated on `@Ignore` for more than a single PR's lifetime. (KT-22)
- `runBlocking` in tests — use `runTest`. (KT-22)
- Production code conditionally checking `BuildConfig.DEBUG` to alter test outcomes. Use DI bindings instead. (KT-22)

## Commit messages

- `Co-Authored-By: Claude …`, `Co-Authored-By: GPT …`, `Co-Authored-By: Gemini …`, `Co-Authored-By: Copilot …`, or any `Co-Authored-By:` trailer crediting an LLM model. Commits are clean Conventional Commits attributed to the human author only. (bankai `_conventions.md`)
- Multi-page commit bodies with exhaustive bullet lists rehashing what the diff already shows. Subject ≤ 72 chars; the body (when present) is one or two short paragraphs explaining the *why*. (bankai `_conventions.md`)
