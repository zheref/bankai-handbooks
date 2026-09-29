<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# Repo-specific placeholders — `compose-uzf-v2`

The rule files in this directory are **canon** (product-agnostic). Everything genuinely
repo-specific is a `{{TOKEN}}`. When the mirror generator (`nen canon mirror generate`) renders a
consumer repo's per-surface mirror (`CON-13`; history: Phase 0b of `<reference-repo>#34`), it substitutes
each token from that repo's **canon-values** binding. This file is the **schema**: the token, what it means, an illustrative
example (a fictional product, "Acme"), and whether it is **shared** with the `swiftui-tca-uzf-v2` schema or **compose**-specific.
It is NOT the value store — a repo binds values in its own config.

Tokens marked **shared** carry the identical meaning (and reuse the exact token name) as the
SwiftUI schema, so a repo on both stacks binds them once. Tokens marked **compose** have no SwiftUI
equivalent (Kotlin package paths, an in-repo UZF runtime folder, a swappable DI framework, the
Android dual test roots, the Compose theme package) and exist only here.

| Token | Meaning | Illustrative example | Schema |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Product name — the `…Application` class, the Room `…Database`, the forbidden brand type-prefix | `Acme` | shared |
| `{{CORE_FRAMEWORK}}` | Shared pure-domain module (models/logic; owns the flag registry) | `AcmeCore` | shared |
| `{{APP_PACKAGE}}` | Kotlin reverse-DNS package root (file-path anchors, `MainDispatcherRule` path) | `com.acme.app` | compose |
| `{{UZF_RUNTIME_ROOT}}` | The common module root holding the UZF runtime (`{{UZF_RUNTIME_ROOT}}/uzf`) and cross-feature DI (`{{UZF_RUNTIME_ROOT}}/di`) | `library` | compose |
| `{{APP_SOURCE_ROOT}}` | App source root in lint globs / file-path comments | `app/src/main/java` | shared |
| `{{UI_MODULE}}` | Design-system / UI module | `app` | shared |
| `{{THEME_ROOT}}` | Compose theme package (`AppTheme` / design tokens) | `ui/theme` | compose |
| `{{DI_FRAMEWORK}}` | DI framework name (swappable per repo; `Hilt` is the default) | `Hilt` | compose |
| `{{TEST_TARGET}}` | JVM unit-test source root | `app/src/test/java` | shared |
| `{{ANDROID_TEST_ROOT}}` | Instrumented (`androidTest`) source root | `app/src/androidTest/java` | compose |
| `{{SNAPSHOT_DEVICE}}` | Paparazzi reference `DeviceConfig` | `PIXEL_5` | shared |
| `{{LINT_SCRIPT}}` | Repo's architecture/quality **verification command** — a lint script or a Gradle/test task that runs the arch gate (Konsist/Detekt) and, where they share a task, the unit suite | `./gradlew :app:testDebugUnitTest` | shared |
| `{{CI_TEST_WORKFLOW}}` | Test CI workflow | `.github/workflows/build-test.yml` | shared |
| `{{DOCS_ROOT}}` | Feature-docs root | `docs/Features` | shared |
| `{{FLAG_ENUM}}` | Platform feature-flag registry | the app's `FeatureFlags` registry | shared |

> A token that appears in a rule file MUST be listed here. Adding/renaming a token is a Naruto
> G4 change (keep the generator's substitution map in lockstep).

## Token reconciliation notes

- **Three runtime-root tokens collapsed to one.** The reconcilers independently minted separate
  tokens for the same underlying root — the in-repo `library/` module holding both the UZF runtime
  (`library/uzf/`, the `Feature` base and UZF primitives) and the cross-feature DI root
  (`library/di/`). They are unified here as **`{{UZF_RUNTIME_ROOT}}`**, bound to the common root
  (`library`) so both subfolders resolve via `{{UZF_RUNTIME_ROOT}}/uzf` and `{{UZF_RUNTIME_ROOT}}/di`.
  A product that keeps the runtime and DI folders under a different shared parent binds this token
  to that parent instead.
- **`{{DI_FRAMEWORK}}` retained (contested).** Files 06/09/13 tokenized Hilt; files 00/02/05/08/10/11
  kept `Hilt` literal as a stack constant (the way SwiftUI keeps `ComposableArchitecture`/TCA
  literal). Ruling: the **concrete API symbols** (`@HiltViewModel`, `hiltViewModel()`, `@Inject`,
  `@Binds`, `@HiltAndroidApp`) stay **literal**, but the **framework name in prose** is
  `{{DI_FRAMEWORK}}` (default `Hilt`) because a product could swap in Koin/Dagger. Open item: a
  normalization pass should replace the remaining bare-word "Hilt" prose in 00/02/05/08/10/11 with
  the token.
- **`{{SCREENSHOTS_SCRIPT}}` withdrawn from this stack's schema.** Rule 14 originally required it
  (`<reference-repo>#792`), but the then-generator bound every token unconditionally — a
  consumer whose repo has no mirror-helper script of its own fails closed with no drift report at
  all, not a "no automation yet" note. <product-repo-B> hit exactly this on the `v0.11.0` repin
  (RR-IS-#831). Rule 14 was revised to document
  a manual mirroring flow the helper would otherwise have automated — but see the correction below,
  the revision's own premise about the other two tokens turned out to be wrong.
- **`{{ASSETS_REPO}}`/`{{ASSETS_LAYOUT}}` withdrawn from this stack's schema — the #831 fix's
  premise about them was false.** The note above (and Rule 14's `<reference-repo>#831` revision) asserted these two
  tokens "were already bound" in <product-repo-B>, reasoning by analogy from the `swiftui-tca-uzf-v2`
  schema where the equivalent tokens genuinely are bound for <product-repo-A>. That was never checked
  against <product-repo-B>'s own `.claude/canon-values.yml`, which binds neither
  (RR-IS-#835) — `rules/14-ui-screenshots.md`
  did not exist in `compose-uzf-v2` before `v0.11.0`, so no `compose-uzf-v2` consumer had ever
  needed to bind them, and the assumption that they'd carried over from a prior release went
  unverified. Same failure as the `SCREENSHOTS_SCRIPT` case above — a stack schema requiring a
  binding no registered consumer actually has — so the same fix applies: Rule 14's UZF-26 mandate
  (embed the Paparazzi PNGs so a reviewer judges the change without running Gradle) no longer
  depends on a public assets-repo mirror. The `## Screenshots` section names each changed scene and
  its committed path; the reviewer opens the PR's **Files changed** tab to see the actual PNG,
  rendered natively with the viewer's own repo permissions — no anonymous fetch, no camo, nothing to
  mirror or pin a SHA against. `swiftui-tca-uzf-v2`'s `{{ASSETS_REPO}}`/`{{ASSETS_LAYOUT}}` binding
  for <product-repo-A> is untouched; a future `compose-uzf-v2` consumer that stands up its own public
  assets-mirror host can re-adopt the same pattern, added back to this schema at that point rather
  than carried here speculatively.
