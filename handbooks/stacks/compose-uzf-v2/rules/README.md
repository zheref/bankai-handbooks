<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# `compose-uzf-v2` — canonical rule set

The **single source** for the Jetpack Compose + Hilt UZF stack's operational rules (`CON-13`) — the
Compose twin of `swiftui-tca-uzf-v2`. A consumer repo on this stack carries a **generated, pinned
mirror** of these files in each agent surface's rules location (`.claude/rules/` for Claude Code, and
the Codex / Cursor / Antigravity equivalents), never hand-authored, so every agent loads them
natively (history: `<reference-repo>#34`, Phase B). The condensed, ID'd form and the one `KT-{n}` registry live in
[`../architecture.md`](../architecture.md) and the cross-platform concepts in
[`../../../uzf-core.md`](../../../uzf-core.md) (`UZF-{n}`); these rule files are the operational
expansion. Repo-specific values are [`{{TOKEN}}` placeholders](placeholders.md).

| File | Concern |
|---|---|
| `00-architecture-overview` | 10-second layer/artifact/active-passive triage + rule index |
| `01-feature-and-events` | `Feature` identity, `onEvent`, `Outcome`, Event-case naming |
| `02-base-class` | UZF runtime/base-class contract (`Sink`, `Effect`, `Outcome` factories) |
| `03-state-shifters-selectors` | `val`-only `State`, `with…` Shifters, `select…` Selectors |
| `04-producers-effects-uieffects` | Producers, `FlowEffect`/`ThunkEffect`, `UiEffect` on `SharedFlow` |
| `05-page-and-screen` | Stateless `Page` / stateful `Screen` split |
| `06-services-and-data` | Service shape, Repository, Provider, Mapper boundary |
| `07-models-mocks-mappers` | Model shape, `Response`/`Entity`, Mapper, `mock*` fixtures |
| `08-hilt-and-di` | Hilt bootstrap, per-feature modules, bindings, injection |
| `09-testing` | JUnit5 + Turbine + Paparazzi minimums |
| `10-naming-and-layout` | File-suffix taxonomy + folder tree |
| `11-forbidden-patterns` | The coded reject list (`KT-{n}`) |
| `12-session-completion-checklist` | Definition-of-done gate |
| `13-feature-documentation` | `{{DOCS_ROOT}}` specs + mermaid |
| `14-ui-screenshots` | Sourcing + hosting Paparazzi snapshot PNGs as PR screenshots (UZF-26) |

## Reconciliation decisions (`<reference-repo>#34` Phase B, three-way: <product-repo-B> `.claude/rules/` ↔ `SYNTHESIS_JETPACK_COMPOSE_v2` ↔ this canon)

These files adopt <product-repo-B>'s `.claude/rules/` (the most complete operational source), reconciled
against the Compose synthesis and grounded on the already-ratified SwiftUI canon's house style.

| Topic | Decision |
|---|---|
| **No rule contradictions** | The source rules and the synthesis **agree on every actual coding rule**; the synthesis is a strict superset. Reconciliation was **additive** (canon absorbed the fuller synthesis detail the terse <product-repo-B> rules only implied). |
| **KT numbering** | The 14 files used **three conflicting local numberings** (see below). Resolved into one canonical `KT-1…KT-29` sequence. |
| **`Page` is NOT retired (cross-stack divergence)** | Unlike SwiftUI `SW-1` (where `…Page.swift` is retired in favor of `Screen`/`View`), the Compose canon **keeps** `…Page.kt` as the stateless renderer and `…Screen.kt` as the stateful wrapper (`KT-1`). Called out explicitly rather than mirrored. |
| **`…ViewModel` grandfathering** | Preserved from the synthesis: legacy `…ViewModel` names are renamed to `…Feature` on the next material edit, not en masse. |
| **`SharedFlow` buffer capacity** | Source says `extraBufferCapacity = 8`, synthesis says `≥ 1`, condensed `KT-9` says `= 1`. Reconciled to **`replay = 0, extraBufferCapacity ≥ 1, DROP_OLDEST`** — the invariant is `replay = 0` (never `Channel`, never `replay ≥ 1`); a small positive buffer (e.g. 8) is fine. Faithful to all three. |
| **Shifter strictness** | Kept Compose's stricter rule — every `copy` goes through a named `with…` Shifter; inline `copy(...)`/`updateState{}` in `reduce` is forbidden (`KT-6`). Did **not** import SwiftUI's inline-mutation carve-out. |
| **`UZF-9` loading model** | Compose **follows** `UZF-9`: the loading/loaded/failed lifecycle is modeled as a single sealed `LoadState` field (`Idle`/`Loading`/`Loaded`/`Failed`), never as parallel `isLoading`/`exception` optionals that could represent an invalid combination — a stack rule may tighten a `UZF-n` but never contradict it. |
| **`{{DI_FRAMEWORK}}`** | Retained for the framework name in prose (default `Hilt`, swappable to Koin/Dagger); concrete Hilt API symbols stay literal. See [`placeholders.md`](placeholders.md). |
| **Firestore/vendor generalization** | Backend-specific *implementation* names (Firestore, Supabase) were genericized to vendor-agnostic illustrations ("a realtime remote listener"). This did **not** extend to illustrative feature/screen names in code samples (`Now`, `Suggestions`, `UserProfile`, …) — those are ordinary examples, not repo config, and were intentionally left as-is; only product *config* is tokenized into `{{TOKEN}}`s. |

### KT-n numbering collision — how it was resolved

The reconcilers, running in parallel without a shared `architecture.md` KT index, produced
**incompatible numberings** across the 14 files:

1. The **file-00 overview scheme** (`KT-1…18`) — the architecture-overview master assigns each core and
   supporting rule a single clear meaning: `KT-1`=Page/Screen split, `KT-2`=Page nav-/DI-free, `KT-3`=Feature/base-class, `KT-4`=State, `KT-5`=`onEvent`+pure reduce, `KT-6`=Shifters, `KT-7`=Selectors, `KT-8`=Producers, `KT-9`=`UiEffect`, `KT-10`=Services, `KT-11`=Repositories, `KT-12`=Providers, `KT-13`=Preview, `KT-14`=Theme, `KT-15`=Navigation, `KT-16`=No-global-buses, `KT-17`=Hilt module, `KT-18`=Mocks.
2. A **09/10/12 cluster** that independently re-numbered the same concepts (`KT-1`=Feature, `KT-5`=Shifters, `KT-10`=Page/Screen, `KT-11`=Mocks/Preview, `KT-12`=Services, `KT-13`=Mapper/boundary, `KT-14`=Testing).
3. **Independent append blocks** minted by expansion files: `06` used `KT-15/16/17`, `07` used `KT-16…21`, `08` used `KT-30…34`, `13` used `KT-30/31`, and `11` re-declared a full **master `KT-1…32`** on entirely different meanings.

**Resolution.** Adopt the **file-00 overview scheme as the authoritative `KT-1…18` backbone** — it is the
master triage file and gives each core/supporting rule one clear meaning. Every rule a topic file had
re-numbered was re-pointed to the number `00` assigned that concept (Shifters→`KT-6`, Selectors→`KT-7`,
Producers→`KT-8`, Services→`KT-10`, Repositories→`KT-11`, Providers→`KT-12`, Preview→`KT-13`,
Theme→`KT-14`, Hilt module→`KT-17`, Mocks→`KT-18`, …). Genuinely new topic-specific rules that `00` does
**not** cover were appended sequentially as **`KT-19…KT-29`** (boundary/Mapper/Model, the testing stack,
Hilt bootstrap/binding/injection, structured concurrency, `LaunchedEffect` keys, runtime portability, and
the feature-doc rules). No rule was dropped, and no number maps to two rules. `architecture.md`
adopted **this** sequence as its append-only registry at `v0.13` and now holds it.

## KT-n rule registry

The registry is [`../architecture.md` → *KT-n rule registry (canonical)*](../architecture.md#kt-n-rule-registry-canonical):
the stack's one append-only `KT-{n}` list, `KT-1`…`KT-29`, with each rule's text and its
`UZF-{n}` parent in its section heading. These rule files cite it and mint no id. Until `v0.12`
the list was a table in this file and `architecture.md`'s own bold rules used an older numbering;
at `v0.13` the list moved there unchanged, and its numbering note maps the old ids
(zheref/bankai-handbooks#11).

## Shared-UZF ↔ Compose mapping

Every `KT-n` in the registry tightens a cross-platform `UZF-n` (from [`uzf-core.md`](../../../uzf-core.md))
except the `KT`-only rules, which encode stack mechanics with no cross-platform parent.

| Cross-platform (`UZF-n`) | Compose tightening (`KT-n`) |
|---|---|
| UZF-1 Feature is the funnel | KT-3 |
| UZF-2 Event/action naming; single entry | KT-5 |
| UZF-3 Throwables via `Result` → Exception | KT-8, KT-20 |
| UZF-4 Passive renderer purity | KT-1, KT-2, KT-9, KT-14, KT-15 |
| UZF-6 Co-location / runtime portability | KT-28 |
| UZF-7 Active/passive split | KT-1 |
| UZF-8 No wire types in State | KT-4, KT-21 |
| UZF-9 Coherent lifecycle fields | KT-4 |
| UZF-10 Shifters | KT-6 |
| UZF-11 Selectors | KT-7 |
| UZF-12/13 Reducer purity, event loop | KT-5, KT-8 |
| UZF-14 Effects never throw | KT-8 |
| UZF-15 Effects via a Producer | KT-8 |
| UZF-16 External systems behind a DI'd Service + stub | KT-10, KT-11, KT-12, KT-23, KT-24 |
| UZF-17 Wire types cross via a Mapper | KT-19, KT-20 |
| UZF-18/19/20 Test minimums / coverage floor | KT-13, KT-18, KT-22 |
| UZF-21 Feature spec docs | KT-29 |
| UZF-23 One PR = code + docs | KT-29 |
| UZF-26 Previews mirror snapshots | KT-13 |
| **Compose-only (no `UZF` parent)** | KT-16, KT-17, KT-25, KT-26, KT-27 |

## Open items / follow-ups (Naruto G4)

1. **Resolved at `v0.13`.** `architecture.md` holds the `KT-1…29` sequence as the one append-only
   registry, superseding the conflicting local numberings (zheref/bankai-handbooks#11).
2. **UZF re-tagging.** Files 00/01 deliberately did **not** fabricate `UZF-n` numbers for
   single-entry-point / pure-reduce / standalone Shifters/Selectors where they couldn't verify a
   canonical number against `uzf-core.md`; those got `KT` codes. A pass with `uzf-core.md` in hand may
   re-tag some `KT` rules as "implements UZF-n" where a shared number exists.
3. **`{{DI_FRAMEWORK}}` prose normalization** — inline-Hilt prose in 00/02/05/08/10/11 should be
   switched to the token (or the token dropped and all references made literal — pick one).
4. **`placeholders.md` registration** — this file is the first placeholder schema for the stack; the
   15 tokens above must be wired into each adopting repo's `canon-values` binding before the mirror is
   generated (Phase A pattern).
