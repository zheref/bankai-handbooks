<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# 15 · Database migrations → `UZF-25`

Database-migration canon is **not** stack-specific — it lives in the cross-platform handbook as
**`UZF-25`** (`handbooks/uzf-core.md`): migrations authored as idempotent files, reviewed **as
files** (no builder/reviewer agent holds DB credentials), applied by the deterministic
`db-migrate` CI pipeline (per-PR preview branch for G2, prod-on-merge with back-query).

A product family's shared schema has a **single owning repo** (typically its first client until
a dedicated backend repo takes over) — other-platform apps are **clients**, never co-owners of a
second migration copy (`handbooks/stacks/*/README.md`, `handbooks/stack-matrix.md`).

Change this rule by editing `UZF-25` in `bankai-handbooks` (G4), never here.
