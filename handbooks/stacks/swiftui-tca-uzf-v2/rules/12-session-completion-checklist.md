<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 12 — Session Completion Checklist

Implements **UZF-23** (the session-completion gate) for the SwiftUI/TCA stack. A
"session" is one focused unit of work on a single feature — one branch, one PR, one
ramp-up. **A session is not complete** until every item here is satisfied. Use this
to refuse marking work done; use it in PR review to refuse merge.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{TEST_TARGET}}` | `AcmeTests` |
| `{{SCREENSHOTS_SCRIPT}}` | `ci_scripts/pr_screenshots.sh` |
| `{{FLAG_ENUM}}` | `FeatureFlags.swift` |

## The Checklist

For every session that touches a feature, before declaring it done:

### 1. Coverage ≥ 80% on touched files (UZF-19)

- Run the test target. The files you added or modified must have **line coverage
  ≥ 80%**.
- Coverage of the project as a whole is not the bar — *touched files* are the bar.
  A 30-line bug fix in an 80%-covered file is fine; the same fix that takes coverage
  below 80% is not.
- Coverage measurement uses Xcode's default code-coverage report (`xcodebuild test
  ... -enableCodeCoverage YES`). The CI gate must read from the same source so local
  and CI agree.
- Minimums from [07-testing.md](07-testing.md) / **UZF-18** still apply on top of
  the 80% floor:
  - ≥ 3 unit tests per non-trivial reducer arm.
  - ≥ 3 tests per Shifter, per Selector.
  - ≥ 3 `#Preview` blocks + ≥ 3 matching snapshot tests per View.
  - ≥ 7 mocks per new domain model.
- Files exempt from the 80% floor: pure UI surfaces fully exercised by snapshot
  tests, generated code, `*+Mocks.swift`. Note the exemption in the PR description.

### 2. Mermaid diagram is current (UZF-21)

- The ` ```mermaid ` fenced block(s) inside `docs/Features/<FeatureName>.md` reflect
  the behavior shipped in this session. (Standalone `.mermaid` files are retired —
  every diagram is a fenced block inside the spec; see [Rule 11](11-feature-documentation.md).)
- If the spec has no diagram yet, **add one now** per [11-feature-documentation.md](11-feature-documentation.md).
- New states, new edges, new branches in user flows → diagram update in the same PR.

### 3. Feature spec is current (UZF-21)

- `docs/Features/<FeatureName>.md` reflects the shipped behavior.
- If the doc didn't exist, **create it now** per Rule 11.
- Sections to revisit every session:
  - **User flows** — any new tap target, gesture, or empty-state copy goes here.
  - **States** — any new state, including failure/empty/loading variants.
  - **Interactions with other features** — any new delegate event, navigation, or
    cross-feature scroll/jump.
- The doc is language-agnostic. Resist the urge to mention type names — describe
  behavior.

### 4. Feature flag wrapping (UZF-22)

- Any session that adds **new user-visible behavior** must check whether a feature
  flag already covers it.
- If yes: confirm the new behavior is reachable only when the flag is enabled.
- If no: introduce a new flag. Add it to the platform's flag enum (`{{FLAG_ENUM}}`),
  register a default state in the status-quo set (usually `.disabled` for greenfield
  work), and document it in `docs/Features/<FeatureName>.md` under **Feature flag**.
- One feature flag = one feature doc file. Do not split a single product feature
  across multiple flags unless the rollout strategy genuinely requires it.
- Internal-only refactors and bug fixes do **not** need new flags.

### 5. UI screenshots — from snapshot tests (UZF-26)

- Any session that adds or changes a TCA-free `<Name>View` renderer (structurally:
  no `ComposableArchitecture` import, wherever it lives — **SW-2**) or a reusable
  component must embed the **mandatory snapshot images** in the PR description under
  a `## Screenshots` section — one per user-visible state, mirroring the
  `#Preview`/snapshot set 1:1. See [16-ui-screenshots.md](16-ui-screenshots.md)
  (implements **UZF-26** / **SW-18**).
- The screenshots are the **recorded snapshot PNGs themselves** (Rule 07 / SW-17),
  never separately-staged captures — so what the reviewer sees is exactly what the
  tests assert.
- Run `{{SCREENSHOTS_SCRIPT}}` — it mirrors this branch's snapshot PNGs to the
  associated public assets host and prints a ready-to-paste `## Screenshots` block
  whose SHA-pinned `raw` URLs render inline (a private repo's *own* raw URLs 404 in
  the proxy — Rule 16 / UZF-26 hosting). Mirroring is a **permanent public** push
  (mock-only fixtures; the helper confirms first).
- **If a snapshot changes after the block was pasted, re-run the helper and
  re-paste** — the block is pinned to an assets-repo SHA and does not auto-track
  later changes (Rule 16 drift note / UZF-26).
- Logic-only sessions (no View/component change) are exempt — note the exemption in
  the PR description.

## When you may skip an item

You may skip an item only when the user has explicitly accepted the gap **in writing
in the PR / conversation**, and only for one of these reasons:

- **Coverage** — A spike or research branch that will not be merged. Mark the PR as
  draft, label `do-not-merge`.
- **Diagram** — The feature has no flow worth diagramming (e.g. a single static
  page). Note the omission in the doc itself.
- **Spec** — The session was a pure-tech-debt change (file moves, dependency bumps,
  renames inside one file) with zero behavior change. Note in PR description.
- **Flag** — Bug fix to existing flagged behavior; no new product surface introduced.
- **Screenshots** — The session changed no View/component (logic-only). Note "no UI
  surface changed" in the PR description. **Note:** the UZF-26 visual evidence is
  **not** a freely-waivable coverage item — its only two sanctioned incompletenesses
  are the UZF-26 *bankai-mode timed deferral* (no snapshot-capable runner yet — a
  tracked IOU trued-up at the final `integration/<epic> → main` PR) and a
  *demonstrated capture-tooling gap* (a scene that provably can't be captured — a
  tracked `XCTSkip`), never an arbitrary written waiver.

If none of those apply, **complete the item**.

## Enforcement

This checklist is enforced at three points:

1. **Self-review** — before pushing your last commit, re-read this file. If any item
   is open, finish it.
2. **PR description** — the PR template includes the checklist; the author ticks each
   box or notes the explicit skip reason. Reviewers reject PRs with un-ticked boxes
   and no skip note.
3. **Claude Code (this assistant / Sasuke in CI)** — when asked to "wrap up", "mark
   this done", "ship it", or similar, the assistant must walk the checklist and
   report which items are not yet satisfied. Refuse to declare a session complete
   with open items unless the user explicitly waives one with a reason.

## Infra/process-dependency propagation is part of "done" (UZF-23 / CON-21)

If the session bumped a **shared infra/process dependency that CI resolves
per-branch** (a pinned reusable-workflow tag, a tool/runtime/SDK version, a shared
config/secret contract), the session is not complete until that bump has **cascaded
to every live `integration/*` branch** — see [14-github-version-control.md](14-github-version-control.md)
for the concrete trunk-first → cascade → inherit-by-rebase procedure — or an
explicit, reasoned deferral is noted (e.g. "no integration branch is live"). A
trunk-only repin is **not** a completed bump.

## Suggested order during a session

1. Implement the change.
2. Write / update unit tests until coverage on touched files is ≥ 80% and the UZF-18
   minimums are met.
3. Update / create the feature spec under `docs/Features/<FeatureName>.md`.
4. Update / create the mermaid diagram.
5. Verify flag wrapping; introduce a flag if missing.
6. For UI changes, attach the snapshot screenshots to the PR description (Rule 16).
7. Commit. The session is now done.

## Cross-references

- [07-testing.md](07-testing.md) / **UZF-18** — testing minimums per artifact.
- [11-feature-documentation.md](11-feature-documentation.md) / **UZF-21** — where
  docs live and how they're shaped.
- [16-ui-screenshots.md](16-ui-screenshots.md) / **UZF-26** / **SW-18** — sourcing
  and embedding the snapshot screenshots.
- Platform flag enum (`{{FLAG_ENUM}}`) — where flags are declared.
