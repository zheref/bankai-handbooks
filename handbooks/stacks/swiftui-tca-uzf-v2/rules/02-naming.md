<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 02 — Naming

## Repo-specific placeholders

- `{{PREVIEW_HOST_TARGET}}` — the isolated preview app target that compiles TCA-free `…View.swift` files. Illustrative example: `PreviewHost`.

(Domain-model names in examples — `Profile`, `Endeavor`, `FormValues` — are illustrative, not repo config.)

---

## Files and types

| Artifact | File suffix | Type form |
| --- | --- | --- |
| Screen (v2, replaces Page) | `…Screen.swift` | `struct …Screen: View` — `@Bindable var store: StoreOf<…Feature>`; hosts navigation; renders `…View(…)` (SW-1, SW-3) |
| Fragment | `…Fragment.swift` | `struct …Fragment: View` — `@Bindable var store: StoreOf<…Feature>`; renders `…View(…)` |
| View (v2, new) | `…View.swift` | `struct …View: View` — pure SwiftUI; **no `import ComposableArchitecture`**; plain values + closures; ≥3 `#Preview` blocks; `{{PREVIEW_HOST_TARGET}}` target member (SW-2) |
| Component (no domain) | (none, or domain-less name) | `struct …: View`, lives in `Design/`, no TCA (UZF-5, SW-5) |
| Adapter (list cell) | `…Adapters.swift` | `@ViewBuilder func …Adapter(…) -> some View` on `extension View` |
| Interactor (declaration) | `…Feature.swift` | `@Reducer struct …Feature` |
| Interactor (instance) | (variable name) | `…Interactor` (e.g., `userProfileInteractor: StoreOf<UserProfileFeature>`) |
| State | nested in `…Feature.swift` | `@ObservableState struct State` (SW-6) |
| Selectors | `…Selectors.swift` | `extension …Feature.State { var fooSelector: T { … } }` (UZF-11, SW-9) |
| Shifters | `…Shifters.swift` | `extension …Feature.State { mutating func applyFoo(...) { … } }` (used in reducers). Optional `#if DEBUG` `func withFoo(...) -> Self` for fluent test/preview state assembly only. (UZF-10, SW-8) |
| Producer | `…Producer.swift` | `extension …Feature { static func produceXEffect(...) -> Effect<Action> }` (UZF-15, SW-10) |
| Action | nested in `…Feature.swift` | `enum Action` (Equatable only if needed) |
| Service | `…Client.swift` (TCA-idiomatic) or `…Service.swift` | `@DependencyClient struct …Client: Sendable` (UZF-16, SW-15) |
| Operation | (no suffix) | property on the Client struct |
| Repository | `…Repository.swift` | `final class …Repository` (only when state across services is needed) (UZF-16) |
| Provider | `…Provider.swift` | `@DependencyClient struct …Provider` |
| Mapper | `…Mapper.swift` | `enum …Mapper { static func toDomain(...) }` (UZF-17, SW-16) |
| Domain model | `<Model>.swift` | `struct …` |
| Response | `…Response.swift` | `struct …Response: Codable, Equatable, Sendable` (UZF-8, UZF-17) |
| Exception | `…Exception.swift` | `enum …Exception: LocalizedError, Equatable, Sendable` (UZF-3, SW-11) |
| Endpoint | `…Endpoint.swift` | `enum …Endpoint` |

### Retired (v1) — do not use in new code (SW-1)

| Old | New |
| --- | --- |
| `…Page.swift` / `struct …Page: View` | `…Screen.swift` + `…View.swift` |
| `…FragmentView.swift` (the v1 double-suffix Fragment renderer) | `…View.swift` co-located with `…Fragment.swift` |
| `Mobile…View.swift` (one-off prefixed mobile splits) | `…View.swift` with previews exercising iPhone + iPad + macOS configs |

## Action cases (UZF-2)

| Prefix | Use for | Example |
| --- | --- | --- |
| `userDid…` | User intents (tap, swipe, type, drag) | `userDidTapEdit`, `userDidPullToRefresh`, `userDidSubmitForm(values: FormValues)` |
| `on…` | System / lifecycle signals | `onViewLoaded`, `onViewAppeared`, `onSceneBecameActive` |
| `on…Completed` | Effect resolution (success+failure unified via `Result`, UZF-3) | `onProfileFetchCompleted(Result<Profile, ProfileException>)` |
| `child…Delegated` *or* `destination(.presented(.child(.delegate(…))))` | Child feature talks back | `childAuthDelegatedSignOut`; with `Destination` use the presentation form |
| `destination` | Navigation actions when using `@Reducer enum Destination` | `case destination(PresentationAction<Destination.Action>)` (SW-7, SW-14) |
| `alert` | Alert/confirmation dialog actions | `case alert(PresentationAction<Alert>)` with a nested `Alert` enum |
| `binding` | If a field is exposed via `@Bindable` binding | `case binding(BindingAction<State>)` — declare `BindableAction` conformance (SW-13) |

**Never** name an action by its mechanism (`fetchProfile`, `loadData`) — name it by its intent or source (`userDidPullToRefresh`, `onProfileFetchCompleted`). (UZF-2.)

## Shifter functions (UZF-10, SW-8)

Direct mutation (`state.foo = bar`) is the default inside reducers. Shifters are extracted only when a mutation has an invariant, is reused across arms, or has logic worth unit-testing alone (see rule 05).

When you do extract one:

- **Reducer-facing form (the default): `mutating func apply…(…)`.** Mutates `self`, returns `Void`. Matches TCA's `inout state` reducer signature — zero allocations.
  - Prefix `apply…` for any mutation (additive, replacing, clearing). `applyProfileLoaded`, `applyException`, `applyExceptionCleared`.
  - Prefix `as…` is reserved for re-shape transforms that change identity/kind (`mutating func asEmptyState()`).
- **Optional test/preview form (`#if DEBUG` only): `func with…(…) -> Self`.** Returns a new `Self`; internally calls `apply…`. Used **only** for fluent test fixtures / preview state, never inside a reducer body.
  - Example: `State().withProfile(.mockTypical).withException(.offline)`.

This split matches `GENERAL_UZF_ARCHITECTURE.md` §4.2 (`apply…` for mutation-style, `with…` for value-returning), distilled as UZF-10.

## Selector properties (UZF-11, SW-9)

- Suffix every computed property meant to be **read by the View** with `…Selector`.
- Don't suffix internal helpers used only inside shifters; those are private.
- A boolean selector reads as a statement: `shouldShowEmptyStateSelector`, `isRefreshAllowedSelector`.

## Producer functions (UZF-15, SW-10)

- Always `static func produce<X>Effect(...) -> Effect<Action>`.
- The `produce` prefix is non-negotiable — it makes the call site grep-friendly.
- Arguments are the *inputs the effect needs* (ids, search text, dependencies). Never the whole `State`.

## View `init` signatures (v2)

`<Name>View.swift` initializers follow a uniform shape (SW-2):

1. **Inputs first** — plain values derived from selectors (Strings, Ints, arrays of domain models, Booleans).
2. **Closures last** — every user intent the View can fire, named `on…`.
3. **Closures default to a no-op** so previews don't need to spell every one out:
   ```swift
   public init(
       title: String,
       endeavors: [Endeavor],
       isLoading: Bool = false,
       exception: ProfileException? = nil,
       onTapEndeavor: @escaping (Endeavor.ID) -> Void = { _ in },
       onPullToRefresh: @escaping () -> Void = { }
   )
   ```
4. **No `Store`, no `Feature`, no `Action`.** If the View needs to know about an enum, redeclare a UZF-free equivalent inside the View file or accept the enum's domain type (when it's part of the model, not the action namespace).

## Test files and tests (UZF-20)

- `…FeatureTests.swift`, `…SelectorsTests.swift`, `…ShiftersTests.swift`, `…SnapshotTests.swift`.
- Each test function names a real-world scenario, not the code path:
  - ✅ `test_userDidPullToRefresh_whileOffline_surfacesOfflineException()`
  - ❌ `test_action_returnsCorrectState()`
