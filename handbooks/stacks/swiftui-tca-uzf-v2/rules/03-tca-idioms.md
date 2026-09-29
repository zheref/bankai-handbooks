<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 03 — TCA Idioms (1.13+)

## Repo-specific placeholders

- `{{APP_SOURCE_ROOT}}` — app source dir that holds `Pages/` and `Fragments/` (illustrative: `Acme/Application`).
- `{{CORE_FRAMEWORK}}` — shared framework that vends domain models to Views (illustrative: `AcmeCore`).

Encodes the **v3 Screen/View split** (synthesis §3.3): the TCA-aware wrapper and
the TCA-free renderer are separate files. The `Page` suffix is retired (`SW-1`).

## The `@Reducer`

```swift
@Reducer
public struct UserProfileFeature {
    @ObservableState
    public struct State { /* … */ }

    public enum Action {            // Equatable only if a test needs it
        case userDidPullToRefresh
        case onViewLoaded
        case onProfileFetchCompleted(Result<Profile, ProfileException>)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    public enum Destination { case edit(EditProfileFeature) }

    @Dependency(\.profileClient) var profileClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            // pattern-match. Each branch returns either .none or
            // `Self.produce…Effect(...)`. NEVER inline .run.
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
```

**Hard rules in this snippet** (`SW-4`, `SW-6`; action naming per `UZF-2`)

- `@Reducer` on the type, `@ObservableState` on `State`, no `@MainActor` on the whole struct (`SW-4`).
- `@Dependency` declarations at the top, `body` last.
- `.ifLet` references `\.$destination` (PresentationState key path).

## The Screen (`SW-1`, `SW-3`)

```swift
// {{APP_SOURCE_ROOT}}/Pages/UserProfile/UserProfileScreen.swift
import ComposableArchitecture
import SwiftUI

@MainActor
struct UserProfileScreen: View {
    @Bindable var store: StoreOf<UserProfileFeature>

    var body: some View {
        UserProfileView(
            displayName: store.displayNameSelector,
            avatarURL: store.profile?.avatarURL,
            isLoading: store.isLoading,
            exception: store.exception,
            canEdit: store.canEditSelector,
            onPullToRefresh: { store.send(.userDidPullToRefresh) },
            onTapEdit: { store.send(.userDidTapEdit) }
        )
        .navigationTitle("Profile")
        .task { store.send(.onViewLoaded) }
        .sheet(item: $store.scope(state: \.destination?.edit, action: \.destination.edit)) { editStore in
            EditProfileFragment(store: editStore)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
```

**Hard rules in this snippet**

- The Screen does exactly four things: declares `@Bindable var store`, constructs `<Name>View(...)` from selectors and closures, applies **navigation** modifiers (`.navigationTitle`, `.sheet`, `.alert`, `.task`), and forwards delegate intents to children (`SW-3`).
- **No layout** (no `VStack`, no padding, no colors) lives in the Screen. If you find layout creeping in, move it to the View (`SW-3`).
- `@Bindable var store: StoreOf<…>` — never `@StateObject`, never `WithViewStore` (`SW-6`).
- `@MainActor` on the **Screen** only, not the Feature (`SW-4`).
- `.sheet(item:)` uses `$store.scope(...)`. Same for `.popover(item:)`, `.navigationDestination(item:)`, `.fullScreenCover(item:)` (`SW-14`).
- `.alert(...)` uses `$store.scope(...)` against an `AlertState`-backed `@Presents` (`SW-14`).

## The View (`SW-1`, `SW-2`)

```swift
// {{APP_SOURCE_ROOT}}/Pages/UserProfile/UserProfileView.swift
// NOTE: this file does NOT import ComposableArchitecture. It is PreviewHost-eligible.
import SwiftUI
import {{CORE_FRAMEWORK}}   // only because Profile/Endeavor models live here

struct UserProfileView: View {
    let displayName: String
    let avatarURL: URL?
    let isLoading: Bool
    let exception: ProfileException?
    let canEdit: Bool
    var onPullToRefresh: () -> Void = { }
    var onTapEdit: () -> Void = { }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            AvatarView(url: avatarURL)
            Text(displayName).font(AppTheme.Typography.title)
            if isLoading {
                ProgressView()
            } else if let exception {
                ExceptionBanner(message: exception.errorDescription ?? "Something went wrong")
            }
            if canEdit {
                Button("Edit", action: onTapEdit).buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .refreshable { onPullToRefresh() }
    }
}

#Preview("loaded · typical") {
    UserProfileView(
        displayName: "Ada Lovelace",
        avatarURL: nil,
        isLoading: false,
        exception: nil,
        canEdit: true
    )
}

#Preview("loading") {
    UserProfileView(
        displayName: "—",
        avatarURL: nil,
        isLoading: true,
        exception: nil,
        canEdit: false
    )
}

#Preview("offline exception") {
    UserProfileView(
        displayName: "Ada Lovelace",
        avatarURL: nil,
        isLoading: false,
        exception: .offline,
        canEdit: false
    )
}
```

**Hard rules in this snippet** (`SW-2` implements `UZF-4`)

- No `import ComposableArchitecture`. No `Store`, no `StoreOf`, no `Action`. CI lint: `grep -rl 'ComposableArchitecture' {{APP_SOURCE_ROOT}}/**/*View.swift` must be empty (`SW-2`).
- All inputs are plain values; all intents are `@escaping` closures with no-op defaults.
- Three `#Preview` blocks minimum: typical, loading, exception (or empty). They must mirror the snapshot tests 1:1 (`SW-17`, `UZF-18`, `UZF-26`).
- Layout, theming, accessibility all live here (`SW-3`).

## Navigation (`SW-7`)

| Need | Pattern |
| --- | --- |
| One child screen | `@Presents var child: ChildFeature.State?` + `.ifLet(\.$child, action: \.child)` |
| Two or more child screens | `@Reducer enum Destination { case a(AFeature); case b(BFeature) }` + `@Presents var destination: Destination.State?` |
| A stack | `@Reducer enum Path { … }` + `var path = StackState<Path.State>()` + `.forEach(\.path, action: \.path)` |
| Alerts / confirmation dialogs | `@Presents var alert: AlertState<Action.Alert>?` + `.ifLet(\.$alert, action: \.alert)` |

Plain optional child state (no `@Presents`) is forbidden — it breaks effect cancellation (`SW-7`).

## Bindings (`SW-13`)

If the view binds to fields (text fields, toggles), declare `BindableAction`:

```swift
public enum Action: BindableAction {
    case binding(BindingAction<State>)
    // … other cases
}

public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in /* … */ }
}
```

Then in the view: `TextField("Email", text: $store.email)` (the `$` syntax works because `@Bindable` exposes bindings to `@ObservableState` properties). Hand-written "set field" actions alongside `binding` are forbidden (`SW-13`).

## Effect rules (`SW-10`; cross-reference 06-producers-effects.md)

A reducer body has exactly three return shapes:

1. `return .none`
2. `return Self.produce…Effect(…)`
3. `return .merge(Self.produceA…(), Self.produceB…())` — **only** if you have two independent effects already produced. Don't `.merge` raw `.run` (`SW-10`).

## Equatable on `Action`

TCA 1.13+ does **not** require `Action: Equatable` for `TestStore`. Add `Equatable` only when:

- A payload is `Equatable` and a test does `store.receive(.foo(payload))` with full equality check.
- Or another reducer composes via `.scope` and the parent's action equality is needed.

In all other cases, omit it.

## `@Dependency` placement (`SW-15`)

Always at the top of the `Feature` struct, before `body`. Group by source if many:

```swift
// Services
@Dependency(\.profileClient) var profileClient
@Dependency(\.authClient) var authClient
// System
@Dependency(\.date.now) var now
@Dependency(\.continuousClock) var clock
@Dependency(\.uuid) var uuid
```

Prefer the granular forms (`\.date.now`, `\.uuid`) over capturing the whole `Date()` or `UUID()` — they make tests deterministic (`SW-15`).
