# Handbooks

The guild's **numbered, citable policy**. Every reviewer finding must cite a rule
from here (or a public standard like CWE/OWASP). No uncited opinions.

> **Handbook set version:** [`VERSION`](VERSION) is the single source of truth for
> the current token. Agents stamp the version they reviewed against in every
> output header and machine stamp. Canon-lane-maintained (see [`INDEX.md`](INDEX.md));
> changes are **G4-gated** (human merges only).
>
> **This repository (`zheref/bankai-handbooks`) is the single canonical source of the
> handbooks (`CON-13`).** Consumer repos carry generated, pinned, per-surface mirrors —
> see [*How canon reaches a consumer*](#how-canon-reaches-a-consumer-con-13) below.

## Layout: general (top level) + per-stack folders

General handbooks apply to **every** stack and live at the top level. Each
supported stack has a folder under [`stacks/`](stacks/) holding the concrete
framework rules for that stack. A review loads **all general handbooks plus the
one stack folder** for the repo under review.

| File | Citation prefix | Owner / enforcer | Scope | Purpose |
| --- | --- | --- | --- | --- |
| [`uzf-core.md`](uzf-core.md) | `UZF-{n}` | Sasuke | general | Cross-platform UZF architecture (flow, artifacts, purity, testing, docs, flags). |
| [`security-baseline.md`](security-baseline.md) | `SEC-{n}` (+ `CWE`/OWASP) | Tenma | general | Data-security, privacy, and compliance baseline. |
| [`ux-baseline.md`](ux-baseline.md) | `UX-{n}` (+ `WCAG`/HIG/Material) | the design reviewer *(Phase 2; Edward self-applies at build in Phase 1a)* | general | UI/UX design-quality baseline — accessibility, touch, tokens, typography, motion, layout, forms, nav, data-viz. |
| [`release-policy.md`](release-policy.md) | `REL-{n}` | Natsu | general | Versioning, release gates, store-submission policy (G3). |
| [`quality-baseline.md`](quality-baseline.md) | `QA-{n}` (+ `CWE`/`WCAG`) | Rukia *(future CI gate; Ichigo's Hollow nature self-runs it locally today)* | general | Adversarial QA method, E2E tooling by scenario, performance budgets, process-machinery testing, the advisory pre-release gate. |
| [`spec/authoring.md`](spec/authoring.md) | `SP-{n}` | the spec folder's reviewer (never its author) | general (spec repositories) | Writing and reviewing a family specification — citation-or-marker, confidence tiers, fenced source data, platform-neutral vocabulary, parity handlings, the living spec, bounded clarification, reviewer-owned checklists. |
| [`stack-matrix.md`](stack-matrix.md) | — | Naruto | general | Scenario registry + how the right stack folder is resolved per repo. |
| [`stacks/swiftui-tca-uzf-v2/architecture.md`](stacks/swiftui-tca-uzf-v2/architecture.md) | `SW-{n}` | Sasuke | stack | SwiftUI + TCA bindings (iOS/macOS). Refines `UZF-{n}`. |
| [`stacks/compose-uzf-v2/architecture.md`](stacks/compose-uzf-v2/architecture.md) | `KT-{n}` | Sasuke | stack | Jetpack Compose + Hilt bindings (Android). Refines `UZF-{n}`. |
| [`stacks/react-uzf-v1/architecture.md`](stacks/react-uzf-v1/architecture.md) | `RC-{n}` | Sasuke | stack | React 19 + Redux Toolkit bindings (Next.js web + Expo mobile, one shared state tier; on scaffold scenario 2A also the Electron desktop shell, `RC-64`–`RC-69`). Refines `UZF-{n}`. |
| [`stacks/bankai-machinery/architecture.md`](stacks/bankai-machinery/architecture.md) | `BC-{n}` | Sasuke / Tenma | stack (self-review) | Framework **machinery** review rules — reusable-workflow/permission hygiene, CI trust/fork-safety, lane/authorship. Machinery repos only; **no product code**. Scenario id `bankai-machinery` (renamed at v0.6; `BC-` kept). |
| [`ports/INDEX.md`](ports/INDEX.md) | `PT-{n}` (one global counter) | `hatsu:bankai-rule` writes; the architecture reviewer reviews | port (pair) | Port rulings: one directed pair file per pair of product stacks — how a `<from>` rule or concept is realised on the `<to>` stack. Read beside the always-load set and the target's stack handbook, never alone. |

## Citation families

- **Sasuke** (architecture) cites `UZF-{n}` (cross-platform core) and the loaded
  stack's `SW-{n}` / `KT-{n}` / `RC-{n}` / `BC-{n}` (framework-specific — `BC-{n}` for the
  `bankai-machinery` self-review scenario, where Tenma also cites it for CI-security findings). A stack rule refines a `UZF-{n}`
  rule and names its parent; it never contradicts it.
- **Tenma** (security) cites `SEC-{n}` from `security-baseline.md`, or a public
  `CWE-{n}` / OWASP reference when it maps more precisely.
- **The design reviewer** (design quality, reviewer tier — Phase 2) cites `UX-{n}` from
  `ux-baseline.md`, or a public `WCAG` / Apple HIG / Material reference when it maps more
  precisely. In **Phase 1a** there is no design gate yet — **Edward** self-applies the
  `UX-{n}` rules at build time and the human reviews at G2.
- **Natsu** (release) cites `REL-{n}`.
- **Quality** (adversarial QA + performance) cites `QA-{n}` from `quality-baseline.md`, or a
  public `CWE-{n}` / `WCAG` reference where one maps more precisely. There is **no CI quality
  gate yet** — **Ichigo's Hollow nature** self-runs these locally, on demand, before a release,
  and its `Quality-Gate:` verdict is **advisory**: the human owns G3 (`QA-21`, `CON-6`). The CI
  gate (**Rukia**) follows later, exactly as the design reviewer followed the `UX-{n}` baseline.
- **Spec authoring** cites `SP-{n}` from `spec/authoring.md` when the object under review is a
  family specification folder; its completeness claims cite `SP-14`.
- Because a review loads exactly one stack folder, `SW-{n}`, `KT-{n}`, `RC-{n}` and `BC-{n}`
  are never in scope together — no cross-stack collision.
- A finding that no rule covers → the reviewer opens a scope-routed
  `bankai:handbook-question` (a handbook/stack-rule gap is canon → `bankai:agent/yamamoto`; a
  `CON-{n}` governance gap → `bankai:agent/naruto`; `CON-37`) and does **not** improvise policy.

## Port rulings (`PT-{n}`)

[`ports/`](ports/INDEX.md) records, per **directed** pair of product stacks in
[`stack-matrix.md`](stack-matrix.md), how a rule or concept of the `<from>` stack is realised on the
`<to>` stack (`map` · `mirror` in the Equivalence table, `drop with note` · `target-only addition` in
the Drift table). It is not a stack handbook and changes nothing about which stack folder a review
loads: a pair file is read **beside** the always-load set and the target's stack handbook, **never
alone**. Ids are `PT-{n}` from **one counter across every pair file** (zheref/hatsu ROSTER HR-9; the
counter zheref/hatsu#392 landed, re-confirmed by HR-34) — append-only, never reused, a reversal is a
new row with `supersedes`. Rows are written by `hatsu:bankai-rule` from the maintainer's answers and
land by G4 PR; the files are rendered from Hatsu's `templates/ports/` and keep their
`Canonical source` marker.

## Adding a stack

1. Add a scenario row to [`stack-matrix.md`](stack-matrix.md).
2. Create `stacks/<scenario-id>/` with `architecture.md` (its own citation prefix,
   refining `UZF-{n}`) and a `README.md` facet card.
3. Consumer repos on that stack record `<scenario-id>` as their scenario in the
   consumer registry and regenerate their mirrors. MINOR version bump.
4. A product stack adds its directed port pair files in the same PR, one per direction to and
   from every other product stack. Each is rendered empty (no ruling rows) from Hatsu's
   `templates/ports/pair.md` as a scaffold, and its marker names that template. The PR also adds
   each file's row in [`ports/INDEX.md`](ports/INDEX.md) at a ruling count of `0` and its row in
   [`INDEX.md`](INDEX.md)'s *Port rulings* table. `hatsu:bankai-rule` appends rows on the first
   ruling and never creates a file (`CON-13`, *Port rulings*).

## Versioning

- Format is `vMAJOR.MINOR` — the leading `v` is part of the token, matching the
  version stamp agents write in their review-output header (that template lives with
  the CI plane's machinery, not in this repository).
- The single source of truth is [`VERSION`](VERSION), which holds the **complete
  token including the `v`**. Agents stamp it **verbatim** — no add/strip of a `v`.
- **MINOR** bump: rules/stacks added, wording clarified. **MAJOR** bump: a rule's
  meaning changes, a rule is removed, or citation prefixes are restructured.
- **Pre-1.0 carve-out (`v0.x`):** while the taxonomy is still stabilizing, a
  breaking restructure — like the v0.2 prefix split — is allowed within a **MINOR**
  bump. The MAJOR/MINOR guarantees above become firm from **`v1.0`** onward, once
  live review citations exist to protect.
- Within a family, rule numbers are **append-only and stable**: never re-purpose a
  retired number; mark a retired rule `RETIRED` in place.

> **v0.2 restructure note.** v0.1 shipped one flat `uzf-swiftui-tca.md` citing
> `UZF-{n}` for the Swift stack. v0.2 splits that into the cross-platform
> `uzf-core.md` (`UZF-{n}`) plus per-stack `SW-{n}` (Swift) and adds `KT-{n}`
> (Kotlin/Compose). Prior `UZF-{n}` citations from v0.1 do not carry forward
> unchanged — this is the one deliberate renumber, done before any stack besides
> Swift went live.
>
> **v0.6 migration note (2026-09-28).** The handbook set moved out of the frozen,
> private reference implementation into this repository, `zheref/bankai-handbooks`
> (see [`../MIGRATION.md`](../MIGRATION.md)). Three changes, no rule renumbered:
> the machinery self-review stack is **renamed `bankai-machinery`** — its former id was
> the reference implementation's own repository name (`<reference-repo>`)
> (directory and scenario id; the **`BC-` prefix is kept** so citations stay valid);
> `CON-13`'s mirror doctrine is **re-pointed** at this repository and made
> per-surface; and every repo-specific example value is **tokenised** — the
> illustrative product in examples is now a fictional "Acme". No rule's meaning
> changed, so this is a MINOR bump under the pre-1.0 carve-out.

## How canon reaches a consumer (`CON-13`)

One source, a generated mirror everywhere it is read:

1. **Source.** Every handbook and rule file lives here and is edited **only** here, by a
   canon-lane PR the human merges (G4). Stack rule files are product-agnostic: anything
   repo-specific is a `{{TOKEN}}` declared in that stack's
   [`stacks/<id>/rules/placeholders.md`](stacks/).
2. **Pin.** A consumer pins a **tag** of this repository, never floating `main`, and the tag
   must contain the canon it mirrors (tag first, then repin).
3. **Resolve.** `nen canon resolve` computes, from the consumer's recorded scenario, the
   always-load set ([`INDEX.md`](INDEX.md)) plus exactly **one** stack handbook.
4. **Render, per surface.** Hatsu/Nen substitute the consumer's `canon-values` bindings
   into the stack's `rules/` and write the result into the rules location of **each agent
   surface the consumer uses** — Claude Code `.claude/rules/`, Codex `AGENTS.md`, Cursor
   `.cursor/rules/`, Antigravity `.agents/rules/`, and any surface added later — each in that
   surface's own file shape and size limits. Every generated file carries a marker naming
   its source path and pin. (Today `nen canon mirror generate` renders one rules directory;
   fanning the same render out to every surface is the intended next step and is what this
   doctrine is written to accommodate.)
5. **Check.** `nen canon mirror check` regenerates in memory and diffs against the committed
   mirror: `missing` / `extra` / `stale` / `hand-edited` fail the consumer's CI. A mirror is a
   build artifact, not a second source.
6. **General handbooks** (`UZF-`, `SEC-`, `UX-`, `REL-`, `QA-`, and `SP-` for a spec repository
   or a product repository whose issue, PR or test quotes a spec id) are resolved **live** from a
   checkout at the pin (step 3) — they are not part of the stack `rules/` mirror today.
   Folding them into the per-surface mirror is a machinery change that this doctrine already
   permits; the rule content is authored here first either way.

What a consumer hand-authors: only genuinely repo-specific, non-canon configuration — its
`canon-values` bindings, build targets, secret wiring, and the project-specifics header of its
own instruction file. Never a rule.
