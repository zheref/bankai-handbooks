# Stack scenario: `bankai-machinery` (framework machinery self-review)

| Facet | Value |
| --- | --- |
| Platform | Bankai's own machinery repos — the CI delivery/governance plane, the deterministic CLI, the local agent plugin, and any scaffolder (the frozen reference implementation was the first) |
| Language | GitHub Actions YAML (reusable workflows + callers), TypeScript (the default for new logic, `BC-11`), shell (glue and bootstrap, bats), Python (frozen, pytest) |
| UI architecture | **None** — this scenario generates **no product code**. It is a self-review rule set only. |
| Backend | N/A |
| Testing | `make lint && make test` (shellcheck + bats + jq schema check); `pytest` for Python machinery cores. (Workflow-syntax linting, e.g. `actionlint`, is recommended but not yet wired.) |
| Reference implementation | the frozen, private reference implementation (`<reference-repo>`), which self-hosted the review pair on its own machinery PRs |
| Scaffold generation scenario | N/A (machinery, not a generated product stack) |

## Handbooks a review on this scenario loads

- General: [`uzf-core.md`](../../uzf-core.md) (`UZF-{n}`, process/testing/docs facets),
  [`security-baseline.md`](../../security-baseline.md) (`SEC-{n}` — the primary family;
  CI is a security surface),
  [`release-policy.md`](../../release-policy.md) (`REL-{n}`)
- Stack: [`architecture.md`](architecture.md) (`BC-{n}`)

## What this scenario is (and is not)

`bankai-machinery` is the **self-review** scenario: the framework runs its own review pair
(Sasuke + Tenma) on its own **machinery** PRs — reusable workflows, `bankai.yml`
callers, guard scripts, scaffolder plumbing, dependency/toolchain upkeep. Only
**machinery** is in scope, and only **Kisuke** (Scientist · Platform DevEx) is wired
to a CI builder for it.

It is **not** a product stack: no store, no View, no snapshots, no device runner. And
it is **not** the review target for **spec/policy** — `CONSTITUTION.md`, `handbooks/`,
the Stack Matrix, `schemas/` content, and `agents/*/AGENT.md` are Naruto's, authored
interactively and merged by the human at G4 (`CON-3`/`CON-7`), never wired to a
builder. See [`../../stack-matrix.md`](../../stack-matrix.md).

## Name and prefix

Until handbook set v0.6 this scenario's id was the reference implementation's own repository
name (`<reference-repo>`, now frozen), so the scenario was renamed `bankai-machinery` when the
handbooks moved to `bankai-handbooks`. **The `BC-` rule prefix
is deliberately unchanged** — every `BC-{n}` citation across the estate stays valid, and
rule numbers stay append-only. Rules that record the reference implementation's own
history (the frozen Python scripts and release lines in `BC-11`/`BC-12`) are carried as
written; they describe that implementation and are cited as precedent.
