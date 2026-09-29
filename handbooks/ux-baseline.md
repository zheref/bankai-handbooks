# UX Baseline Handbook

Numbered, citable UI/UX design-quality rules for client apps (iOS/macOS SwiftUI,
Android Compose, and web/React stacks). These make design quality a **deterministic,
enforceable** part of the Bankai process — the design counterpart to how
`security-baseline.md` (`SEC-{n}`) governs security and `uzf-core.md` (`UZF-{n}`)
governs architecture.

The design reviewer (**Bisky**, reviewer tier — Phase 2) cites these as `UX-{n}`, or a
more precise public reference (`WCAG 2.2 SC {x.y.z}`, platform HIG / Material guidance)
where one maps better. **In Phase 1a there is no CI design gate yet**: the builder
(**Edward**) *self-applies* these rules at build time and the human reviews at G2. Bisky
(the gate) is provisioned in Phase 2.

> **Adding or changing a rule?** Do not hand-edit this file in place — see
> **[Growing this handbook — how to add a `UX-n` rule](#growing-this-handbook--how-to-add-a-ux-n-rule)**
> at the bottom. A `UX-{n}` rule is authored/changed only through a Naruto G4 PR the human
> merges.

**Scope:** applies to every Stack Matrix scenario that ships user-visible UI. Concrete
thresholds bind across stacks; where a platform HIG/Material value differs, the platform
value governs and the rule names it. **Design tokens (`UX-5`) lean on the repo's existing
`AppTheme`/theme layer as the semantic-token source of truth for v1** — no separate
per-repo tokens registry is required in Phase 1a.

**A reviewer cites these rules; it never invents them.** Same discipline as `CON-11` /
`SEC-15`: a design concern with **no** matching `UX-{n}` / `WCAG` / HIG-Material reference
is a `bankai:handbook-question` scope-routed to the canon lane (§ *Reviewer discipline*), never an
improvised opinion.

Rules are **grouped by topic** and numbered **sequentially within this version**. Numbers
are **append-only and stable**: a later version appends the next number in the relevant
topical section; a retired rule is marked `RETIRED` in place, never renumbered or
re-purposed. The topical grouping mirrors the priority 1→10 ordering the UI/UX rubric
this handbook distills uses (accessibility highest, data-viz lowest), so `critical`
findings cluster at the low numbers.

---

## A. Accessibility (priority 1 — CRITICAL)

**UX-1 — Sufficient contrast and a visible focus state.** Body text and essential UI
meet a contrast ratio of **≥ 4.5:1** against their background (**≥ 3:1** for large text
≥ 24px/18px-bold and for meaningful graphical/UI components); every keyboard/pointer-focusable
control shows a **visible focus indicator**. *Anti-pattern:* gray-on-gray or low-contrast
text; **removing or suppressing focus rings**. Maps `WCAG 2.2 SC 1.4.3` (contrast),
`SC 1.4.11` (non-text contrast), `SC 2.4.7` (focus visible).

**UX-2 — Operable by keyboard/switch with accessible names.** Every interactive element
is reachable and operable without a pointer and exposes an **accessible name/label** to
assistive tech (SwiftUI `.accessibilityLabel`, Compose `contentDescription`, web
`aria-label`/labelled control). *Anti-pattern:* **icon-only buttons with no label**;
tap-only affordances that a screen reader or keyboard cannot reach. Maps `WCAG 2.2 SC 2.1.1`
(keyboard), `SC 4.1.2` (name, role, value).

## B. Touch & interaction (priority 2 — CRITICAL)

**UX-3 — Touch targets ≥ 44×44 and adequately spaced.** Tappable targets are at least
**44×44 pt (iOS HIG) / 48×48 dp (Material)** with **≥ 8px spacing** between adjacent
targets. *Anti-pattern:* dense rows of sub-44px hit areas; **hover-only interactions** with
no touch/keyboard equivalent. Maps Apple HIG (44pt), Material (48dp), `WCAG 2.2 SC 2.5.8`
(target size), `SC 2.5.5`.

**UX-4 — Every async or state-changing action gives immediate feedback.** A control that
starts async work (load, submit, navigate) gives **instant, visible feedback** — a
loading/progress/disabled state or optimistic update — so no tap feels dead. *Anti-pattern:*
a button that appears inert while work runs; **instant (0ms) state swaps** with no
transition or affordance that the state changed. Maps `WCAG 2.2 SC 4.1.3` (status messages).

## C. Visual system — style & tokens (priority 4 + 6)

**UX-5 — Style through semantic design tokens, never raw literals.** Colors, spacing,
radii, and type styles come from the repo's **semantic token/theme layer** (`AppTheme` or
the stack's equivalent) — never a raw hex/RGBA, magic px, or ad-hoc font literal inlined in
a component. New surfaces reuse existing tokens; a genuinely new value is added to the theme
first, then referenced. *Anti-pattern:* **raw hex/`Color(0x…)`/hard-coded px scattered in
components**; one-off styling that bypasses the theme. (Leans on the existing `AppTheme` as
the v1 source of truth — `UZF-26` / `SW-{n}` / `KT-{n}` govern how the design-system layer
is structured per stack.)

**UX-6 — Deliberately designed components and vector icons — no raw defaults, no emoji
icons.** Screens are composed from intentionally styled components, not framework defaults
dropped in unstyled; iconography is **vector/SF Symbols/Material Icons**, and the visual
style stays **consistent** (don't mix flat and skeuomorphic at random). *Anti-pattern:*
**raw/undesigned default components** shipped as-is (the plain, "unfinished" look);
**emoji used as UI icons**; randomly mixed visual styles.

## D. Layout & responsive (priority 5 + 3 stability)

**UX-7 — Responsive layout, no horizontal scroll, stable during load.** Layouts adapt to
the viewport/size class (mobile-first breakpoints; Dynamic Type / font-scale respected);
content **never forces horizontal scroll** of the page, pinch-zoom is **not disabled**, and
fixed-pixel widths don't clip content on small screens. Reserve space for async content so
it doesn't **shift the layout** as it loads. *Anti-pattern:* **horizontal page scroll**;
fixed `px` widths that overflow; `user-scalable=no`; content that jumps as images/data
arrive (layout shift). Maps `WCAG 2.2 SC 1.4.10` (reflow), `SC 1.4.4` (resize text).

## E. Typography (priority 6)

**UX-8 — Legible type scale and rhythm.** Body text is **≥ 16px base** (never below ~12px
for any body copy), line-height is **~1.4–1.6** for body, and a limited, consistent type
scale is used; text honors the platform's Dynamic Type / font-scale setting. *Anti-pattern:*
sub-12px body text; cramped line-height; an unbounded pile of ad-hoc font sizes;
gray-on-gray low-legibility text (see also `UX-1`).

## F. Motion (priority 7)

**UX-9 — Purposeful motion, 150–300ms, honoring reduced-motion.** Transitions are
**150–300ms**, convey meaning/continuity (not decoration), and **respect the OS
reduced-motion setting** (SwiftUI `accessibilityReduceMotion`, Compose/Android
`Settings.Global.ANIMATOR_DURATION_SCALE`, web `prefers-reduced-motion`) by dropping or
minimizing non-essential animation. Prefer animating **transform/opacity** over
layout-affecting properties. *Anti-pattern:* **no reduced-motion support**; decorative-only
or janky animation; animating width/height/layout each frame. Maps `WCAG 2.2 SC 2.3.3`
(animation from interactions).

## G. Forms & feedback (priority 8)

**UX-10 — Persistent visible labels and inline, field-adjacent errors.** Inputs have a
**persistent visible label** (not a placeholder standing in for one), validation errors
appear **next to the offending field** with a clear message, and helper text guides input;
disclose complexity progressively rather than overwhelming up front. *Anti-pattern:*
**placeholder-only labels** (the label vanishes on input); errors shown only in a
top-of-form summary; a wall of fields with no grouping. Maps `WCAG 2.2 SC 3.3.1`
(error identification), `SC 3.3.2` (labels/instructions).

## H. Navigation (priority 9)

**UX-11 — Predictable navigation.** Back/dismiss behaves as the platform expects, primary
bottom/tab navigation stays **≤ 5 items**, and key destinations are deep-linkable/restorable.
*Anti-pattern:* overloaded or inconsistent navigation; a broken/surprising back stack;
destinations that can't be linked to or restored.

## I. Charts & data (priority 10)

**UX-12 — Readable, non-color-only data visualization.** Charts carry **legends, axis
labels, and tooltips/values**, use accessible palettes, and **never rely on color alone**
to convey meaning (add labels, patterns, or direct annotation). *Anti-pattern:*
unlabeled charts; **color as the sole encoding** of a category/series. Maps `WCAG 2.2
SC 1.4.1` (use of color).

---

## Severity guidance (for the design reviewer's verdict — Phase 2, Bisky)

| Severity | Use when a finding… |
| --- | --- |
| `critical` | Makes the UI **unusable for a class of users** — fails contrast/keyboard/labels (`UX-1`/`UX-2`), or targets so small/dense they can't be operated (`UX-3`). **Blocks merge.** |
| `high` | A clear, concrete defect against a baseline rule with a known fix — placeholder-only labels (`UX-10`), horizontal scroll / clipped content (`UX-7`), raw-default/emoji-icon UI (`UX-6`), no reduced-motion (`UX-9`), missing async feedback (`UX-4`). Blocks merge. |
| `medium` | A real quality gap that raises friction but doesn't block a user — inconsistent tokens (`UX-5`), off-scale typography (`UX-8`), overloaded navigation (`UX-11`). |
| `low` / `nit` | Polish / refinement; never blocks. |

Bisky reviews **only** the UI/design-quality surface — architecture findings are Sasuke's
lane (`UZF-{n}` / `SW-{n}` / `KT-{n}`), security is Tenma's (`SEC-{n}`). A concern with no
matching `UX-{n}` / `WCAG` / HIG-Material reference is a `bankai:handbook-question` scope-routed
to the canon lane (`bankai:agent/yamamoto`, `CON-37`), not an improvised policy.

## Reviewer discipline

- **Cite, never invent.** Every finding names a numbered `UX-{n}` rule (or a public
  `WCAG` / HIG / Material reference that maps more precisely). No un-cited design opinions —
  same bar as `SEC-{n}` and `UZF-{n}`.
- **A finding no rule covers → a scope-routed `bankai:handbook-question`** (a `UX-{n}` gap is
  canon, so `bankai:agent/yamamoto` — `CON-37`), not improvised policy. Search the repo's open
  handbook-questions first and comment on a match instead of opening a duplicate (`CON-11`).
- **Human preferences become rules, not one-off notes.** When the human states a
  design preference/practice-in-context on a PR (e.g. "prefer X over Y here"), that is
  surfaced as a `bankai-handbooks` issue to codify it into a `UX-{n}` rule (Bisky's
  *learn-from-the-human* duty, Phase 2) — so the same call is enforced deterministically
  from then on, rather than restated per PR.

---

## Growing this handbook — how to add a `UX-n` rule

This handbook is meant to **grow deliberately** as design taste is codified into durable,
citable rules. Adding or changing a `UX-{n}` rule is **never a hand-edit to this file**: it
goes through Naruto as a **G4 PR the human merges** (`CON-3` sole-author, `CON-7` G4), for
the same reason `SEC-{n}` and `UZF-{n}` do — a rule a reviewer will *cite* must be versioned,
reviewed, and adopted by consumers on a pinned tag, not silently mutated.

Use this whenever you want a new design standard enforced (or an existing one sharpened).

### 1. Propose the rule
- **Summon Ichigo** (`/ichigo`) in a local session and describe the standard you want
  enforced, **or** file an issue on `bankai-handbooks` describing the gap. If the
  proposal came from a design reviewer (Bisky, Phase 2) or a builder (Edward) hitting a
  gap, it arrives as a **`bankai:handbook-question`** labeled **`bankai:agent/yamamoto`** — a
  `UX-{n}` rule is canon, so it scope-routes to the canon lane (`CON-37` refines `CON-11`), and it
  lands in Ichigo's session warm-up inbox either way.
- Bring the *check* (what "good" is, with a concrete threshold) and the *anti-pattern*
  (what it forbids), and — ideally — a public reference (`WCAG` SC, HIG, Material) it maps
  to, so the rule can be cited precisely.

### 2. The canon lane turns it into a numbered rule
The canon lane — CI **Yamamoto**, or **Ichigo**'s Quincy nature locally (`CON-3`) — in a G4
PR, will:
- **Assign the next `UX-{n}`** in the relevant topical section (A–I above). Numbers are
  **append-only and stable** — never renumber or re-purpose a retired number; a retired rule
  is marked `RETIRED` in place.
- Write the rule in the house format: **stable ID · the check (with threshold) · the
  anti-pattern it forbids · a public reference where one maps** — so a reviewer can cite it.
- Set/adjust its **severity** in the *Severity guidance* table.

### 3. Where it lives + INDEX wiring
- The rule lives **in this file** (`handbooks/ux-baseline.md`), in its topical section.
- Naruto updates the **`UX-{n}` row + when-to-load cue** in
  [`handbooks/INDEX.md`](INDEX.md) and the family row in [`handbooks/README.md`](README.md)
  if the scope/enforcer statement changes. (These stay in sync with this file — that upkeep
  is Naruto's, `CON-3`.)

### 4. Source → mirror regeneration (`CON-13`)
- `handbooks/` in `bankai-handbooks` is the **single canonical source**. Reviewers resolve
  it **live** from a checkout at the consumer's pin, so a consumer picks up the new rule when
  it **repins** to the tag that ships it (below) — the same live-canon path
  `security-baseline.md` already follows.
- If/when the general-handbook set is folded into the generated per-surface mirror that
  build agents auto-load, that regeneration is mirror machinery (Hatsu/Nen); the *rule
  content* is authored here first, then mirrored — never authored in a mirror.

### 5. Version bump + consumer cascade (`CON-21` / `CON-22`)
- **Bump [`handbooks/VERSION`](VERSION)** in the same PR: a **new rule** or a wording
  clarification is a **MINOR** bump; a change to a rule's *meaning*, a removal, or a
  prefix restructure is a **MAJOR** bump (pre-`v1.0` carve-out per
  [`README.md`](README.md#versioning)). Agents stamp this token verbatim.
- This handbook is **not** a reusable workflow, so a new/changed rule does **not** trigger a
  `CON-22` reusable-workflow fan-out on its own. Consumers adopt the new rule when they
  next **repin their handbooks pin** to a `bankai-handbooks` tag containing it (an ordinary
  pin adoption recorded in the consumer registry); `CON-21` then cascades that repin down any live
  `integration/*` branches. Naruto records the affected-consumer determination in the PR.

### 6. It ships as a G4 PR the human merges
The canon lane opens the PR (branch `yamamoto/<issue>-<slug>` in CI, `ichigo/<slug>`
locally; `CON-20` real-commit authoring), drives it through the review gauntlet, and **the
human merges at G4** (`CON-7`). No agent merges its own PR. The PR body carries the affected
agents/repos list, migration notes, the version-tag proposal, and a `## How to verify`
section (`CON-17`).

> **In one line:** *summon Ichigo / file the gap → the canon lane assigns the next `UX-n`,
> writes check + anti-pattern + reference here, wires `INDEX.md`/`README.md`, bumps
> `VERSION`, records the consumer adoption → G4 PR you merge.*
