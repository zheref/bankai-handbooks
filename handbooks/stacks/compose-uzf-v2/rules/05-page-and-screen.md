<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 05 — Page and Screen

## Repo-specific placeholders

- `{{APP_SOURCE_ROOT}}` — app source root that holds each feature folder's `…Page.kt` and `…Screen.kt` files.
- `{{LINT_SCRIPT}}` — architecture-lint script (Konsist/Detekt-backed) that fails the build on the violations coded below: DI/navigation inside a Page, a Page taking anything other than `(state, onEvent, modifier)`, or a Page with no `@Preview`.

A feature with UI is **two Composables, never one** (`KT-1`): a stateless **Page** and a stateful **Screen**. This is the active/passive split of `UZF-7` expressed in Compose — the Page is a passive renderer (a pure function of `State`), the Screen is the active wrapper that hoists the Feature, subscribes to state, and routes one-shot `UiEffect`s to navigation and system callbacks.

## Page — stateless (`KT-1`, `KT-2`; implements `UZF-4`)

A Page is a pure function of its `State`. It renders and raises intents; it owns no dependencies.

- Signature **exactly**: `@Composable fun <Feature>Page(state: <Feature>State, onEvent: (<Feature>Event) -> Unit, modifier: Modifier = Modifier)`. Nothing else in the parameter list — extra inputs are props the Screen must derive and fold into `State`, not parameters random callers pass (`KT-2`).
- No `hiltViewModel()`, no `viewModel()`, no dependency injection of any kind (`KT-2`).
- No `LaunchedEffect` that touches a Feature/`ViewModel` or a `NavController`.
- No imports from `androidx.navigation.*`, `androidx.hilt.*`, `dagger.*`, `androidx.lifecycle.*`, or `android.content.Context` — a Page is framework-free below Compose so it stays snapshot- and preview-testable (`KT-2`, mirrors `UZF-4`).
- May read Selectors via `remember(state) { derivedStateOf { … } }` — derivation off `State` is allowed; reaching outside `State` is not.
- The `onEvent` lambda is the single upward channel; every user intent goes through it (`UZF-2`). No Page-local mutation, no callbacks-per-button in the signature.
- Must define **≥ 3 `@Preview`** functions (`KT-13`): at minimum `loading`, `loaded`, `errored`. Each consumes a canned `State` from the feature's `<Feature>Mocks.kt` — never construct `State` inline in a preview. Previews mirror the Paparazzi snapshot tests 1:1 (`UZF-18`, `UZF-26`).

```kotlin
// {{APP_SOURCE_ROOT}}/userprofile/UserProfilePage.kt
// NOTE: this file imports nothing from androidx.navigation / androidx.hilt / dagger / androidx.lifecycle.
@Composable
fun UserProfilePage(
    state:    UserProfileState,
    onEvent:  (UserProfileEvent) -> Unit,
    modifier: Modifier = Modifier,
) { … }

@Preview(name = "Loading")
@Composable
private fun UserProfilePage_Loading() {
    AppTheme { UserProfilePage(state = UserProfileMocks.loadingState, onEvent = {}) }
}

@Preview(name = "Loaded")
@Composable
private fun UserProfilePage_Loaded() {
    AppTheme { UserProfilePage(state = UserProfileMocks.loadedState, onEvent = {}) }
}

@Preview(name = "Errored — network")
@Composable
private fun UserProfilePage_Errored() {
    AppTheme { UserProfilePage(state = UserProfileMocks.erroredState, onEvent = {}) }
}
```

## Screen — stateful wrapper (`KT-1`, `KT-3`)

A Screen is the **only** Composable in a feature that touches Hilt, lifecycle, navigation, or system services (`KT-1`). It hoists the Feature, subscribes to state, drains one-shot effects, and forwards them to callbacks the caller supplies.

- Signature: `@Composable fun <Feature>Screen(... callbacks ..., store: <Feature>Feature = hiltViewModel())`. The Feature parameter is named `store` — that vocabulary mirrors TCA/Bloc/Redux and pairs with `store.send(...)` at call sites (`UZF-2`).
- Collects state with `collectAsStateWithLifecycle()` — **never** plain `collectAsState()` — so collection stops below the started lifecycle state and resumes correctly across configuration changes and process death (`KT-4`).
- Collects `uiEffects` with `LaunchedEffect(store) { store.uiEffects.collect { … } }` and routes each case to a callback parameter. `uiEffects` is a `SharedFlow` (`replay = 0`, `extraBufferCapacity ≥ 1`, `onBufferOverflow = DROP_OLDEST`), never a `Channel` — a cold `Channel` misses emissions while no collector is attached, producing "ghost" navigations after process death (`KT-9`; see `04-producers-effects-uieffects.md`).
- Dispatches the `OnAppeared` (or similar) lifecycle event via `LaunchedEffect(<real key>) { store.send(...) }`. Use a real key — `store`, or the id the effect depends on — never `LaunchedEffect(true)` or `LaunchedEffect(Unit)` (`KT-27`).
- Passes `store::send` as the `onEvent` lambda to the Page. (`store::send` and `store::onEvent` resolve to the same `final` entry point; `send` is the canonical view-layer name — `UZF-2`.)
- Navigation is data, not a call: the Feature emits a `UiEffect.NavigateTo…` case and the Screen maps it to an `onNavigateTo…` callback (which the caller wires to a `NavController`). Reducers and Pages never touch `NavController` directly (`KT-9`, `KT-15`).
- The Screen contains **no layout** — no `Column`, no padding, no colors. If layout creeps in, it belongs in the Page (`KT-1`).

```kotlin
// {{APP_SOURCE_ROOT}}/userprofile/UserProfileScreen.kt
@Composable
fun UserProfileScreen(
    onNavigateToEdit: (ProfileId) -> Unit,
    onShowSnackbar:   (String) -> Unit,
    store:            UserProfileFeature = hiltViewModel(),
) {
    val state by store.state.collectAsStateWithLifecycle()
    LaunchedEffect(store) { store.send(UserProfileEvent.OnAppeared) }
    LaunchedEffect(store) {
        store.uiEffects.collect { effect ->
            when (effect) {
                is UserProfileUiEffect.NavigateToEdit -> onNavigateToEdit(effect.id)
                is UserProfileUiEffect.ShowSnackbar   -> onShowSnackbar(effect.message)
            }
        }
    }
    UserProfilePage(state = state, onEvent = store::send)
}
```

## Forbidden

- Calling `hiltViewModel()` (or `viewModel()`, or constructing a Feature via `remember { … }`) from inside a Page (`KT-2`).
- Passing the Feature, `store`, or a `NavController` into a Page (`KT-2`).
- A Page that imports `androidx.lifecycle.*`, `androidx.navigation.*`, `androidx.hilt.*`, `dagger.*`, or `android.content.Context` (`KT-2`).
- A "Page" Composable whose parameter list is anything other than `(state, onEvent, modifier)` (`KT-2`).
- `collectAsState()` in a Screen where `collectAsStateWithLifecycle()` is required (`KT-4`).
- `LaunchedEffect(true)` or `LaunchedEffect(Unit)` — almost always wrong; use a real key (`KT-27`).
- Exposing `uiEffects` as a `Channel`/`receiveAsFlow()`, or as a `SharedFlow` with `replay ≥ 1` — the latter re-fires the most recent effect on every screen re-entry (`KT-9`).
- Calling `Toast.makeText(...)` or invoking a `Snackbar` API from any Composable. Emit `UiEffect.ShowSnackbar(...)` and let the Screen route it to a `SnackbarHost` (`KT-16`).
- Layout code (`Column`, padding, colors, hard-coded typography) in a Screen — it belongs in the Page (`KT-1`).
- A Page with no `@Preview`. `{{LINT_SCRIPT}}` must fail the build on this (`KT-13`).
