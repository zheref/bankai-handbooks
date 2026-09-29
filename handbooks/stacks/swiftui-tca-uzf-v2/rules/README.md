<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# `swiftui-tca-uzf-v2` — canonical rule set

The **single source** for the SwiftUI + TCA UZF stack's operational rules (`CON-13`). A consumer
repo on this stack carries a **generated, pinned mirror** of these files in each agent surface's
rules location (`.claude/rules/` for Claude Code, and the Codex / Cursor / Antigravity
equivalents), never hand-authored, so every agent loads them natively (history: `<reference-repo>#34`). The
condensed, ID'd form lives in [`../architecture.md`](../architecture.md) (`SW-{n}`) and the
cross-platform concepts in [`../../../uzf-core.md`](../../../uzf-core.md) (`UZF-{n}`); these rule
files are the operational expansion. Repo-specific values are [`{{tokens}}`](placeholders.md).

| File | Concern |
|---|---|
| `00-overview` | 10-second layer/artifact/active-passive triage |
| `01-folder-layout` | Folder tree + per-artifact import allow/deny matrix |
| `02-naming` | File-suffix taxonomy + action-case prefixes |
| `03-tca-idioms` | `@Reducer`/`@ObservableState`/navigation/bindings |
| `04-services-dependencies` | `@DependencyClient` shape, Repository, segregation |
| `05-state-shifters-selectors` | State, `apply…` Shifters, `…Selector`s |
| `06-producers-effects` | Producers, Effects, cancellation |
| `07-testing` | Test minimums + snapshot tooling |
| `08-anti-patterns` | The coded reject list (`A/S/AC/V/D/C/M/T`) |
| `09-design-system` | `Design/`, `AppTheme`, accessibility |
| `10-migration` | Legacy→UZF + v1(Page)→v2(Screen/View) migration |
| `11-feature-documentation` | `{{DOCS_ROOT}}` specs + mermaid |
| `12-session-completion-checklist` | Definition-of-done gate |
| `13-build-execution` | Xcode hung-clang recovery + exec context |
| `14-github-version-control` | VCS ops (defers to `CON-17/20/21`, `_conventions`) |
| `15-database-migrations` | Pointer → `UZF-25` |
| `16-ui-screenshots` | Snapshot embed/mirror mechanics (`UZF-26`/`SW-18`) |

## Reconciliation decisions (`<reference-repo>#34`, three-way: <reference-repo> ↔ <product-repo-A> `.claude/` ↔ OneDrive UZF)

These files were produced by adopting <product-repo-A>'s `.claude/rules/` (the most complete source),
reconciled against the OneDrive UZF canon. Decisions the human ratified:

| Topic | Decision |
|---|---|
| **Canon version** | The **Screen/View split** model is canon. This stack id (`swiftui-tca-uzf-v2`) calls it **v2**; the OneDrive synthesis numbers the identical model **v3**; `…Page.swift` is the **retired v1** form. The numbers differ across sources but name the same rules — this note is the mapping. |
| **OneDrive source** | **Retired / superseded.** The canon repository (then `<reference-repo>`, now `bankai-handbooks`) is the single source; the OneDrive `UZF/` folder is archival and <product-repo-A>'s OneDrive pointers are removed (follow-up <product-repo-A> PR). |
| **`08` A10/A11 numbering** | <product-repo-A>'s numbering is canon: `A10` = a `<Name>View.swift` importing `ComposableArchitecture`; `A11` = an architecture change shipped without a doc update. |
| **`14` assignee** | Scoped: **issues** assign `@me` (the running contributor) additively for credit; **PRs** assign `{{MAINTAINER}}` fixed; **bankai CI-agent-tier** artifacts follow the shared agent conventions (`_conventions.md`) (assign the human maintainer, not `@me`). |
| **No rule contradictions** | The three sources agreed on every actual coding rule; the reconciliation was additive (<reference-repo> absorbed <product-repo-A>/OneDrive operational detail it lacked). |
