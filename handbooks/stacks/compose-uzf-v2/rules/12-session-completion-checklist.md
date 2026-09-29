<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 12 — Session Completion Checklist

Implements **UZF-23** (the session-completion gate) for the Jetpack Compose / UZF
stack. A "session" is one focused unit of work on a single feature — one branch,
one PR, one ramp-up. **A session is not complete** until every item here is
satisfied. Use this to refuse marking work done; use it in PR review to refuse
merge.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{CORE_FRAMEWORK}}` | `AcmeCore` |
| `{{FLAG_ENUM}}` | `FeatureFlagsService.kt` (`object FeatureFlags`) |
| `{{DOCS_ROOT}}` | `docs/Features` |
| `{{LINT_SCRIPT}}` | `./gradlew :app:testDebugUnitTest` |

## The Checklist

For every session that touches a feature, before declaring it done:

### 1. Coverage ≥ 80% on touched files (UZF-19)

- Run the repo's verification command (`{{LINT_SCRIPT}}`) — in this stack it runs the
  JVM unit suite (alongside the Konsist arch gate). The files you added or modified must
  have **line coverage ≥ 80%**.
- Coverage of the project as a whole is not the bar — *touched files* are the bar.
  A 30-line bug fix in an 80%-covered file is fine; the same fix that takes
  coverage below 80% is not.
- Coverage is measured with JaCoCo via Gradle (`./gradlew jacocoTestReport`, or the
  project's configured JaCoCo task). The CI gate must read from the same source so
  local and CI agree.
- The per-artifact minimums from [09-testing.md](09-testing.md) / **UZF-18** /
  **KT-22** still apply on top of the 80% floor:
  - ≥ 3 unit tests per non-trivial reducer arm, driven through Turbine on both
    `state` and `uiEffects`.
  - ≥ 3 tests per Shifter, per Selector.
  - ≥ 3 cases per Mapper function (`toDomain`, `fromDomain`, `toException`).
  - ≥ 3 `@Preview` Composables + ≥ 3 matching Paparazzi snapshot tests per Page
    (**KT-13** / **KT-22**), built from the feature's `<Feature>Mocks.kt` — never
    inline `State`.
  - ≥ 7 mocks per new domain model, in the model's `companion object`
    (3 convenient, 1 neutral, 3 inconvenient — e.g. happy / empty / long /
    non-ASCII / missing-optional / stale / fresh).
- Files exempt from the 80% floor: Pages fully exercised by Paparazzi snapshots
  (**KT-1** / **KT-22**), generated code, `<Feature>Mocks.kt` (the mocks file),
  and `<Feature>Module.kt` (pure Hilt wiring — **KT-17**). Note the exemption in
  the PR description.

### 2. Mermaid diagram is current (UZF-21)

- The ` ```mermaid ` fenced block(s) inside `{{DOCS_ROOT}}/<FeatureName>.md` reflect
  the behavior shipped in this session. (Standalone `.mermaid` files are retired —
  every diagram is a fenced block inside the spec; see
  [13-feature-documentation.md](13-feature-documentation.md).)
- If the spec has no diagram yet, **add one now** per
  [13-feature-documentation.md](13-feature-documentation.md).
- New states, new edges, new branches in user flows → diagram update in the same
  PR.

### 3. Feature spec is current (UZF-21)

- `{{DOCS_ROOT}}/<FeatureName>.md` reflects the shipped behavior.
- If the doc didn't exist, **create it now** per Rule 13.
- Sections to revisit every session:
  - **User flows** — any new tap target, gesture, or empty-state copy goes here.
  - **States** — any new state, including failure / empty / loading variants.
  - **Interactions with other features** — any new delegate event, navigation, or
    cross-feature scroll/jump.
- The doc is language-agnostic. Resist the urge to mention type names — describe
  behavior.

### 4. Feature flag wrapping (UZF-22)

- Any session that adds **new user-visible behavior** must check whether a feature
  flag already covers it.
- If yes: confirm the new behavior is reachable only when its flag resolves enabled
  (via the flag registry's resolver). Gate the behavior at the boundary — the
  `<Feature>Screen` Composable (**KT-1**) and Producer methods (**KT-8**) — **not**
  deep inside the reducer, which stays pure (**KT-5**).
- If no: introduce a new flag. Register a flag entry in the platform's flag registry
  (`{{FLAG_ENUM}}`, in `{{CORE_FRAMEWORK}}`) and register its default in the
  status-quo default set (usually disabled — `isOn = false` — for greenfield work),
  then document it in `{{DOCS_ROOT}}/<FeatureName>.md` under **Feature flag**.
- One feature flag = one feature doc file. Do not split a single product feature
  across multiple flags unless the rollout strategy genuinely requires it.
- Internal-only refactors and bug fixes do **not** need new flags.

### 5. UI screenshots — from snapshot tests (UZF-26)

- Any session that adds or changes a stateless `<Feature>Page` (structurally:
  `(state, onEvent, modifier)`, navigation- and DI-free — **KT-1**/**KT-2**) or a
  reusable Fragment/Adapter must embed the **mandatory Paparazzi snapshot images**
  in the PR description under a `## Screenshots` section — one per user-visible
  state this branch actually adds or re-records, mirroring that changed set
  1:1 (never the Page's full `@Preview` inventory — an unrecorded golden isn't
  in the diff). See [14-ui-screenshots.md](14-ui-screenshots.md) (implements
  **UZF-26** / **KT-13**/**KT-22**).
- The screenshots are the **recorded Paparazzi PNGs themselves**
  (`app/src/test/snapshots/images/`, Rule 09 / **KT-22**), never
  separately-staged captures — so what the reviewer sees is exactly what the
  tests assert.
- Group the changed scenes' names and committed paths
  (`{{UI_MODULE}}/src/test/snapshots/images/<file>.png`) into the
  `## Screenshots` section **per `UZF-26`'s presentation contract** — one table
  per top-level screen, titled with the issue(s) that composed it, changed
  states across the columns — the reviewer opens the PR's **Files changed**
  tab to see the actual PNG, rendered natively under their own repo
  permissions; this stack has no public assets-mirror to push to (Rule 14 /
  `RR-IS-#835`).
- **If a scene is renamed, added, or removed, update the table to match** — the
  image itself can't go stale (it's the committed file, not a separately
  hosted copy), but a name or path that no longer matches its scene still
  misleads the reviewer (Rule 14 drift note / UZF-26).
- Logic-only sessions (no Page/Fragment/Adapter change) are exempt — note the
  exemption in the PR description.

## When you may skip an item

You may skip an item only when the user has explicitly accepted the gap **in writing
in the PR / conversation**, and only for one of these reasons:

- **Coverage** — A spike or research branch that will not be merged. Mark the PR as
  draft, label `do-not-merge`.
- **Diagram** — The feature has no flow worth diagramming (e.g. a single static
  page). Note the omission in the doc itself.
- **Spec** — The session was a pure-tech-debt change (file moves, dependency bumps,
  renames inside one file) with zero behavior change. Note in PR description.
- **Flag** — Bug fix to existing flagged behavior; no new product surface
  introduced.

The **UZF-26 visual evidence** carried by a UI change — the Paparazzi snapshots that
mirror a Page's `@Preview` set (**KT-13** / **KT-22**) — is **not** a
freely-waivable coverage item. Its only two sanctioned incompletenesses are the
UZF-26 *bankai-mode timed deferral* (no snapshot-capable runner yet — a tracked IOU
with a mandatory true-up) and a *demonstrated capture-tooling gap* (the tooling
provably cannot render a specific scene — a tracked, skipped snapshot), never an
arbitrary written waiver. A logic-only session that changes no Page/component is
simply exempt — note "no UI surface changed" in the PR description.

If none of those apply, **complete the item**.

## Enforcement

This checklist is enforced at three points:

1. **Self-review** — before pushing your last commit, re-read this file. If any item
   is open, finish it.
2. **PR description** — the PR template includes the checklist; the author ticks each
   box or notes the explicit skip reason. Reviewers reject PRs with un-ticked boxes
   and no skip note.
3. **Claude Code (this assistant / the CI review agent)** — when asked to "wrap up",
   "mark this done", "ship it", or similar, the assistant must walk the checklist and
   report which items are not yet satisfied. Refuse to declare a session complete
   with open items unless the user explicitly waives one with a reason.

## Infra/process-dependency propagation is part of "done" (UZF-23 / CON-21)

If the session bumped a **shared infra/process dependency that CI resolves
per-branch** (a pinned reusable-workflow tag, a tool/runtime/SDK version, a shared
config/secret contract), the session is not complete until that bump has **cascaded
to every live `integration/*` branch** — and thereby the feature branches off them —
or an explicit, reasoned deferral is noted (e.g. "no integration branch is live"). A
**trunk-only repin is not a completed bump**: it silently strands every in-flight
epic on the old version. See the shared GitHub-version-control canon (bankai's
cross-stack general rules — not a `compose-uzf-v2` rule file) for the concrete
trunk-first → cascade → inherit-by-rebase procedure (CON-21).

## Suggested order during a session

1. Implement the change.
2. Write / update tests (JUnit5 + Turbine for Features; Paparazzi for Pages; plain
   JUnit for Shifters / Selectors / Mappers) until coverage on touched files is
   ≥ 80% and the UZF-18 / KT-22 minimums are met.
3. Update / create the feature spec under `{{DOCS_ROOT}}/<FeatureName>.md`.
4. Update / create the mermaid diagram.
5. Verify flag wrapping; introduce a flag (and its status-quo default) if missing.
6. For UI changes, attach the Paparazzi snapshot screenshots to the PR
   description (Rule 14).
7. Commit, per the repo's commit-message convention (CON-17). The session is now
   done.

## Cross-references

- [09-testing.md](09-testing.md) / **UZF-18** / **KT-22** — testing minimums per
  artifact (Turbine, Paparazzi, MockK).
- [13-feature-documentation.md](13-feature-documentation.md) / **UZF-21** — where
  docs live and how they're shaped.
- [14-ui-screenshots.md](14-ui-screenshots.md) / **UZF-26** / **KT-13**/**KT-22**
  — sourcing and embedding the Paparazzi snapshot screenshots.
- [11-forbidden-patterns.md](11-forbidden-patterns.md) — the greppable anti-pattern
  list to self-review against.
- Platform flag registry (`{{FLAG_ENUM}}`, in `{{CORE_FRAMEWORK}}`) — where flag
  entries and their status-quo defaults live (UZF-22).
