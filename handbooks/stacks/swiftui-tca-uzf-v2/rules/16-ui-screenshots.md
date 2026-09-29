<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 16 — UI Screenshots (from snapshot tests)

Implements **UZF-26** (UI changes carry visual evidence from their tests) and its
stack binding **SW-18** for SwiftUI/TCA — the operational "how" for this repo family.
Every UI PR shows the visual change, and the images come **straight from the mandatory
snapshot tests** — never separately-staged captures. Sasuke enforces UZF-26 as a
completeness check.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{PROJECT_NAME}}` | `Acme` |
| `{{ASSETS_REPO}}` | `acme/acme-assets` |
| `{{ASSETS_LAYOUT}}` | `Acme/pr-<n>/<scene>.png` |
| `{{SCREENSHOTS_SCRIPT}}` | `ci_scripts/pr_screenshots.sh` |
| `{{TEST_TARGET}}` | `AcmeTests` |
| `{{XCODEPROJ}}` | `Acme.xcodeproj` |
| `{{SCHEME}}` | `Acme` |
| `{{SNAPSHOT_DEVICE}}` | `iPhone 17 Pro` |
| `{{SNAPSHOT_OS}}` | `26.5` |
| `{{SNAPSHOT_PATH}}` | `AcmeTests/Application/<Name>/__Snapshots__/<Name>SnapshotTests/test_<scene>.1.png` |

## The expectation (UZF-26)

Any PR that adds or changes a **TCA-free `<Name>View.swift` renderer** — defined
**structurally** (**SW-2**): a `…View.swift` that does not `import
ComposableArchitecture` and references no `Store`/`Action`, **wherever it lives**.
That includes reusable UI (e.g. `AcmeUI/ComingSoon/ComingSoonView.swift`), feature
renderers (e.g. `Acme/Application/Fragments/DayFragment/DayView.swift`), and reusable
components under `Acme/Components/` or `AcmeUI/Components/`. **Folder is not the
trigger — the absence of TCA is.** Such a PR embeds the snapshot images in the PR
description under a `## Screenshots` section:

- **one image per user-visible state**, captioned with the scene name;
- **mirroring the `#Preview` / snapshot set 1:1** (same scenes, same names);
- so a reviewer can judge the change **without building the project**.

A logic-only PR that touches no View/component is **exempt** — state the exemption in
the PR description (e.g. "No UI surface changed — screenshots N/A").

The UZF-26 mandate never weakens: the fix for "I can't record baselines" is a
snapshot-capable runner, not a missing screenshot. The only two sanctioned
incompletenesses are UZF-26's *bankai-mode timed deferral* (no snapshot-capable runner
at child-review time — a tracked IOU trued-up at the final `integration/<epic> → main`
PR) and a *demonstrated capture-tooling gap* (a scene proven un-capturable across
multiple strategies — a tracked `XCTSkip` referencing a capture-tooling issue).

## The source: the snapshot PNGs *are* the screenshots (SW-18)

Do not take fresh captures. The screenshots are the exact PNGs recorded by the
snapshot tests (see [07-testing.md](07-testing.md) / SW-17), which already exist and
are committed:

```
{{SNAPSHOT_PATH}}
```

One per scene, matching the View's `#Preview` blocks 1:1. Because these are the same
bytes the tests assert against, the screenshots **cannot silently drift** from the
shipped UI — if the View changes, the snapshot re-records and the PR re-attaches it,
or the snapshot test fails.

**Fixtures must be `#if DEBUG` mock data only** (Rule 07 / UZF-18) — never a real
captured account/session. These exact PNGs are **committed to this repo _and_ mirrored
to the public `{{ASSETS_REPO}}` host** (see below), so a snapshot rendered from live
data would leak it publicly (**SEC-8**, data minimization). Current practice
(mock-only fixtures) already satisfies this; the line is a guard-rail against future
drift — **anything hosted for a screenshot is world-readable.**

## Recording (recap of Rule 07 / SW-17)

Record against the reference environment — **{{SNAPSHOT_DEVICE}} · iOS {{SNAPSHOT_OS}}**:

```bash
xcodebuild -project {{XCODEPROJ}} -scheme {{SCHEME}} \
    -destination 'platform=iOS Simulator,name={{SNAPSHOT_DEVICE}},OS={{SNAPSHOT_OS}}' \
    -only-testing:{{TEST_TARGET}}/<Name>SnapshotTests test
```

The first run records the baselines; a second run verifies parity. **Open each PNG
before committing** — a "passing" run can still record a blank image (Rule 07's glass
/ alpha=0 pitfalls; glass surfaces opt into `liquidGlassFallback()` — SW-17).

## Embedding them in the PR description

This repo is **private**, and that dictates the mechanism (the UZF-26 hosting rule).
GitHub does **not** render `raw.githubusercontent.com` / `…/blob/…?raw=true` images
from a private repo inline: its image proxy (camo) fetches **anonymously**, gets a
`404` on the private URL, and shows a broken image. (Verified: an anonymous `curl` of
a private-repo raw URL returns `404`. `user-attachments` uploads render but have no
API — they require the web uploader.)

So the snapshot PNGs are **mirrored to the public `{{ASSETS_REPO}}`** repo — the shared
image host for every {{PROJECT_NAME}} product family (Apple / Android / Web) — and
referenced from there:

```
<img src="https://raw.githubusercontent.com/{{ASSETS_REPO}}/<sha>/{{ASSETS_LAYOUT}}" width="240">
```

Because `{{ASSETS_REPO}}` is **public**, that URL is anonymously fetchable (`200`), so
camo renders it inline in this private repo's PR description. Notes (the three UZF-26
hosting properties):

- **Layout in `{{ASSETS_REPO}}`:** `{{ASSETS_LAYOUT}}`. **Pin to the assets-repo
  commit SHA** so the URL is stable.
- **Public host → mock-data only, and permanently public (one-way door).** Only
  `#if DEBUG`/mock-fixture snapshots may be mirrored (**SEC-8**) — never a screenshot
  rendered from real data. A push is irreversible: once a PNG is in `{{ASSETS_REPO}}`,
  a later delete does **not** retract it (git history + any fork/clone persists it,
  and the SHA-pinned URL keeps resolving). An accidental non-mock snapshot is an
  **incident** (rotate/notify), not a delete. The helper therefore **confirms before
  pushing** (a technical gate; skip with `-y` only in automation).
- **Append-only retention:** `{{ASSETS_REPO}}` is not pruned — merged/closed PRs'
  images are not removed. That's the accepted policy: the volume is tiny and old SHAs
  must keep resolving for historical PRs. No cleanup job.
- The committed PNGs **also** render in the product repo's _Files changed_ tab — a
  zero-effort backstop — but the `## Screenshots` section is still required.

**Prerequisites for the helper:** push access to `{{ASSETS_REPO}}` (ask the maintainer
if `git push` fails), an authenticated `gh` CLI, and an **open PR** on the branch (its
number is the `{{ASSETS_REPO}}` folder).

### Flow

1. Record and verify the snapshots (Rule 07) and commit them to the product repo.
2. **Push the branch and open its PR** — the helper resolves the `pr-<n>` folder via
   `gh pr view`, so it needs an open PR (it exits with an error otherwise).
3. Run the helper — it mirrors this branch's snapshot PNGs to `{{ASSETS_REPO}}` (under
   the PR folder), asks you to confirm the public push, and prints a ready-to-paste
   `## Screenshots` block pinned to the resulting assets-repo SHA:
   ```bash
   {{SCREENSHOTS_SCRIPT}}            # diffs against origin/main
   ```
4. Paste the printed block into the PR description. It renders inline — no uploads, no
   drag-drop.

## Keeping them current (UZF-26 drift)

The embedded `<img>` is pinned to the **assets-repo SHA from when the helper last
ran** — a separate artifact from the product-repo commit, so it does **not**
auto-track later snapshot changes. Therefore, whenever a snapshot changes after the
block was first pasted, **re-running the helper and re-pasting the block is mandatory,
not best-effort** — otherwise the description silently shows a stale image while the
shipped PNG has moved on. A stale screenshot is worse than none. (The snapshot test is
the drift backstop for the *committed* PNG; the pasted block has no such backstop,
which is why the re-paste is required by hand.)

## Cross-references

- `{{ASSETS_REPO}}` — the public image host (shared across the product family) that
  makes inline screenshots possible from a private repo; its README documents the
  layout and the public/mock-only rule.
- [07-testing.md](07-testing.md) / **SW-17** — recording snapshots, the iOS
  {{SNAPSHOT_OS}} reference environment, and the blank-snapshot pitfalls.
- [12-session-completion-checklist.md](12-session-completion-checklist.md) /
  **UZF-23** — the completion-checklist item that gates this before "done".
- [14-github-version-control.md](14-github-version-control.md) — PR body conventions.
- `uzf-core.md` **UZF-26** / **SW-18** — the language-agnostic expectation Sasuke
  enforces on every UI PR, and its SwiftUI binding.
