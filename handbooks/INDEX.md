# Handbooks — INDEX (manifest)

The map agents use to load the *right* handbook and no more. The canon lane keeps it in sync
with the actual contents of `handbooks/`. Resolution is `CON-13`: **this repository —
`zheref/bankai-handbooks` — is the single canonical source** of every handbook and rule family.
A consumer repo never authors canon of its own. It carries a **generated, pinned mirror** of its
stack-relevant canon, rendered into the rules location of **each agent surface it uses** (Claude
Code `.claude/rules/`, Codex `AGENTS.md`, Cursor `.cursor/rules/`, Antigravity `.agents/rules/`,
…) from a **tag** of this repository by Hatsu/Nen, with a drift check that fails when a mirror is
hand-edited or lags its pin. Whether an agent resolves the set live (`nen canon resolve` against a
checkout of this repository) or reads its repo's mirror, it reads **this** canon — one source, no
product-authored canon, no fallback source. Mechanics:
[`README.md` → *How canon reaches a consumer*](README.md#how-canon-reaches-a-consumer-con-13).

## Always load (general — apply to every scenario)

| File | Scope | Rule-ID prefix | When to load |
| --- | --- | --- | --- |
| [`uzf-core.md`](uzf-core.md) | UZF cross-platform architecture (store shape, action flow, effects, forbidden patterns) | `UZF-{n}` | Every build/review — the architecture canon |
| [`security-baseline.md`](security-baseline.md) | Data security, privacy, compliance, agent tool-use & untrusted content | `SEC-{n}` | Every security review (Tenma); any data/secret-handling work; any agent pairing web fetch/search with write-to-code tools (`SEC-15`) |
| [`ux-baseline.md`](ux-baseline.md) | UI/UX design-quality: accessibility, touch targets, tokens, typography, motion, layout, forms, navigation, data-viz | `UX-{n}` | Every build/review of user-visible UI — Edward builds against it (Phase 1a); the design reviewer (Bisky, Phase 2) cites it |
| [`release-policy.md`](release-policy.md) | Versioning, changelog, store submission | `REL-{n}` | Release work (Natsu); version decisions |
| [`quality-baseline.md`](quality-baseline.md) | Adversarial QA method, E2E tooling by scenario, performance budgets, process-machinery testing, the pre-release gate | `QA-{n}` | Pre-release quality verification (Ichigo — Hollow: local, on-demand, **advisory**, `QA-20`/`QA-21`); any adversarial/E2E or performance test authoring. The CI gate (Rukia) is future work |

## Load exactly ONE stack handbook (per repo's scenario)

Selected by the repo's `bankai_scenario` (see [`stack-matrix.md`](stack-matrix.md)). Never
load a stack folder other than the repo's own.

| Scenario | File | Rule-ID prefix | Platform · UI |
| --- | --- | --- | --- |
| `swiftui-tca-uzf-v2` | [`stacks/swiftui-tca-uzf-v2/architecture.md`](stacks/swiftui-tca-uzf-v2/architecture.md) | `SW-{n}` | iOS/macOS · SwiftUI + TCA |
| `compose-uzf-v2` | [`stacks/compose-uzf-v2/architecture.md`](stacks/compose-uzf-v2/architecture.md) | `KT-{n}` | Android · Compose + Hilt |
| `react-uzf-v1` | [`stacks/react-uzf-v1/architecture.md`](stacks/react-uzf-v1/architecture.md) | `RC-{n}` | Web + Mobile · Next.js/Expo + RTK |
| `bankai-machinery` | [`stacks/bankai-machinery/architecture.md`](stacks/bankai-machinery/architecture.md) | `BC-{n}` | Bankai machinery (CI plane, CLI, local plugin) · self-review, no product code. **Renamed at v0.6** (its former id was the reference implementation's own repository name); the `BC-` prefix is kept so every existing citation stays valid. |

## Catalog & meta

| File | Purpose |
| --- | --- |
| [`stack-matrix.md`](stack-matrix.md) | Registry of supported scenarios → which handbooks govern each; how `bankai_scenario` resolves |
| [`README.md`](README.md) | Handbook set overview |
| [`VERSION`](VERSION) | Handbook set version |
| [`../CONVENTIONS.md`](../CONVENTIONS.md) | The shared agent conventions every agent output follows (header, machine stamp, `Verdict:` line, object notation, human-glance fields, delivery summary, verification plan, discipline). Not a rule family and not part of the always-load set; cited by `CON-3`, `CON-17`, `CON-32` and the stack rules |

> Adding a scenario, handbook, or rule family is a canon-lane PR to this repository, merged by
> the human (G4): add the file, register it here and in `stack-matrix.md`, bump `VERSION`, and
> note the migration for consuming repos.
