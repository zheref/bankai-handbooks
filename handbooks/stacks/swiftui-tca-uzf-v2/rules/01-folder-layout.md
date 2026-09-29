<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 01 — Folder Layout

## Repo-specific placeholders

- `{{APP_TARGET_IOS}}` — the iOS app target name. Illustrative example: `Acme`.
- `{{APP_TARGET_MACOS}}` — the native macOS app target name (Catalyst-free). Illustrative example: `Acme for Mac`.
- `{{PREVIEW_HOST_TARGET}}` — the isolated preview app target that compiles TCA-free `…View.swift` files. Illustrative example: `PreviewHost`.
- `{{CORE_FRAMEWORK}}` — the shared framework vending domain models/business logic. Illustrative example: `AcmeCore`.
- `{{APP_SOURCE_ROOT}}` — the app's source root folder used in CI lint globs. Illustrative example: `Acme/Application`.
- `{{TEST_TARGET}}` — the unit/snapshot test target (and its root folder). Illustrative example: `AcmeTests`.

---

```
<target-root>/
  App/
    Theme/                       # AppTheme.swift, palette enums, typography
    Pages/                       # Full-screen features
      <Name>/
        <Name>Screen.swift       # UZF wrapper (TCA-aware). {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} targets.
        <Name>View.swift         # Pure SwiftUI (TCA-free). {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} + {{PREVIEW_HOST_TARGET}}.
        <Name>Feature.swift
        <Name>Selectors.swift
        <Name>Shifters.swift
        <Name>Producer.swift
        <Name>Adapters.swift     # only when the View renders a list
    Fragments/                   # Reusable domain-specific features (NO Producer)
      <Name>/
        <Name>Fragment.swift     # UZF wrapper (TCA-aware). {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} targets.
        <Name>View.swift         # Pure SwiftUI (TCA-free). {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} + {{PREVIEW_HOST_TARGET}}.
        <Name>Feature.swift      # only if the fragment has its own state
        <Name>Selectors.swift
        <Name>Shifters.swift
    Adapters/                    # Cross-feature reusable adapters
  Design/                        # Domain-LESS reusable UI (plain SwiftUI, NO TCA, no domain types) (UZF-5, SW-5)
  Services/
    Network/
    System/
    Sensors/
    SDK/
    Compute/
  Models/                        # Domain models, mappers, exceptions, responses
  Utility/                       # Helpers, extensions
  Library/                       # UZF abstractions not provided by TCA
<test-target>/                   # e.g. {{TEST_TARGET}}
  # Mirrors the structure above. Snapshot tests construct <Name>View directly, no Store required.
```

## Target membership (project.pbxproj)

| File kind | {{APP_TARGET_IOS}} (iOS) | {{APP_TARGET_MACOS}} | {{PREVIEW_HOST_TARGET}} |
| --- | :---: | :---: | :---: |
| `<Name>Screen.swift` / `<Name>Fragment.swift` | ✅ | ✅ | ❌ |
| `<Name>View.swift` | ✅ | ✅ | ✅ |
| `<Name>Feature.swift`, `<Name>Selectors.swift`, `<Name>Shifters.swift`, `<Name>Producer.swift`, `<Name>Adapters.swift` | ✅ | ✅ | ❌ |
| `Design/*` (Components) | ✅ | ✅ | ✅ |
| `Models/*` | (via `{{CORE_FRAMEWORK}}`) | (via `{{CORE_FRAMEWORK}}`) | (via `{{CORE_FRAMEWORK}}` if needed) |
| `Services/*` | ✅ | ✅ | ❌ |

`{{PREVIEW_HOST_TARGET}}` exists so a designer or developer can render any `<Name>View` in isolation without compiling `ComposableArchitecture`, `{{CORE_FRAMEWORK}}` business logic, or service implementations. If `<Name>View.swift` fails to compile under `{{PREVIEW_HOST_TARGET}}` alone, it has accidentally taken on a TCA or domain-service dependency — fix it before merging. (SW-2.)

## Layering rules (enforced in review — implements UZF-4, UZF-5, UZF-6)

| File | May import | May NOT import |
| --- | --- | --- |
| `<Name>Screen.swift` / `<Name>Fragment.swift` | `ComposableArchitecture`, the co-located `<Name>View`, other `App/Fragments/*Fragment`, `App/Adapters`, `Design`, `Models`, `Library` | `Services/*` directly, sibling Screens |
| `<Name>View.swift` | `Design`, `Models`, `Library`, Apple frameworks | **`ComposableArchitecture`**, `App/Pages/<Other>/<Other>Screen`, `Services/*` |
| `App/Adapters` | `Design`, `Models` | `Services/*`, `App/Pages` |
| `Design` | `Models` (only if necessary), Apple frameworks | `ComposableArchitecture`, `App/*`, `Services/*` |
| `Services` | `Models`, `Library`, Apple/3rd-party SDKs | `App/*` |
| `Models` | `Library`, Apple frameworks | everything else |
| `Utility`, `Library` | nothing app-specific | `App/*`, `Services/*` |

**The hardest line: `<Name>View.swift` may not import `ComposableArchitecture` (SW-2).** This is the rule that makes the `{{PREVIEW_HOST_TARGET}}` target work. CI lint: `grep -rl 'ComposableArchitecture' {{APP_SOURCE_ROOT}}/**/*View.swift` must return nothing.

## Co-location rule (UZF-6)

A `<Name>Feature`, its `<Name>Screen` (or `<Name>Fragment`), and its `<Name>View` all live **in the same folder**, even though formally each is a different layer (state / UZF-wrapper / pure render). This is a deliberate UZF override: cognitive locality beats layering purity.

`<Name>Producer.swift` and `<Name>Shifters.swift` also live next to the Feature, because they extend it.

The only reason to extract a piece into a *different* folder is reuse across two or more features — and even then, prefer `Design/` (if domain-less) or `App/Fragments/` (if domain-bound) over `App/Pages/<Name>/Subviews/`.

## Naming the folder

The folder name is the feature name *without* any suffix:
- ✅ `App/Pages/UserProfile/`
- ❌ `App/Pages/UserProfilePage/` (suffix is for files, not folders)
- ❌ `App/Pages/userProfile/` (PascalCase always for feature folders)

## When a feature outgrows one folder

If a feature has > 5 sub-views, sub-fragments, or sub-features, split into a nested layout:

```
App/Pages/UserProfile/
  UserProfileScreen.swift
  UserProfileView.swift          # ≥3 #Preview; {{PREVIEW_HOST_TARGET}} target
  UserProfileFeature.swift
  UserProfileSelectors.swift
  UserProfileShifters.swift
  UserProfileProducer.swift
  Subviews/
    HeaderView.swift             # plain SwiftUI, takes data + closures, {{PREVIEW_HOST_TARGET}}-eligible
    StatsView.swift
  Children/
    EditProfile/                 # full UZF folder for the child Feature
      EditProfileFragment.swift
      EditProfileView.swift
      EditProfileFeature.swift
      …
```

Children that have their own `@Reducer` get their own folder *with the full Screen/View or Fragment/View pair*; pure subviews are flat in `Subviews/` and are also TCA-free (`{{PREVIEW_HOST_TARGET}}`-eligible).

## What goes in `Library/`

Only abstractions that UZF needs but TCA/SwiftUI don't provide out of the box. Today that's typically:
- A `TaskHandle` wrapper if you need cancellable, progress-bearing tasks.
- A canonical `…Exception` base if multiple features share one.
- Test helpers (`StateTester`, `TestStore` extensions).

Resist the urge to put generic utilities here. Those go in `Utility/`.
