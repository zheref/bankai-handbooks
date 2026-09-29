# MIGRATION.md — provenance of this repository

Created **2026-09-28** as step 1 of the approved Bankai migration plan: the handbooks moved out of
the frozen, private reference implementation and the canon prose out of the private scaffolding
repository into one public canon repository, `zheref/bankai-handbooks`. **The git history is fresh
by design** — preserving the sources' history would have preserved every private name in it. This
file is the record of what came from where, what was renamed, what was reconciled, and what was
deliberately left behind. It is a record, not a changelog: later canon changes go through PRs and
`handbooks/VERSION`, not here.

Private repositories are named by placeholder throughout ([`docs/PUBLIC-REDACTION.md`](docs/PUBLIC-REDACTION.md)).

## 1. Sources

| Source | Ref taken | What was taken | Landed as |
|---|---|---|---|
| `<reference-repo>` — the frozen, private reference implementation | tag **`v0.11.3`** = commit `2269fe723e355dc69bf535ab40f22556e4fe4081` (2026-09-01). Its `handbooks/` tree (`7b4d5ad207aa52d573c62b3a6de2d60e620b5c90`) and `CONSTITUTION.md` blob (`9ac466249d31995fe0290dc3a7b62633bb38d5dc`) are byte-identical on its `main` (`345c79b2ab316f896e7415fc38734cdd9cd59d0a`), so the tag and the head are the same content. | `handbooks/` — 68 files: 5 always-load handbooks, 4 stack folders, `INDEX.md`, `README.md`, `stack-matrix.md`, `VERSION` (`v0.5`) | `handbooks/` (68 files, one folder renamed; `VERSION` → `v0.6`) |
| same | same | `CONSTITUTION.md` — 2 831 lines, `CON-1`…`CON-50` | `CONSTITUTION.md` — redacted, `CON-13` rewritten, provenance preamble and § 6 / `CON-51` appended |
| `<scaffold-repo>` — the private scaffolding repository | commit `46715239d19b38150f4db4f4a8d49e0d99925142` (2026-08-03), local checkout | `constitution.md` — the UZF architecture constitution (Articles 0–VIII, ~15 KB) | **not copied**; reconciled into `CONSTITUTION.md` § 6 and `handbooks/uzf-core.md` (§ 6 below records every divergence) |
| same | same | `agents/_conventions.md` — the shared agent conventions (665 lines) | `CONVENTIONS.md` at the repository root (ruled 2026-09-28 — see § 4a), redacted, machinery named by role, a precedence note against `CON-51(c)` |
| `zheref/hatsu` (public) | `ccb91fff616bb5ae79f065327a224870d3f3c954` (2026-09-23) | `docs/PUBLIC-REDACTION.md` — the redaction legend | `docs/PUBLIC-REDACTION.md`, adapted for this repository and extended (`RS-`, the Acme convention) |
| a consumer's `.claude/canon-values.yml` (private) | — | the shape of the `{{TOKEN}}` → value binding | nothing copied; the convention is described in `.claude/rules/03-tokens.md` with fictional values |

## 2. Inventory as migrated

Migrated files (from `<reference-repo>`; every one edited at least for redaction):

- `CONSTITUTION.md`
- `CONVENTIONS.md`
- `handbooks/INDEX.md`
- `handbooks/README.md`
- `handbooks/VERSION`
- `handbooks/quality-baseline.md`
- `handbooks/release-policy.md`
- `handbooks/security-baseline.md`
- `handbooks/stack-matrix.md`
- `handbooks/stacks/bankai-machinery/README.md`
- `handbooks/stacks/bankai-machinery/architecture.md`
- `handbooks/stacks/compose-uzf-v2/README.md`
- `handbooks/stacks/compose-uzf-v2/architecture.md`
- `handbooks/stacks/compose-uzf-v2/rules/00-architecture-overview.md`
- `handbooks/stacks/compose-uzf-v2/rules/01-feature-and-events.md`
- `handbooks/stacks/compose-uzf-v2/rules/02-base-class.md`
- `handbooks/stacks/compose-uzf-v2/rules/03-state-shifters-selectors.md`
- `handbooks/stacks/compose-uzf-v2/rules/04-producers-effects-uieffects.md`
- `handbooks/stacks/compose-uzf-v2/rules/05-page-and-screen.md`
- `handbooks/stacks/compose-uzf-v2/rules/06-services-and-data.md`
- `handbooks/stacks/compose-uzf-v2/rules/07-models-mocks-mappers.md`
- `handbooks/stacks/compose-uzf-v2/rules/08-hilt-and-di.md`
- `handbooks/stacks/compose-uzf-v2/rules/09-testing.md`
- `handbooks/stacks/compose-uzf-v2/rules/10-naming-and-layout.md`
- `handbooks/stacks/compose-uzf-v2/rules/11-forbidden-patterns.md`
- `handbooks/stacks/compose-uzf-v2/rules/12-session-completion-checklist.md`
- `handbooks/stacks/compose-uzf-v2/rules/13-feature-documentation.md`
- `handbooks/stacks/compose-uzf-v2/rules/14-ui-screenshots.md`
- `handbooks/stacks/compose-uzf-v2/rules/README.md`
- `handbooks/stacks/compose-uzf-v2/rules/placeholders.md`
- `handbooks/stacks/react-uzf-v1/architecture.md`
- `handbooks/stacks/react-uzf-v1/rules/00-architecture-overview.md`
- `handbooks/stacks/react-uzf-v1/rules/01-feature-and-events.md`
- `handbooks/stacks/react-uzf-v1/rules/02-store-setup.md`
- `handbooks/stacks/react-uzf-v1/rules/03-state-shifters-selectors.md`
- `handbooks/stacks/react-uzf-v1/rules/04-producers-effects.md`
- `handbooks/stacks/react-uzf-v1/rules/05-page-and-screen.md`
- `handbooks/stacks/react-uzf-v1/rules/06-services-and-data.md`
- `handbooks/stacks/react-uzf-v1/rules/07-models-mocks-mappers.md`
- `handbooks/stacks/react-uzf-v1/rules/08-monorepo-and-sharing.md`
- `handbooks/stacks/react-uzf-v1/rules/09-testing.md`
- `handbooks/stacks/react-uzf-v1/rules/10-naming-and-layout.md`
- `handbooks/stacks/react-uzf-v1/rules/11-forbidden-patterns.md`
- `handbooks/stacks/react-uzf-v1/rules/12-session-completion-checklist.md`
- `handbooks/stacks/react-uzf-v1/rules/13-feature-documentation.md`
- `handbooks/stacks/react-uzf-v1/rules/README.md`
- `handbooks/stacks/react-uzf-v1/rules/placeholders.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/README.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/architecture.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/00-overview.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/01-folder-layout.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/02-naming.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/03-tca-idioms.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/04-services-dependencies.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/05-state-shifters-selectors.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/06-producers-effects.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/07-testing.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/08-anti-patterns.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/09-design-system.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/10-migration.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/11-feature-documentation.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/12-session-completion-checklist.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/13-build-execution.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/14-github-version-control.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/15-database-migrations.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/16-ui-screenshots.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/README.md`
- `handbooks/stacks/swiftui-tca-uzf-v2/rules/placeholders.md`
- `handbooks/ux-baseline.md`
- `handbooks/uzf-core.md`

Authored for this repository:

- `LICENSE` (MIT, the estate's copyright line)
- `.claude/rules/01-canon-authoring.md`
- `.claude/rules/02-redaction.md`
- `.claude/rules/03-tokens.md`
- `.claude/rules/04-commits-and-prs.md`
- `.gitignore`
- `AGENTS.md`
- `CLAUDE.md`
- `MIGRATION.md`
- `README.md`
- `docs/PUBLIC-REDACTION.md`

## 3. Renames

| Before | After | Why |
|---|---|---|
| the machinery stack's directory and scenario id — both were the reference implementation's own repository name (`<reference-repo>`) | `handbooks/stacks/bankai-machinery/`, scenario id **`bankai-machinery`** — rows in `INDEX.md`, `stack-matrix.md`, `README.md`, `quality-baseline.md`; the stack's own `README.md`/`architecture.md` | The scenario is the machinery self-review scenario; its old name was the name of one repository, now frozen. **The `BC-` rule-id prefix is kept** so every existing `BC-{n}` citation across the estate stays valid; stated in `INDEX.md`, `stack-matrix.md`, the stack `README.md` § *Name and prefix* and `handbooks/README.md`. |
| `stack-matrix.md` column *Reference repo* | *Live consumer today* | The column named product repositories; it now describes them (private, registry-recorded) |
| `stack-matrix.md` § *Relationship to `<scaffold-repo>`* | § *Relationship to the scaffolding tooling* | The scaffolder is a private repo and may be replaced; the doctrine is about the tooling role |
| stack `README.md` rows *Reference repo* / *`<scaffold-repo>` analogue* | *Reference implementation* / *Scaffold generation scenario* | same |
| `handbooks/VERSION` `v0.5` | **`v0.6`** | MINOR under the pre-1.0 carve-out: a stack renamed, doctrine re-pointed, examples tokenised, one clause appended; no rule's meaning changed. Recorded in `handbooks/README.md` § *Versioning*. |
| the generated-file marker on every `stacks/*/rules/*.md`, which named the reference repository as the canonical source (two react rule files never carried one) | `<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->` | the marker consumers' drift checks key on now names the real source |

## 4. Rewrites (doctrine)

- **`CON-13`** (`CONSTITUTION.md`) — was: *the reference repo's `handbooks/` is the single canonical
  source; CI reads it live from a pinned checkout, product repos carry a `sync-canon`-generated
  `.claude/rules/` mirror (Claude Code only)*. Now: **`zheref/bankai-handbooks` is the single
  canonical source; consumers keep a generated, pinned mirror — sourced from a tag of this
  repository by Hatsu/Nen (`nen canon resolve`, `nen canon mirror generate`, `nen canon mirror
  check`), rendered into the rules location of every agent surface the consumer uses (Claude Code
  `.claude/rules/`, Codex `AGENTS.md`, Cursor `.cursor/rules/`, Antigravity `.agents/rules/`, and
  any added later)**, with a drift check. The mirror concept is kept and re-pointed, not deleted.
  The old "Transition" bullet became a "History" bullet; the pin-discipline bullet is unchanged.
- **`handbooks/INDEX.md`** header, **`handbooks/stack-matrix.md`** § *How resolution works* and the
  closing note, **`handbooks/README.md`** (new § *How canon reaches a consumer (`CON-13`)*, the
  version note, *Adding a stack* step 3), **`quality-baseline.md`** § 4/§ 5 and
  **`ux-baseline.md`** § 4/§ 5 (the "source → mirror" and "repin" steps), every stack
  `rules/README.md` first paragraph, every `rules/placeholders.md` boilerplate, `00-overview.md` /
  `00-architecture-overview.md` hard-"never" 13/14, the swiftui `architecture.md` header note —
  all re-pointed from the reference repo and from `sync-canon` / `bankai_core_ref` to
  `bankai-handbooks`, the Nen verbs, and the per-surface mirror. The per-surface sync itself is
  **not built here**; the doctrine is written so Nen can implement it without another canon change.
- **`stacks/bankai-machinery/`** — reframed from "the reference repo reviewing itself" to "the
  Bankai machinery repositories (CI plane, CLI, local plugin, scaffolder) reviewing their own
  machinery"; `BC-1`…`BC-12` carried verbatim apart from redaction. `BC-11`/`BC-12` record facts
  about the reference implementation (its frozen Python scripts, its `v0.11.x`/`v0.12.0` release
  lines); they are carried as written and flagged in § 8.
- **Manifest gap closed:** `handbooks/README.md`'s family table never listed `react-uzf-v1`
  although `INDEX.md` did; a row was added and the "never in scope together" sentence extended to
  all four stack prefixes.

## 4a. The shared agent conventions — placement and split

`agents/_conventions.md` was first left behind under the plan's `agents/` exclusion and reported
(§ 8.3). The maintainer ruled on 2026-09-28 that it belongs with the handbooks, so it was brought
across from the same tag.

- **Placement: repository root, as `CONVENTIONS.md`, beside `CONSTITUTION.md`.** It applies to
  every agent on every stack and carries no rule-id family, so it is not one of the handbooks
  `INDEX.md` loads (a row in *Catalog & meta* points at it); the constitution calls it the one
  shared edge read by every agent (`CON-3`), and eleven handbook passages cite it as "the shared
  agent conventions" — those now resolve to `CONVENTIONS.md` (links where the citing file is not
  mirrored, the plain name where it is a mirrored stack rule file).
- **Split: prose stayed, machinery was never inside.** The file is conventions end to end; no
  section was cut. What it *describes* and is machinery — the colour registry, the label registry,
  the consumer registry, the PR/issue templates, the readiness gate, the gate-stop and board
  helpers, the prompt renderer — stays with the planes (Nen: `nen/colors.yml`, `nen/labels.json`,
  `nen/repos.json`, `nen pr ready`; Hatsu: templates and the stop/board skills) and is named in the
  text by role, with the reference implementation's script names kept where the sentence is
  about that implementation.
- **Reconciled, not rewritten:** § *Commit attribution* names the reference implementation's
  `Bankai-Agent:` / `Bankai-Run:` trailers and bot identities; a precedence note at its head and in
  the preamble makes `CON-51(c)` govern on the successor planes (`Hatsu-Agent:` / `Akatsuki-Agent:`,
  never AI attribution). The object-notation examples use the placeholder product codes.

## 5. Tokenisation — repo canon out of stack canon

Handbooks are stack canon. Every example value that named the reference products' targets,
modules, schemes, package roots, asset repositories, build-log path, timezone or maintainer login
was replaced by a fictional product, **Acme** (`Acme`, `Acme for Mac`, `AcmeCore`, `AcmeUI`,
`AcmeTests`, `Acme.xcodeproj`, `Acme/Application`, `com.acme.app`, `acme/acme-ios`,
`acme/acme-assets`, `Acme/pr-<n>/<scene>.png`, `/tmp/acme-build.log`, `UTC`, `octocat`). The
"`<product> example`" column and bullet labels became "Illustrative example". The real values live
only in each consumer's private `canon-values` binding.

Product-specific **worked examples** inside rule text were generalised rather than placeheld:
the swiftui `10-migration.md` lint allow-list (named product features), `14-github-version-control.md`
(specific PR numbers, epic branch numbers, a workflow-tag repin), `07-testing.md` (the concrete
assets repo), `13-build-execution.md` (attribution of the hung-toolchain canon), the shared-schema
ownership rows in `stack-matrix.md`, both native stack `README.md`s and `15-database-migrations.md`
(a named backend-extraction issue and a named product schema), and `uzf-core.md`'s `UZF-25`
incident (kept as a dated fact, unattributed). Ordinary sample names in code (`UserProfile`,
`Endeavor`, `Now`, `Suggestions`, `ada@example.com`) were left: they are illustrative vocabulary,
not repository names.

## 6. Constitution reconciliation

The two "constitutions" were different documents: the reference implementation's is the Bankai
**governance** constitution (`CON-1`…`CON-50`: planes, gates, lanes, review and merge discipline),
the scaffold's is the **UZF architecture** constitution (the loop, the building blocks, the
invariants, naming, testing, a cross-platform mapping, and one human-in-the-loop article). The
governance text is the base, because its `CON-{n}` ids are cited across the estate. The
architecture articles were checked clause by clause against `handbooks/uzf-core.md` and the stack
handbooks — the newer canon, which already codifies them as `UZF-1`…`UZF-27` — and every divergence
was resolved **toward the handbooks**. The one governance article was folded in as `CON-51`.

| Topic | Scaffold constitution | Reference constitution / handbooks | Resolution |
|---|---|---|---|
| Expansion of "UZF" | *Unidirectional **Zheref** Flow* (the maintainer's handle) | *Unidirectional **Z** Flow* (`uzf-core.md`) | **Z Flow.** The handbooks' own expansion; the scaffold's is recorded here only. |
| Authority when sources disagree (Art. 0) | *Canonical reference order*: the iOS product implementation wins, then the Android one, then the framework-agnostic spec | `CON-13`: the handbook is canon; a product repo authors none | **`CON-13`.** Inverted deliberately: an implementation that disagrees with its handbook is a finding (or a `bankai:handbook-question` if the handbook is wrong), never a source that silently wins. Recorded in `CON-51`'s note. |
| Where architecture law lives | in the constitution (Arts. I–VII) | in `uzf-core.md` (`UZF-{n}`) + stack handbooks | **Handbooks.** The constitution stays governance; § 6 points at the `UZF-` family instead of restating it. |
| Shifters (Art. II/III/V) | *always return a new State*; prefixes `with…` / `as…` | `UZF-10`: `with…` / `as…` / `apply…`, purity; stack-bound form — `SW-8` (`inout` `apply…`), `KT-5` (`copy` `with…`), `RC` (`with…`) | **`UZF-10`.** Immutability-by-copy is one stack's binding, not the core rule. |
| Selector naming (Art. V) | prefix `select…` for every stack | `UZF-11` names the role; `SW-9` `…Selector` suffix, `KT-6` `select…(state)`, `RC` `createSelector` | **Per-stack binding.** No core-level prefix. |
| Effect resolution events (Art. I/III/V) | `on…Completed` **and** `on…Failed` | `UZF-3`: one `on…Completed(Result)`; separate success/failure events forbidden | **`UZF-3`.** |
| Renderer name (Art. II) | `View` on Apple, `Page` on Kotlin/web | `SW-1` retires `Page` on Apple; `KT-1` keeps `Page` on Compose; `RC` uses `Page` | **No conflict** — the scaffold already said per-platform; recorded. |
| `Provider` readable by a reducer | yes (synchronous, side-effect-free) | `UZF-13` says the same | agree |
| `Outcome` as the reducer's return | four cases via factories | `UZF-12` says the same | agree |
| `Task` owned by a `Repository`; `Context` for cross-feature state | Art. II cross-cutting | `UZF-16`, `UZF-6` | agree |
| `Component` is domain-less and outside UZF; no suffix | Art. II | `UZF-5` | agree |
| Boundaries — no cross-feature imports; shared logic in a core module (Art. IV) | yes | `UZF-6` | agree |
| Screen/View (wrapper/renderer) split (Art. II) | yes | `UZF-4` | agree |
| Testing minimums (Art. VI) | ≥3 per reducer arm / selector / shifter / producer; ≥3 previews; ≥3 snapshots; ≥7 mocks | `UZF-18`: the same, plus Mapper and the 3/1/3 mock split; `UZF-19` coverage floor | **`UZF-18`/`UZF-19`** (a superset). |
| `Theme` as a UZF artifact (Art. II) | listed | no `UZF-` rule; bound per stack (`SW-5` / design system, `KT-14`) | **Stack-level.** No core rule added; the gap is noted for the canon lane. |
| Terminology — `Event` ≙ `Action` ≙ `Intent` | Art. VII note | `UZF-27` glossary | agree |
| Cross-platform mapping table incl. Flutter + Bloc (Art. VII) | normative table | `uzf-core.md` informative table, Flutter marked orientation-only | **Handbooks.** |
| Human in the loop (Art. VIII): agents propose / maintainer disposes; no green-at-any-cost; commits authored by the human, **no LLM co-author trailers**; the spec is the source of truth | `CON-5`/`CON-7` gates; `CON-46` (`--no-verify`, force-push); `BC-7` (*no AI attribution*, machinery only); Hatsu's 2026-09-12 ruling (canonical `Hatsu-Agent:` / `Akatsuki-Agent:` trailers allowed, model/surface/session attribution forbidden); `CON-13` + `UZF-21` for spec-as-truth | **New clause `CON-51` (a–d)** in `CONSTITUTION.md` § 6 — the union the three sources agree on: canonical persona trailers only, never AI attribution; no green at any cost; the spec is truth. |
| Hook mechanism (Art. VIII): `.bankai/hooks/guard.sh`, commitlint, pre-push gate | scaffold-specific | consumers' hooks are generated by Nen from a declared trailer allow-list | **`CON-51(c)`** states the outcome (a commit-msg hook generated from the repo's declared allow-list), not one scaffolder's file names. |

Nothing from the scaffold constitution was concatenated in; the scaffold's `ARCHITECTURE.md`
(a per-scaffold contract *template*) and `README.md` are tooling documentation and stayed behind.

## 7. Redaction

Applied per [`docs/PUBLIC-REDACTION.md`](docs/PUBLIC-REDACTION.md), against the Hatsu legend:

- **Object ids.** Every linked id into a private repository became an unlinked placeholder id with
  its number kept: 203 links into `<reference-repo>` → `RR-IS-#n` / `RR-PR-#n`; 12 into
  `<product-repo-A>` → `RA-…`; 10 into `<scaffold-repo>` → `RS-…` (**prefix added by this
  repository** — the Hatsu legend had none for the scaffold); 4 into `<product-repo-B>` → `RB-…`.
  Bare `#n` the reference implementation cited in the handbooks became `<reference-repo>#n`; the 15
  bare `#n` inside `CONSTITUTION.md` stay bare, declared in its preamble as internal cross-references.
- **Names.** `<reference-repo>` wherever the frozen repository is meant as itself (mostly the
  constitution's machine-plane text and history notes); **`bankai-handbooks`** wherever the text
  meant *the place the canon lives*; `bankai-machinery` wherever the text meant the scenario;
  `<scaffold-repo>`, `<product-repo-A>` (iOS/macOS), `<product-repo-B>` (Android) for the rest.
  Placeholders survive only in provenance/history passages (reconciliation records, incident
  notes); rule text and examples carry tokens or generalised wording instead.
- **Paths into the reference repo** cited by the handbooks (`docs/SETUP.md`, `schemas/repos.json`,
  `schemas/templates/…`, `scripts/sync_canon.py`, lane-guard and
  workflow file names) were replaced by role descriptions ("the CI plane's setup runbook", "the
  consumer registry (`nen/repos.json`)", "the shared agent conventions" — now `CONVENTIONS.md`, § 4a). Inside
  `CONSTITUTION.md` such relative paths are kept and explained once in its preamble.
- **The maintainer's login** appeared twice in the constitution as a reviewer identity in an incident
  narrative → "the maintainer"; as a token example → `octocat`.
- **Kept, deliberately** (legend): `bankai:` labels, rule and clause ids, scenario ids, the `BC-`
  prefix, system names (Bankai, Akatsuki, Hatsu, Nen, UZF), persona names, version tags, dates,
  counts, public repositories (`zheref/hatsu`, `zheref/nen`), fictional sample data.

## 8. Audit findings — things the maintainer should read

1. **Persona and plane vocabulary is the reference implementation's.** The constitution's
   `CON-1`…`CON-50` and the handbooks speak of Naruto, Yamamoto, Kisuke, Sasuke, Tenma, Ichigo and
   `bankai.yml` callers. They are carried as written (the preamble says so); Hatsu maps the local
   plane to Kurapika and the review roster to Chrollo/Feitan/Nobunaga, and the governance rewrite for
   the successor planes is decided in the private migration tracker. Only `CON-13` was rewritten.
2. **`BC-11` / `BC-12` carry reference-implementation facts** — a frozen set of six Python scripts,
   named shell scripts, the `v0.11.x` frozen line and `v0.12.0` TypeScript line. They are true of
   `<reference-repo>` and are cited as precedent; whether they bind Akatsuki/Nen as written is a
   canon-lane decision, not made here.
3. **`agents/_conventions.md` — resolved.** First left behind under the plan's `agents/` exclusion
   and reported as a conflict; ruled in on 2026-09-28 and migrated as `CONVENTIONS.md` (§ 4a).
4. **One product repository the plan listed as private is currently public** (the web PWA), as is
   the product family's snapshot-assets host. Both were tokenised anyway — a handbook naming a product repo is a bug
   regardless of visibility — and `<product-repo-C>` is reserved for the web product.
5. **Illustrative vocabulary drawn from the reference products' domains** (`Endeavor`, `Now`,
   `Suggestions`, `Triage`, `Inbox` as sample feature/model names) was kept as ordinary example
   names. It identifies no repository; flagged so the choice is visible.
6. **Conception-document titles** (`GENERAL_UZF_ARCHITECTURE`, `SYNTHESIS_JETPACK_COMPOSE_v2`,
   "the OneDrive UZF folder") remain in provenance notes. They are document titles, not repositories.
7. **`{{SNAPSHOT_OS}}`'s illustrative value `26.5`** and device presets are stack facts from the
   reference product's environment; kept as plausible illustrations.
8. **A dangling-link check** passes; the only external links left point at public repositories.
9. **The public Nen README** cites a private product repo slug as its fixture `--target` example.
   Out of this task's scope (Nen is untouched); reported.

## 9. Deliberately left behind

In `<reference-repo>` (frozen, private, the historical record): `agents/` (the agent definitions —
only `_conventions.md` came across, § 4a), `cli/`, `claude/`, `schemas/`, `scripts/`, `tests/`, `examples/`,
`.github/` (including the `sync-canon` workflow), `docs/` (setup runbooks, agent architecture and
roster, canon-reconciliation method, prompts), `CHANGELOG.md`, `changelog.d/`, `Makefile`,
`README.md`, the plugin manifest. In `<scaffold-repo>`: the TypeScript/Ink CLI and its tests, the
scenario scripts, `ARCHITECTURE.md` (the per-scaffold contract template), `README.md`, the retired
`stack-matrix.jsx`, `constitution.md` itself (reconciled, not copied).

## 10. Not done here (next steps, for the maintainer)

- Flip the repository to **public** after reading this audit — a one-way door.
- Cut the first **tag** (`v0.6.0` is the natural choice) **before** any consumer repins to this
  repository (`CON-13` pin discipline).
- Register the repository as a **Hatsu consumer** (`nen/contract.json`, `nen/workflow.json`, the
  trailer hook) and point Hatsu's `bankai-handbooks` skill and Nen's `canon` verbs at it.
- Build the **per-surface sync** in Nen; the doctrine here already accommodates it.
- Rule on § 8.1–8.2. (The conventions' home and the license — MIT, matching the estate — were ruled and done on 2026-09-28.)
