<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# UZF Rules — Overview

## Repo-specific placeholders

- `{{APP_TARGET_IOS}}` — the iOS app target name. Illustrative example: `Acme`.
- `{{APP_TARGET_MACOS}}` — the native macOS app target name (Catalyst-free). Illustrative example: `Acme for Mac`.
- `{{PREVIEW_HOST_TARGET}}` — the isolated preview app target that compiles TCA-free `…View.swift` files. Illustrative example: `PreviewHost`.
- `{{CORE_FRAMEWORK}}` — the shared framework vending domain models/business logic. Illustrative example: `AcmeCore`.
- `{{TEST_TARGET}}` — the unit/snapshot test target (and its root folder). Illustrative example: `AcmeTests`.
- `{{PRODUCT_REPO}}` — the consuming product repo whose codebase these rules govern. Illustrative example: `acme/acme-ios`.
- `{{ARCH_DECISIONS_DIR}}` — the product repo's local architecture-decisions folder (the generated mirror of this canon). Illustrative example: `.claude/Architecture/`.

---

This `rules/` folder is the operational reference for a SwiftUI + TCA 1.13+ / Swift 6 project under **UZF v2 — Screen/View split**. It is intentionally **split into short files** so each can be loaded individually by Claude Code without burning context.

> **Current architecture: UZF v2 (Screen/View split).** Every feature with UI splits into a TCA-aware wrapper (`<Name>Screen.swift` or `<Name>Fragment.swift`) and a TCA-free renderer (`<Name>View.swift`). The View joins `{{PREVIEW_HOST_TARGET}}`; the wrapper does not. `<Name>Page.swift` is **retired** (SW-1). (Implements UZF-4.)

| File | When to consult |
| --- | --- |
| [00-overview.md](00-overview.md) | Always (first). High-level rules, decision flow, file map. |
| [01-folder-layout.md](01-folder-layout.md) | Creating a new feature, new module, or new top-level folder. |
| [02-naming.md](02-naming.md) | Naming an action, file, type, or instance. |
| [03-tca-idioms.md](03-tca-idioms.md) | Writing or reviewing a `@Reducer`, View, navigation, or alert. |
| [04-services-dependencies.md](04-services-dependencies.md) | Adding a service, repository, or `@Dependency`. |
| [05-state-shifters-selectors.md](05-state-shifters-selectors.md) | Mutating state, adding a derived value, or refactoring a fat reducer. |
| [06-producers-effects.md](06-producers-effects.md) | Anything involving `Effect`, `.run`, async work, or persistence. |
| [07-testing.md](07-testing.md) | Writing tests, snapshot tests, or `TestStore` cases. |
| [08-anti-patterns.md](08-anti-patterns.md) | Reviewing code or refusing a code suggestion. |
| [09-design-system.md](09-design-system.md) | Touching theme, palette, typography, or reusable UI under `Design/`. |
| [10-migration.md](10-migration.md) | Touching a legacy / non-UZF screen, or migrating a v1 Page to the Screen/View split. |
| [11-feature-documentation.md](11-feature-documentation.md) | Adding or changing a feature; defines `docs/Features/<FeatureName>.md` (flat, mermaid inline). Language-agnostic (UZF-21). |
| [12-session-completion-checklist.md](12-session-completion-checklist.md) | Closing a session. Coverage, diagrams, spec, feature-flag wrapping (UZF-23). Refuse "done" with open items. |
| [13-build-execution.md](13-build-execution.md) | Running `xcodebuild` from this repo. Hung-clang detection, the compile-time budget, the `pkill -9 clang` recovery procedure. |
| [14-github-version-control.md](14-github-version-control.md) | Creating or updating an issue or PR. Native relationships/sub-issues, PR↔issue closing-keyword links, Project association, labels, assignee. |
| [15-database-migrations.md](15-database-migrations.md) | Changing the Supabase DB (tables, columns, RLS policies, views, functions, grants, seed). Repo migrations are canon; live DB is kept in sync (UZF-25). |
| [16-ui-screenshots.md](16-ui-screenshots.md) | Opening/updating a UI PR. Embedding the mandatory snapshot images (the recorded PNGs) in the PR description, one per state — enforced via UZF-26 / SW-18. |

## The 10-second rule

Before writing or reviewing any Swift file, ask:

1. **What layer is this?** UI-wrapper (Screen/Fragment) / UI-renderer (View/Component) / State+Logic / Data. The file's location, allowed imports, and target membership all follow from the answer (UZF-4, UZF-7).
2. **What artifact is this?** Screen, Fragment, View, Component, Adapter, Interactor (`Feature`), Selector, Shifter, Producer, Service, Repository, Mapper, Model, Exception, Response. Suffix the file accordingly (02-naming.md).
3. **Is it active or passive?** Active artifacts decide (Reducer, Repository, Screen/Fragment via store). Passive artifacts react or transform (View, Selector, Mapper, Service operation). (UZF-7.)

If you cannot answer all three in ten seconds, stop and read the relevant rule file.

## Hard "never"s — memorize these

1. **Never inline `.run { … }`, `.send`, `.cancel`, `.merge`, `.concatenate`** in a reducer body. Call a Producer. (UZF-12, SW-10.)
2. **Never** put a service call (`URLSession`, `UserDefaults`, file I/O, `Calendar.current`, `Date()` in a non-trivial branch) inside a reducer. (UZF-13.)
3. **Never** use `WithViewStore`, `viewStore`, `EnvironmentObject`, `@StateObject` or `@Observable` for feature state. Always `@Reducer` + `@Bindable var store` (in Screens/Fragments only). (SW-6.)
4. **Never** put wire-format types (`…Response`, raw JSON dicts) into `State`. Map first. (UZF-8, SW-16.)
5. **Never** throw out of an `Effect`. Always `Result<Success, …Exception>` and a single `on…Completed` action. (UZF-14, SW-11.)
6. **Never** declare a `Feature` `@MainActor`. Only the Screen/Fragment/View boundary is `@MainActor`. (SW-4.)
7. **Never** present a child screen via plain optional state. Use `@Presents` + `Destination` reducer. (SW-7.)
8. **Never** ship `fatalError` inside a `liveValue` closure. (SW-15.)
9. **Never** `import ComposableArchitecture` from a `<Name>View.swift`. Views are TCA-free. (UZF-4, SW-2.)
10. **Never** create a new `<Name>Page.swift`. The `Page` suffix is retired; use `<Name>Screen.swift` + `<Name>View.swift`. (SW-1.)
11. **Never** add a `<Name>Screen.swift` or `<Name>Fragment.swift` to the `{{PREVIEW_HOST_TARGET}}` target. Only the corresponding `<Name>View.swift` joins it. (SW-2.)
12. **Never** put layout code in a Screen. The Screen wires store + navigation only; layout belongs in the View. (SW-3.)
13. **Never** change architecture rules (suffixes, layering, artifact responsibilities) locally, and **never hand-edit the generated `.claude/rules/` mirror**. This handbook in `bankai-handbooks` is the canonical source (CON-13); propose changes as a PR there (G4 — the human merges) and let the mirror generator regenerate every surface's mirror.
14. **Never** mark a session done with the [completion checklist](12-session-completion-checklist.md) open: touched-file coverage < 80%, missing mermaid diagram, missing feature spec, or new user-visible behavior unwrapped by a feature flag. (UZF-23.)
15. **Never** describe a feature in `docs/Features/` using file paths, type names, or platform-specific terms — those docs are language-agnostic per [Rule 11](11-feature-documentation.md). (UZF-21.)
16. **Never** change DB structure (schema, RLS policy, view, function, grant, seed) without an idempotent migration file in the repo — the repo is canon and the live DB never drifts ([Rule 15](15-database-migrations.md), UZF-25).
17. **Never** open or update a PR that adds/changes a TCA-free `<Name>View` renderer (structurally: no `ComposableArchitecture` import, wherever it lives) or a reusable component without embedding the mandatory snapshot screenshots in the description — the recorded PNGs themselves, one per state ([Rule 16](16-ui-screenshots.md); enforced via UZF-26 / SW-18). Logic-only PRs are exempt with a noted reason.

## File generation prompt template

When the user asks for a new Screen-level feature, generate **all seven** files in one go:

```
App/Pages/<Name>/
  <Name>Screen.swift            # UZF wrapper. @Bindable var store. Hosts navigation. Targets: {{APP_TARGET_IOS}}, {{APP_TARGET_MACOS}}.
  <Name>View.swift              # Pure SwiftUI. Plain values + closures. ≥3 #Preview. Targets: {{APP_TARGET_IOS}}, {{APP_TARGET_MACOS}}, {{PREVIEW_HOST_TARGET}}.
  <Name>Feature.swift
  <Name>Selectors.swift
  <Name>Shifters.swift
  <Name>Producer.swift
  <Name>Adapters.swift          # only if the View has a list
{{TEST_TARGET}}/Application/<Name>/
  <Name>FeatureTests.swift
  <Name>SelectorsTests.swift
  <Name>ShiftersTests.swift
  <Name>SnapshotTests.swift     # constructs <Name>View directly, mirrors the #Previews 1:1
```

For a Fragment-level feature, swap `Screen → Fragment` and place under `App/Fragments/<Name>/`. The `<Name>View.swift` naming is identical (no `FragmentView` double-suffix in v2).

After file creation, verify in `project.pbxproj` that:
- `<Name>Screen.swift` / `<Name>Fragment.swift` are in **`{{APP_TARGET_IOS}}`** and **`{{APP_TARGET_MACOS}}`** target memberships only.
- `<Name>View.swift` is in **`{{APP_TARGET_IOS}}`**, **`{{APP_TARGET_MACOS}}`**, and **`{{PREVIEW_HOST_TARGET}}`** target memberships.

Plus add ≥ 7 mocks to `<Model>+Mocks.swift` if a new domain model was introduced (UZF-18).

## Where this came from

These rules synthesize:
- `GENERAL_UZF_ARCHITECTURE.md` — the canonical multi-tech spec (distilled into this canon's `uzf-core.md`, `UZF-{n}`).
- The Swift-specific corrected ruleset for SwiftUI + TCA (distilled into this stack's `architecture.md`, `SW-{n}`).
- TCA 1.13+ official guidance (Observation, `@DependencyClient`, `@Presents`, `@Reducer enum Destination`, `AlertState`).
- Findings from auditing a real SwiftUI + TCA codebase (`{{PRODUCT_REPO}}`): inline effects, missing Selectors/Shifters/Producer files, `@Observable` fragment models, optional child state without `@Presents`, `previewValue` reused as `testValue`, and (driving the Screen/View split) Pages that pulled `ComposableArchitecture` into every `#Preview`, making the `{{PREVIEW_HOST_TARGET}}` target non-viable while forcing `{{CORE_FRAMEWORK}}` and services into preview builds.

The **project-specific evolution** (v1 Page → v2 Screen/View split) is mirrored in the product repo under `{{ARCH_DECISIONS_DIR}}`; the canonical rules are this handbook in `bankai-handbooks` (CON-13).
