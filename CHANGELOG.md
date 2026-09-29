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
- The handbooks, the constitution and the shared agent conventions now live here,
  as the single canonical source. Consumers resolve canon from a tag of this
  repository rather than from the frozen reference implementation.
- `CON-13` re-stated: consumers keep a generated, pinned mirror, rendered from a
  tag of this repository by the Hatsu and Nen planes into every agent surface's
  own rules location, with a drift check. The mirror was re-pointed, not removed.
- The machinery self-review stack is now `bankai-machinery`. Its `BC-` rule-ID
  prefix is unchanged, so existing citations keep resolving.
- `CON-51` added: gates, no green-at-any-cost, spec as source of truth, and
  commit attribution restricted to the canonical persona trailers.
- The shared agent conventions are carried as `CONVENTIONS.md` beside the
  constitution, and the eleven handbook passages that cited them now resolve.