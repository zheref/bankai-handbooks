<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 10 — Migration (legacy → UZF, and v1 → v2)

Implements **UZF-24** (migration by encapsulation, edge-conversion) for the
SwiftUI/TCA stack. Two migration tracks run in a UZF repo:

1. **Legacy non-UZF code → UZF** (phases 0–5 below).
2. **UZF v1 (Page-only) → UZF v2 (Screen/View split)** — the same edge-conversion
   strategy applied to UZF's internal versioning. See the stack `architecture.md`
   (`SW-1`/`SW-2`) and the v3 synthesis Screen/View split.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{APP_TARGET_IOS}}` | `Acme` |
| `{{APP_TARGET_MACOS}}` | `Acme for Mac` |
| `{{PREVIEW_HOST_TARGET}}` | `PreviewHost` |
| `{{APP_SOURCE_ROOT}}` | `Acme/Application` |
| `{{TEST_TARGET}}` | `AcmeTests` |
| `{{XCODEPROJ}}` | `Acme.xcodeproj` |
| `{{LINT_SCRIPT}}` | `ci_scripts/lint_architecture.sh` |
| `{{LINT_WORKFLOW}}` | `.github/workflows/lint.yml` |

## Principle (UZF-24)

**Don't rewrite — encapsulate, then convert by edge.** A legacy screen stays legacy
until a PR touches it. When a PR touches it, convert *only* the artifacts it touches.

For v1→v2 specifically: when a PR touches a `<Name>Page.swift`, rename it to
`<Name>Screen.swift` and extract the body into `<Name>View.swift` *in the same PR*.
Do not leave a half-converted Page lying around. (The `Page` suffix is retired —
`SW`/architecture anti-patterns; a new `*Page.swift` auto-rejects.)

## Phase 0 — Scaffolding (do once per repo)

- Add `swift-composable-architecture` SPM dep.
- Create the UZF layer folders if not present: `Application/`, `Services/`,
  `Models/`, `Design/`, `Library/`, and the test target root. (Folder-name casing
  and the exact set are the repo's — see `01-folder-layout`. The reference product uses
  PascalCase `Application/…`; other repos may use lowercase `app/…`, `tests/…`.)
- Add `swift-snapshot-testing` SPM dep.
- Establish `AppTheme` (or wrap the existing palette).

## Phase 1 — Wrap legacy services (UZF-16)

For every legacy network/persistence object:

1. Define a `@DependencyClient struct …Client`.
2. Implement `liveValue` by delegating to the legacy object.
3. Define `previewValue` (deterministic).
4. Register on `DependencyValues`.

Reducers from this point only see the UZF surface. The legacy object is one file
away from deletion.

## Phase 2 — One feature, full UZF

Pick a low-traffic, high-bug-density screen. Build it 100% UZF (Screen + View,
Feature, Selectors, Shifters, Producer, mocks, ≥ 3 previews, ≥ 3 snapshot tests,
≥ 3 tests per action — the UZF-18 minimums). Route to it.

This screen becomes the team's reference. Document it in `docs/uzf-reference.md`.

## Phase 3 — Edge conversion

When a PR touches a legacy screen *for any reason*:

| Touch | Convert |
| --- | --- |
| Adding a new user intent | Create a `Feature` (or extend the existing one), add a new `Action` case, route the legacy view's button to send the case through a thin bridge. |
| Adding new state | Replace the legacy `@Published var foo` with `@ObservableState`. Bridge via a one-way adapter (legacy reads from the store). |
| Adding a new effect | Write a Producer. Have the legacy screen `await store.send(.userDid…)` to trigger it. |
| Pure visual change | No conversion required. |

Document the seam in the PR description: "Legacy ↔ UZF seam: <what bridges where>".

## Phase 4 — Retire legacy

A legacy screen is retired when:

1. Every user event has a `userDid…` case.
2. Every piece of legacy state has a UZF equivalent.
3. UZF snapshot tests match the legacy screen's pixel output (use
   `swift-snapshot-testing` with the legacy screen as the baseline once).
4. The legacy view-controller / view-model files are deleted in the same PR.
5. The feature flag (if any) is removed in the same PR.

## Phase 5 — Stabilize

After ≥ 5 screens converted:

- Audit `Library/` for repeated `Feature` patterns to extract (e.g. a generic
  `Paginated<Item>Feature`).
- Turn on CI lints (see below).

## CI lints (ENFORCED)

Guardrails run on every push/PR via a **Lint** workflow (`{{LINT_WORKFLOW}}` →
`{{LINT_SCRIPT}}`). The script is pure grep/find/bash, runs on the repo's test
runner (self-hosted where GitHub-hosted minutes are unavailable), ignores full-line
`//` comments, and honors a deliberate, reasoned allow-list. The four enforced gates,
as first wired on the reference product:

1. **No filter side-channels:** `@Shared` / `UserDefaults` in `{{APP_SOURCE_ROOT}}/`
   → fail. Allow-listed (non-filter, deliberate): a small, named set of pre-existing
   `@Shared` anchors carried as tech debt — migrate each behind a Client later.
2. **Views are TCA-free (SW-2):** `import ComposableArchitecture` in any
   `*View.swift` → fail.
3. **No inline effects (UZF-12 / SW-10):** `.run { … }` in a `{{APP_SOURCE_ROOT}}/`
   reducer → fail (excludes `MainActor.run` and `*Producer.swift`, where effects
   belong).
4. **No retired Pages:** any `*Page.swift` under `{{APP_SOURCE_ROOT}}` → fail.

To add a legitimate exception, edit the allow-list in `{{LINT_SCRIPT}}` **with a
reason** — never silently. The PR template restates these gates.

Still recommended (not all yet wired):

- `grep -r 'WithViewStore\|viewStore' {{APP_TARGET_IOS}}/` → fail.
- `grep -r 'URLSession\|UserDefaults' {{APP_SOURCE_ROOT}}/` → fail (only allowed
  under `Services/`).
- `@MainActor` outside a View/Screen/Fragment → fail (SW-4).
- `swift-format` with a UZF-specific style file.

## Bridge patterns

### Legacy `UIViewController` → UZF Screen

```swift
// Wrap the legacy VC in a SwiftUI Screen that forwards intent.
struct LegacyProfileScreen: View {
    @Bindable var store: StoreOf<UserProfileFeature>
    var body: some View {
        LegacyProfileVCRepresentable(onEdit: { store.send(.userDidTapEdit) })
            .task { store.send(.onViewLoaded) }
    }
}
```

The VC is a `UIViewControllerRepresentable`. The Feature owns state and effects.
The VC owns nothing but UI. (When the legacy VC is eventually replaced with native
SwiftUI, the new rendering lands in `LegacyProfileView.swift` and the Screen
reduces to `LegacyProfileView(...)` + navigation — SW-1.)

### Legacy MVVM → UZF Feature

```swift
// Step 1: Move the VM's published state into State.
// Step 2: Move the VM's methods into Action cases.
// Step 3: Move the VM's service calls into Producer.
// Step 4: Extract the SwiftUI rendering into `<Name>View.swift`. Screen reduces to a thin wrapper.
// Step 5: Delete the VM file.
```

Stop at Step 4 if the VM is too large; ship Steps 1–4 as a single PR and Step 5 as
a follow-up.

### v1 Page → v2 Screen + View

```swift
// Before:
struct UserProfilePage: View {
    @Bindable var store: StoreOf<UserProfileFeature>
    var body: some View {
        VStack { /* layout */ Text(store.displayNameSelector) /* … */ }
            .task { store.send(.onViewLoaded) }
    }
}

// After (UserProfileScreen.swift — {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} only):
struct UserProfileScreen: View {
    @Bindable var store: StoreOf<UserProfileFeature>
    var body: some View {
        UserProfileView(
            displayName: store.displayNameSelector,
            /* …plain values… */
            onTapEdit: { store.send(.userDidTapEdit) }
        )
        .task { store.send(.onViewLoaded) }
        .sheet(/*…*/)
    }
}

// New file (UserProfileView.swift — {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} + {{PREVIEW_HOST_TARGET}}):
struct UserProfileView: View {
    let displayName: String
    var onTapEdit: () -> Void = { }
    var body: some View { VStack { /* layout */ Text(displayName) /* … */ } }
}

#Preview("typical") { UserProfileView(displayName: "Ada") }
#Preview("long name") { UserProfileView(displayName: String(repeating: "Ada ", count: 20)) }
#Preview("empty") { UserProfileView(displayName: "") }
```

Steps (PR-sized chunks):

1. Create `<Name>View.swift` next to the Page. Define `init` from the plain values
   the Page reads off `store`.
2. Move the Page's `body` content (sans `store.send(...)` calls) into the View.
   Replace each `store.send(.foo)` with a closure invocation (`onFoo()`).
3. Rename `<Name>Page.swift` → `<Name>Screen.swift`. The Screen's `body` now just
   calls `<Name>View(…)` and applies `.task`, `.sheet`, `.alert` modifiers.
4. In `{{XCODEPROJ}}`: add `<Name>View.swift` to `{{PREVIEW_HOST_TARGET}}`
   target membership; keep `<Name>Screen.swift` on `{{APP_TARGET_IOS}}` +
   `{{APP_TARGET_MACOS}}` only.
5. Add ≥ 3 `#Preview` blocks to the View and ≥ 3 matching snapshot tests under
   `{{TEST_TARGET}}/`.
6. Update every call site of `<Name>Page` → `<Name>Screen` (sidebar, navigation,
   sheet).
7. Run the build for all three targets; run the test suite.

## Conversion budget

One screen per branch. Two if they share a Feature. Never three.
