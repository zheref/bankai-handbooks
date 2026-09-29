# Changelog

Every released version of the handbooks, newest first. Sections are collated
from `changelog.d/` fragments at release time (`CON-33(b)`); they are never
hand-written.

The version this file records is the **handbooks set version**, carried in
`handbooks/VERSION` and pinned by consumers. It moves when the canon moves, not
when the repository is merely edited.

### Unreleased
_(nothing awaiting release.)_

### v0.6.0 — the canonical home
- The handbooks, the constitution and the shared agent conventions now live here.
  This repository is the canonical source they are authored in and tagged from.
- `CON-13` re-stated: the doctrine now names this repository as that source, and
  describes a consumer's mirror as generated and pinned from a tag of it, per
  agent surface, with a drift check. **The doctrine is what shipped. No consumer
  resolves canon from here yet, and the per-surface rendering is not built** —
  both are separate efforts, and the planes still point at the frozen reference
  implementation until they land.
- The machinery self-review stack is now `bankai-machinery`. Its `BC-` rule-ID
  prefix is unchanged, so existing citations keep resolving.
- `CON-51` added: gates, no green-at-any-cost, spec as source of truth, and
  commit attribution restricted to the canonical persona trailers.
- The shared agent conventions are carried as `CONVENTIONS.md` beside the
  constitution, and the eleven handbook passages that cited them now resolve.
- Release machinery stood up, because the repository was seeded by direct push
  and carried none: `nen/labels.json`, `nen/gates.json` and `nen/repos.json` (the
  taxonomy, the reviewer vocabulary, and this repository registered as canon
  role), this changelog, and the `changelog.d/` fragment directory.
- The four `bankai:severity/*` bands are declared and provisioned. They are
  load-bearing rather than decorative: the release preflight queries
  `bankai:severity/critical` by name, and an unprovisioned label returns zero
  matches silently — so the gate reads "none open" because nothing *could*
  match. Hex values are taken from the estate's existing registry (`CON-14`).
- CI gates what this repository can silently get wrong, since there is no build:
  redaction (no private slug, link or linked object id), link resolution, and
  `nen schema check`. The redaction patterns are shape-based, so no private name
  is ever spelled here in order to find one.