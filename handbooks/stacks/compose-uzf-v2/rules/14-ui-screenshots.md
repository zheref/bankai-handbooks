<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 14 — UI Screenshots (from snapshot tests)

Implements **UZF-26** (UI changes carry visual evidence from their tests) and its
stack binding **KT-13** (≥ 3 `@Preview` + matching Paparazzi snapshots) /
**KT-22** (JUnit5 + Turbine + Paparazzi) for Jetpack Compose — the operational
"how" for this repo family. Every UI PR shows the visual change, and the images
come **straight from the mandatory Paparazzi snapshot tests** — never
separately-staged captures. Sasuke enforces UZF-26 as a completeness check.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{PROJECT_NAME}}` | `Acme` |
| `{{UI_MODULE}}` | `app` |
| `{{SNAPSHOT_DEVICE}}` | `PIXEL_5` |
| `{{LINT_SCRIPT}}` | `./gradlew :app:testDebugUnitTest` |

Paparazzi's on-disk golden path is a fixed plugin convention relative to the UI
module (`{{UI_MODULE}}`) — it never varies by project the way a per-repo root does,
so it is documented below as a plain path pattern rather than a placeholder token
(and is a different on-disk shape from the SwiftUI stack's `SNAPSHOT_PATH` schema
entry, which names a per-repo `__Snapshots__` directory root — the two are not the
same concept and this rule does not reuse that name as a token here):
`{{UI_MODULE}}/src/test/snapshots/images/<package>_<TestClass>_<Test_name>.png`.

## The expectation (UZF-26)

Any PR that adds or changes a **stateless `<Feature>Page`** (defined
**structurally** — `KT-1`/`KT-2`: a `@Composable` taking exactly
`(state, onEvent, modifier)`, navigation- and DI-free), **wherever it lives**.
That includes feature renderers under `features/<feature>/`, as well as reusable
`@Composable` Fragments and Adapters (`10-naming-and-layout.md`). **Folder is not
the trigger — the Page/component shape is.** Such a PR lists the snapshot
scenes in the PR description under a `## Screenshots` section (see *Embedding
them in the PR description* below for the exact format):

- **one entry per user-visible state this branch actually adds or re-records**,
  naming the scene and its committed snapshot path;
- **mirroring that changed/added set 1:1** (same scenes, same names, as the
  diffed `{{UI_MODULE}}/src/test/snapshots/images/` set — `KT-13`) — **never**
  the Page's full `@Preview` inventory, since an unchanged golden does not
  appear in the diff at all under this stack's Files-changed-tab mechanism
  (Flow step 3 below is how that changed set is found);
- so a reviewer can judge the change **without running Gradle**, by following
  each entry to the actual PNG in the PR's Files changed tab.

**Layout (`UZF-26`'s presentation contract).** The `## Screenshots` section is
one table per top-level screen, titled with the issue(s) that composed it,
with the changed states as columns and each cell carrying that state's scene
name + committed path (see *Embedding them in the PR description* below for
the exact shape) — never a bullet list, never a tall stack.

A logic-only PR that touches no Page/Fragment/Adapter is **exempt** — state the
exemption in the PR description (e.g. "No UI surface changed — screenshots N/A").

The UZF-26 mandate never weakens: the fix for "I can't record baselines" is a
snapshot-capable runner, not a missing screenshot. The only two sanctioned
incompletenesses are UZF-26's *bankai-mode timed deferral* (no snapshot-capable
runner at child-review time — a tracked IOU trued-up at the final
`integration/<epic> → main` PR) and a *demonstrated capture-tooling gap* (a scene
proven un-capturable across multiple strategies — a tracked, skipped Paparazzi
test referencing a capture-tooling issue).

## The source: the Paparazzi PNGs *are* the screenshots (KT-13, KT-22)

Do not take fresh captures. The screenshots are the exact PNGs recorded by the
Paparazzi snapshot tests (see [09-testing.md](09-testing.md) / `KT-22`), which
already exist and are committed:

```
{{UI_MODULE}}/src/test/snapshots/images/<package>_<TestClass>_<Test_name>.png
```

One per scene this branch changed, matching those `@Preview` blocks 1:1 (never
every `@Preview` the Page defines — an unrecorded golden isn't in the diff).
Because these are the same bytes the tests assert against, the screenshots
**cannot silently drift**
from the shipped UI — if the Page changes, the snapshot re-records and the PR
re-attaches it, or the snapshot test fails.

**Fixtures must be `<Feature>Mocks` / model `mock*` data only** (`KT-18` /
UZF-18) — never a real captured account/session. This stack is structurally safe
here in a way the tooling alone does not guarantee: `KT-18` already requires
every `@Preview` and Paparazzi snapshot test to render from `<Feature>Mocks`
canned `State` (or a model's `mock*` companion fixtures) and forbids constructing
`State` inline or from a live source — so a snapshot rendered from real data is
already a rule violation upstream of this rule, not merely a hosting risk. These
exact PNGs are **committed to this repo**, visible to every collaborator with
repo access, so a snapshot rendered from live data would leak it to the whole
team (**SEC-8**, data minimization) — this rule states the constraint
explicitly rather than relying on `KT-18` alone to carry it silently. Current
practice (mock-only fixtures) already satisfies this; the line is a guard-rail
against future drift. (This stack does not mirror the PNGs anywhere more
exposed than the product repo itself — see *Embedding them in the PR
description* below; a repo that later adopts a public assets-mirror raises the
stakes to world-readable and must re-confirm this rule holds before adopting
one.)

## Recording (recap of Rule 09 / KT-22)

Record with Paparazzi's recording task, on the JVM (no emulator, no device
matrix — the reference config is **{{SNAPSHOT_DEVICE}}**):

```bash
./gradlew recordPaparazziDebug
```

The first run records the baselines; `./gradlew verifyPaparazziDebug` (or the
repo's `{{LINT_SCRIPT}}`, which runs the same suite) verifies parity on
subsequent runs. **Open each PNG before committing** — a "passing" run can still
record a blank or clipped image (theme-application / `AppTheme` wrapper
mistakes are the usual cause).

## Embedding them in the PR description

This repo is **private**, and that shapes what actually renders inline.
GitHub's image proxy (camo) fetches `raw.githubusercontent.com` /
`…/blob/…?raw=true` URLs **anonymously** — it `404`s on a private repo's own
raw URL and shows a broken image. This is not theoretical on this stack — it
already happened: `{{PROJECT_NAME}}Android`'s PR embedding in-repo
`raw.githubusercontent.com` URLs rendered broken.

`swiftui-tca-uzf-v2` solves this, for consumers that register one, with a public assets-mirror repo
(the `ASSETS_REPO`/`ASSETS_LAYOUT` tokens) that camo *can* fetch anonymously.
`compose-uzf-v2` does not require the same mirror
(RR-IS-#835 — no
`compose-uzf-v2` consumer has one registered, and a stack schema requiring a
binding no registered consumer has fails the mirror generator closed, the same failure
`<reference-repo>#831` already found and fixed for this rule's mirror-helper token). Instead,
this stack relies on the **Files changed** tab: GitHub renders a PR's
own committed diff images natively, gated by the *viewer's* actual repo
permissions — no anonymous fetch, no camo, nothing to mirror or pin a SHA
against.

So the `## Screenshots` section does not embed a fetched `<img>` — it **names**
each changed scene and points the reviewer at its committed path, laid out per
`UZF-26`'s presentation contract (`handbooks/uzf-core.md`,
the shared agent conventions (`_conventions.md`)): one table per top-level screen, titled with the
issue(s) that composed it, changed states across the columns, each cell
carrying that state's scene name + committed path:

```
## Screenshots

### <Screen name> — #<issue(s)>
| <State A> | <State B> | … |
| --- | --- | --- |
| **<scene name>** — `{{UI_MODULE}}/src/test/snapshots/images/<file>.png` (see Files changed) | … | … |
```

Only the columns for states this branch actually changed or added appear —
never a column with no path to show, since an unrecorded golden isn't in the
diff. A single-scene change may use a one-column table. Each entry matches the
diffed `@Preview`/Paparazzi set 1:1 (`KT-13`) — see *The expectation* above.
The reviewer opens **Files changed**, finds the listed path, and sees the
exact PNG the test asserts against — no upload, no drag-drop, no separate host
to trust or prune.

(`user-attachments` drag-and-drop uploads also render inline, gated by the
viewer's own repo permissions rather than anonymous fetch — but they have no
API, only the web uploader, so a PR opened headlessly by a CI agent cannot use
them. The Files-changed-tab path above works identically whether the PR was
opened by a human or an agent, which is why it is this stack's mechanism
rather than a documented alternative.)

A repo that stands up its own public assets-mirror can adopt
`swiftui-tca-uzf-v2`'s `ASSETS_REPO`/`ASSETS_LAYOUT` pattern — re-added to this
stack's `placeholders.md` schema at that point, not carried here speculatively
for a mirror that does not exist yet.

### Flow

1. Record and verify the snapshots (Rule 09) and commit them to the product
   repo.
2. Push the branch and open its PR.
3. Diff `{{UI_MODULE}}/src/test/snapshots/images/` against `origin/main` to
   find the scenes that actually changed on this branch.
4. Group the changed scenes by top-level screen and list each under a
   `## Screenshots` section in the PR description — one table per screen,
   changed states across the columns, scene name + its committed path per
   cell, per the format above.

## Keeping them current (UZF-26 drift)

Because the `## Screenshots` section links to the committed PNG rather than
embedding a separately-hosted copy, there is no second artifact to fall out of
sync with it: when a snapshot re-records, the same path already shows the new
image in Files changed — no re-paste, no stale SHA. The only remaining drift
risk is the **table itself**: if a scene is renamed or a `@Preview` added or
removed, update the table to match, so a reviewer following it never lands on a
path that no longer exists or a name that no longer matches its scene.

## Cross-references

- [09-testing.md](09-testing.md) / **KT-13** / **KT-22** — recording Paparazzi
  snapshots and the per-artifact minimums.
- [12-session-completion-checklist.md](12-session-completion-checklist.md) /
  **UZF-23** — the completion-checklist item that gates this before "done".
- `uzf-core.md` **UZF-26** — the language-agnostic expectation Sasuke enforces on
  every UI PR, and its Compose binding (`KT-13`/`KT-22`).
- `swiftui-tca-uzf-v2/rules/16-ui-screenshots.md` — the equivalent rule on the
  SwiftUI/TCA stack (`SW-18`), which mirrors to a public assets-repo host this
  stack currently has no registered consumer for; this file is its
  Compose/Paparazzi twin.
