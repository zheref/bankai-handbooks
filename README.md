# bankai-handbooks

The **single canonical source** of the Bankai handbooks — the numbered, citable canon every
Bankai-consuming repository is built and reviewed against (`CON-13`).

| Family | Where | Prefix |
|---|---|---|
| Governance constitution | [`CONSTITUTION.md`](CONSTITUTION.md) | `CON-{n}` |
| UZF cross-platform architecture | [`handbooks/uzf-core.md`](handbooks/uzf-core.md) | `UZF-{n}` |
| Security baseline | [`handbooks/security-baseline.md`](handbooks/security-baseline.md) | `SEC-{n}` |
| UX baseline | [`handbooks/ux-baseline.md`](handbooks/ux-baseline.md) | `UX-{n}` |
| Release policy | [`handbooks/release-policy.md`](handbooks/release-policy.md) | `REL-{n}` |
| Quality baseline | [`handbooks/quality-baseline.md`](handbooks/quality-baseline.md) | `QA-{n}` |
| SwiftUI + TCA stack | [`handbooks/stacks/swiftui-tca-uzf-v2/`](handbooks/stacks/swiftui-tca-uzf-v2/) | `SW-{n}` |
| Jetpack Compose stack | [`handbooks/stacks/compose-uzf-v2/`](handbooks/stacks/compose-uzf-v2/) | `KT-{n}` |
| React + Redux Toolkit stack | [`handbooks/stacks/react-uzf-v1/`](handbooks/stacks/react-uzf-v1/) | `RC-{n}` |
| Bankai machinery (self-review) | [`handbooks/stacks/bankai-machinery/`](handbooks/stacks/bankai-machinery/) | `BC-{n}` |
| Shared agent conventions | [`CONVENTIONS.md`](CONVENTIONS.md) | — (no rule ids; the output shape every agent follows) |

Start at [`handbooks/INDEX.md`](handbooks/INDEX.md) — the manifest that says which handbooks load
for a repo — and [`handbooks/stack-matrix.md`](handbooks/stack-matrix.md), the scenario registry.
The handbook set version is [`handbooks/VERSION`](handbooks/VERSION).

## Where this sits

Bankai is four components. **Hatsu** ([`zheref/hatsu`](https://github.com/zheref/hatsu)) is the
local agentic plane; **Nen** ([`zheref/nen`](https://github.com/zheref/nen)) is the deterministic
CLI; **Akatsuki** is the CI delivery/governance plane; **this repository** is the canon all three
cite and every consumer mirrors. A consumer never authors canon — it carries a generated, pinned,
per-surface mirror rendered from a **tag** of this repository by Hatsu/Nen, with a drift check
([`handbooks/README.md` → *How canon reaches a consumer*](handbooks/README.md#how-canon-reaches-a-consumer-con-13)).

## Working here

- [`AGENTS.md`](AGENTS.md) is the contract for any agent (and human) editing canon here;
  [`.claude/rules/`](.claude/rules/) holds the depth. Every change is a PR the human merges (G4).
- Rule ids are append-only and stable; `handbooks/VERSION` bumps with every change.
- This repository is public by design and **names no private repository** —
  [`docs/PUBLIC-REDACTION.md`](docs/PUBLIC-REDACTION.md).
- Where everything came from, what was renamed, reconciled and left behind:
  [`MIGRATION.md`](MIGRATION.md).
- License: [MIT](LICENSE), matching the rest of the estate.
