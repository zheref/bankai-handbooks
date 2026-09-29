<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# Repo-specific placeholders — `swiftui-tca-uzf-v2`

The rule files in this directory are **canon** (product-agnostic). Everything genuinely
repo-specific is a `{{TOKEN}}`. When the mirror generator (`nen canon mirror generate`) renders a
consumer repo's per-surface mirror (`CON-13`; history: Phase 0b of `<reference-repo>#34`), it substitutes
each token from that repo's **canon-values** binding. This file is the **schema**: the token, what it means, and an
illustrative example (a fictional product, "Acme"). It is NOT the value store — a repo binds values in its own config.

| Token | Meaning | Illustrative example |
|---|---|---|
| `{{PRODUCT_REPO}}` | `owner/repo` of the consuming product | `acme/acme-ios` |
| `{{PROJECT_NAME}}` | Product name | `Acme` |
| `{{GH_PROJECT}}` | The repo's active GitHub **Project** (board) — distinct from the product name | the repo's active Project |
| `{{MAINTAINER}}` | Human maintainer login (assignee) | `octocat` |
| `{{APP_TARGET_IOS}}` | iOS app target / module (`@testable import`) | `Acme` |
| `{{APP_TARGET_MACOS}}` | Native macOS app target | `Acme for Mac` |
| `{{PREVIEW_HOST_TARGET}}` | Isolated TCA-free preview target | `PreviewHost` |
| `{{CORE_FRAMEWORK}}` | Shared models/logic framework | `AcmeCore` |
| `{{UI_MODULE}}` | Design-system / UI module | `AcmeUI` |
| `{{TEST_TARGET}}` | Unit/snapshot test target/root | `AcmeTests` |
| `{{APP_SOURCE_ROOT}}` | App source root in CI-lint globs | `Acme/Application` |
| `{{XCODEPROJ}}` | Xcode project file | `Acme.xcodeproj` |
| `{{SCHEME}}` | Build/test scheme | `Acme` |
| `{{SNAPSHOT_DEVICE}}` | Snapshot reference simulator | `iPhone 17 Pro` |
| `{{SNAPSHOT_OS}}` | Snapshot reference OS | `26.5` |
| `{{SNAPSHOT_DEVICE_CONFIG}}` | Snapshot layout `ViewImageConfig` matching `{{SNAPSHOT_DEVICE}}` | `ViewImageConfig` for `{{SNAPSHOT_DEVICE}}` |
| `{{SNAPSHOT_TZ}}` | Timezone for date-bearing snapshots | `UTC` |
| `{{SNAPSHOT_PATH}}` | On-disk `__Snapshots__` layout | `{{TEST_TARGET}}/Application/<Name>/__Snapshots__/…` |
| `{{ASSETS_REPO}}` | Public snapshot-assets repo | `acme/acme-assets` |
| `{{ASSETS_LAYOUT}}` | Path layout inside the assets repo | `Acme/pr-<n>/<scene>.png` |
| `{{SCREENSHOTS_SCRIPT}}` | PR-screenshot mirror helper | `ci_scripts/pr_screenshots.sh` |
| `{{LINT_SCRIPT}}` | Architecture-lint script | `ci_scripts/lint_architecture.sh` |
| `{{LINT_WORKFLOW}}` | Lint CI workflow | `.github/workflows/lint.yml` |
| `{{CI_TEST_WORKFLOW}}` | Test CI workflow | `.github/workflows/tests.yml` |
| `{{BANKAI_WORKFLOW}}` | Bankai caller workflow | `.github/workflows/bankai.yml` |
| `{{DBMIGRATE_WORKFLOW}}` | Migration CI workflow | `.github/workflows/db-migrate.yml` |
| `{{BUILD_LOG}}` | Build-log path (watchdog) | build output log |
| `{{ARCH_DECISIONS_DIR}}` | Product-local arch-decisions mirror | `.claude/Architecture/` |
| `{{DOCS_ROOT}}` | Feature-docs root | `docs/Features` |
| `{{FLAG_ENUM}}` | Platform feature-flag registry | the app's flag enum |
| `{{COPILOT_REVIEWER}}` | Copilot reviewer login | `copilot-pull-request-reviewer[bot]` |
| `{{PRODUCT_ACCENT_TOKEN}}` | Design-system accent token (member name; used as `AppTheme.Colors.{{PRODUCT_ACCENT_TOKEN}}`) | `accent` |
| `{{EXTERNAL_STYLE_SDK}}` | Wrapped external styling SDK | (per repo) |

> A token that appears in a rule file MUST be listed here. Adding/renaming a token is a Naruto
> G4 change (keep the generator's substitution map in lockstep).
