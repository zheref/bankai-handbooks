<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# `react-uzf-v1` — canonical rule set

The **single source** for the React 19 + Redux Toolkit UZF stack's operational rules (`CON-13`) —
one stack family covering **both** render targets, {{WEB_APP}} (Next.js 15 App Router) and
{{MOBILE_APP}} (Expo SDK 55 / RN 0.84, New Arch + Hermes), which share the entire RTK state-logic
tier in {{CORE_PACKAGE}}. A consumer repo on this stack carries a **generated, pinned mirror** of
these files in each agent surface's rules location (`.claude/rules/` for Claude Code, and the Codex /
Cursor / Antigravity equivalents), never hand-authored, so every agent loads them natively
(history: `<reference-repo>#34`). This stack has no live reference product yet, so every code sample and
`{{TOKEN}}` in these files is illustrative, not drawn from a shipped repo. The cross-platform
concepts these rules refine live in [`../../../uzf-core.md`](../../../uzf-core.md) (`UZF-{n}`).
The stack also has a condensed, cross-cutting overview at
[`../architecture.md`](../architecture.md); the canonical `RC-{n}` registry itself is anchored on
[`00-architecture-overview.md`](00-architecture-overview.md) and indexed in full in **this file**.
Repo-specific values are `{{TOKEN}}` placeholders — the shared schema lives in
[`placeholders.md`](placeholders.md), with each rule file's own "Repo-specific placeholders"
section restating only the tokens it uses.

| File | Concern |
|---|---|
| `00-architecture-overview` | 10-second loop diagram, the 20 core/supporting contributor rules, folder layout, hard "never"s, and the UZF ↔ React/RTK glossary — the `RC-{n}` numbering anchor |
| `01-feature-and-events` | The Feature (`createSlice`) contract, `UZF-2` event naming realized as thunk type strings, `reducers`/`extraReducers` body shape, `assertNever` exhaustiveness |
| `02-store-setup` | The portable `library/` module — `Result<T,E>`, `assertNever`, `makeStore`/`ThunkExtra` service injection, typed `useAppSelector`/`useAppDispatch` |
| `03-state-shifters-selectors` | `State` shape (domain types, exclusive-lifecycle union), pure `with…` Shifters, `createSelector`-built Selectors |
| `04-producers-effects` | `createAsyncThunk` Producers, the `.pending`/`.fulfilled`/`.rejected` lifecycle, the `…Task`/`AbortController` escape hatch, RTK Query as Service-tier |
| `05-page-and-screen` | The Page/Fragment/Component/Adapter render-layer split, plus the Next.js Server/Client and Expo Router entry-file rules |
| `06-services-and-data` | Service (`live…`/`stubbed…`), Repository, Provider, Operation/RTK-Query-as-Service, Mapper, and the cross-platform `live…` split |
| `07-models-mocks-mappers` | Model / Response / Mapper / Exception shapes, ≥7 domain-model mocks, per-feature `<Feature>Mocks.ts` state fixtures |
| `08-monorepo-and-sharing` | Workspace topology, `{{CORE_PACKAGE}}`/`{{APP_PACKAGE}}` ownership, thin app shells, platform-bound Services, the build graph |
| `09-testing` | Per-artifact test minimums and patterns (reducer/selector/shifter/producer/mapper/Page/Fragment), the testing toolbox, what NOT to test |
| `10-naming-and-layout` | File-suffix taxonomy, monorepo tree, event/Shifter/Selector/Producer/Service/Mapper naming conventions |
| `11-forbidden-patterns` | The coded reject list — the single greppable source of "never do this" across architecture, hooks, reducers, services, data, mocks, and testing |
| `12-session-completion-checklist` | Definition-of-done gate: coverage, mermaid diagram, feature spec, flag wrapping |
| `13-feature-documentation` | `{{DOCS_ROOT}}` language-agnostic feature specs + fenced-mermaid diagrams, shared 1:1 across both render targets |

There are no numbering gaps left — every topic file `01`–`13` exists and is reconciled into the
`RC-{n}` registry below.

## Reconciliation decisions (`<reference-repo>#34` Phase C-1b, then the whole-handbook pass: harmonizing every
independently-authored rule file, plus the condensed `../architecture.md`)

> **Status: fully propagated.** The registry below was originally drafted as a *proposed*
> resolution while the source files still carried their own colliding local numbers (see the
> "Phase C-1b" numbering-collision history further down for how `00`, `02`, `03`, `04`, `07`, `11`,
> `12` collided). A later whole-handbook harmonization pass **applied** this registry to every
> file — `00`–`13`, `../architecture.md`, and this README — so every `RC-{n}` citation in the
> handbook now already matches the table below; no file still carries a stale local number. That
> pass also folded in `01`, `05`, `06`, `08`, `09`, `10`, and `../architecture.md`, none of which
> existed (or were reconciled) when this registry was first drafted — see `RC-36`–`RC-63` below.

Files `00`, `02`, `03`, `04`, `07`, `11`, and `12` were authored as separate passes, each minting
its own local `RC-{n}` sequence starting at `RC-1`. Because no shared registry existed while they
were written, the same number was assigned to unrelated concepts across files, and the same
concept was assigned different numbers across files — the same collision shape the Compose canon
hit and resolved for `KT-{n}` (see [`compose-uzf-v2/rules/README.md`](../../compose-uzf-v2/rules/README.md)).
(`01`, `05`, `06`, `08`, `09`, `10`, and the stack's condensed `../architecture.md` were authored
even later, each also minting its own colliding local sequence — folded in below as `RC-36`–`RC-63`.)

| Topic | Decision |
|---|---|
| **No rule contradictions** | Every file agrees on the actual coding rule; the collision is purely in **numbering**, never in substance. Reconciliation was a pure renumbering exercise — no rule content changed. |
| **RC numbering** | The 7 files used **seven separately-restarted local numberings** (see below). Resolved into one canonical `RC-1…RC-35` sequence in this README. |
| **Backbone choice** | `00-architecture-overview`'s `RC-1…RC-20` was adopted as the authoritative backbone — it is this stack's master triage file (the React analog of Compose's file-`00`) and gives each core/supporting rule one clear meaning. |
| **`RC-9` scope note** | `02`'s local `RC-2` ("every switch ends in `assertNever`") is folded into backbone `RC-9`, but its narrower point stands: inside `createSlice`'s own `reducers`/`extraReducers` map, TypeScript's case-key exhaustiveness on the action map already gives the equivalent guarantee — `assertNever` is required for hand-written `switch` statements elsewhere (a Mapper, an `Exception["kind"]` check outside the slice), not an unreachable default bolted onto every reducer arm. |
| **`RC-1` clash (Storybook)** | `12`'s local `RC-1` ("Storybook is the visual-evidence carrier for this stack") is a distinct rule from backbone `RC-1` ("one slice per feature") despite the shared local number — folded into backbone `RC-11` (Pages/Fragments ship ≥3 stories), which is the same concept `12` restates for the completion checklist. |
| **Router-as-Service** | `00`'s `RC-17` and `04`'s Producer-navigation guidance agree exactly (navigate only from a Producer, never a component) — reconciled as one rule, no divergence. |

### RC-n numbering collision — how it was resolved

Each file's local scheme, before reconciliation:

1. **`00`'s backbone scheme (`RC-1…20`)** — `RC-1`=one slice per feature, `RC-2`=event naming,
   `RC-3`=Producer-only effects, `RC-4`=Shifters, `RC-5`=Selectors, `RC-6`=Service injection,
   `RC-7`=`Result`/never-throw, `RC-8`=`Exception` union, `RC-9`=`assertNever`, `RC-10`=typed
   hooks only, `RC-11`=Storybook stories, `RC-12`=reducer tests, `RC-13`=model mocks, `RC-14`=
   Components under `design/`, `RC-15`=Fragment dispatch ban, `RC-16`=RTK Query as Service,
   `RC-17`=router-as-Service, `RC-18`=memoized Adapters, `RC-19`=scoped Immer, `RC-20`=no
   cross-slice imports.
2. **`02`'s independent `RC-1…7`** — re-numbered `Result` contract, `assertNever`, service
   injection, `ThunkExtra`, `makeStore`, slice registration, and typed hooks onto its own 1–7,
   colliding with `00`'s `RC-1…7` (unrelated concepts) on every number.
3. **`03`'s independent `RC-1…4`** — State, Shifters, Immer, Selectors renumbered 1–4, again
   colliding with `00`'s `RC-1…4`.
4. **`04`'s independent `RC-1…5`** — Producer shape, Effect-as-promise, lifecycle handling, `…Task`,
   RTK Query, colliding with `00`'s `RC-1…5`.
5. **`07`'s independent `RC-1…6`** — Model, Response, Mapper, `Exception`, model mocks, state
   mocks, colliding with `00`'s `RC-1…6`.
6. **`11`'s independent master `RC-1…32`** — re-derived a full sequential numbering across every
   topic above (architecture → hooks → reducers → services → data → mocks → testing), on
   entirely different meanings from all four other schemes.
7. **`12`'s single append `RC-1`** — Storybook-as-evidence, colliding with `00`'s `RC-1`.

**Resolution.** Adopt **`00`'s `RC-1…20` as the authoritative backbone**. Every rule a topic file
had re-numbered was re-pointed to the number `00` assigned that concept. Genuinely new
topic-specific rules `00` does **not** cover were appended sequentially as **`RC-21…RC-35`**
(service-injection manifest/registration mechanics, the Effect-as-promise / lifecycle-handling /
`…Task` mechanics, the Model/Response/Mapper/state-mocks shapes, and three testing/hygiene rules
`11` states but `00` doesn't number). No rule was dropped; no number maps to two rules.

**Second pass — folding in `01`, `05`, `06`, `08`, `09`, `10`, and `../architecture.md`.** These
seven files were authored after (or independently of) the first reconciliation pass above, each
minting its own colliding local sequence exactly the same way `02`/`03`/`04`/`07`/`11`/`12` did —
including `../architecture.md`, which duplicates `00`'s entire `RC-1…18` space under different
meanings (e.g. its own `RC-6` is "typed hooks only," not `00`'s `RC-6` "services injected via
extra"). The same resolution method applies: every duplicate concept is re-pointed to its existing
canonical number, and genuinely new rules are appended as **`RC-36…RC-63`** (below). Two
substantive issues surfaced and were fixed in the same pass, not just renumbered around:

- **A real internal contradiction in `10-naming-and-layout.md`.** Its old "Mocks and Storybook
  fixtures" section claimed this stack has **no** per-feature `<Feature>Mocks.ts` file and
  constructs `State` inline in stories — directly contradicting `07-models-mocks-mappers.md`'s
  "State mocks" section (`RC-31`), `09-testing.md`, `11-forbidden-patterns.md`, and
  `12-session-completion-checklist.md`, all of which require `<Feature>Mocks.ts` and forbid inline
  `State` construction. Fixed in `10` to match the other four files (the majority, and the more
  specific/worked-example source, `07`) rather than left as a flagged-but-unresolved conflict.
- **`{{APP_PACKAGE}}`'s contested meaning**, already diagnosed in `placeholders.md`'s
  token-reconciliation notes as an open item, is now applied: `00`'s illustrative example
  (`packages/ui`) and `10`'s definition (an npm-scope import alias) are corrected to the ruled
  canonical folder meaning (`packages/app`, per `08`'s `RC-51`). `10`'s aside suggesting an
  additional, optional `packages/ui` "fifth package" for sharing Page/Fragment/Adapter bodies
  contradicted `08`'s "exactly four workspace members" rule (`RC-49`) — `{{APP_PACKAGE}}` already
  *is* that package — and is corrected accordingly. `13-feature-documentation.md`'s `{{THEME_ROOT}}`
  example is renested under `packages/app/theme` to match.

No rule was dropped; no number maps to two rules. **The rule files now all carry this canonical
numbering** — this README, `00`–`13`, and `../architecture.md` are in sync as of this pass.

## RC-n rule registry (canonical)

Each *tightens but never contradicts* its `UZF-{n}` parent(s) (shown in parens).

| Code | Rule | Parent | Source file (old local number) |
|---|---|---|---|
| `RC-1` | One slice per feature — `createSlice({ name: "…" })`, filename `…Feature.ts`, co-located with its selectors/shifters/producer, registered in `library/store.ts` | UZF-6 | `00` (RC-1) |
| `RC-2` | Event/action names encode intent, never mechanism (`userDid…`/`on…`/`child…Delegated…`); naming a case after its effect (`fetchProfile`) is forbidden | UZF-2 | `00` (RC-2); `11` (RC-15) |
| `RC-3` | Effects are built only by Producers — components/reducers never call `fetch`/`axios`/a native module directly, and a Producer takes narrow inputs, never the whole `State`/`getState()` | UZF-12, UZF-15 | `00` (RC-3); `04` (RC-1); `11` (RC-6, RC-7, RC-14) |
| `RC-4` | State mutations go through a named `with…` Shifter (`Object.assign(state, withFoo(state, args))`); only a single primitive assignment may be inlined | UZF-10 | `00` (RC-4); `03` (RC-2); `11` (RC-16) |
| `RC-5` | Selectors live in `…Selectors.ts`, built with `createSelector`; no selector logic inline inside a `useAppSelector` callback | UZF-11 | `00` (RC-5); `03` (RC-4); `11` (RC-10) |
| `RC-6` | Services are injected via the thunk `extra` argument only — never a module-level import, a service locator, or a direct import from a reducer/Selector/Page | UZF-13, UZF-16 | `00` (RC-6); `02` (RC-3); `11` (RC-19, RC-20, RC-23) |
| `RC-7` | Thunks resolve `Result<T, E>`; they never throw. `.rejected` is a defensive fallback only, never the primary error path | UZF-3, UZF-14 | `00` (RC-7); `02` (RC-1); `11` (RC-12, RC-13) |
| `RC-8` | `Exception` is a discriminated union with a companion factory (`<Name>Exceptions`) — never a raw `string`/`Error` in State or a completion event | UZF-3, UZF-14 | `00` (RC-8); `07` (RC-4); `11` (RC-26) |
| `RC-9` | Every hand-written `switch` over an Event/Exception union ends in `assertNever(value)` — required outside `createSlice`'s own case-keyed `reducers`/`extraReducers` map, where TS's own exhaustiveness is the equivalent guarantee | UZF-9 | `00` (RC-9); `02` (RC-2); `11` (RC-17) |
| `RC-10` | `useAppSelector`/`useAppDispatch` (typed wrappers) are the only Redux-React binding surface — no raw `useSelector`/`useDispatch`, no `connect()` HOC | UZF-4 | `00` (RC-10); `02` (RC-7); `11` (RC-5, RC-8, RC-9) |
| `RC-11` | Pages and Fragments ship ≥3 Storybook stories mirroring the snapshot/interaction tests (this stack's `UZF-26` visual-evidence carrier) | UZF-18, UZF-26 | `00` (RC-11); `12` (RC-1); `11` (RC-31) |
| `RC-12` | Reducers carry ≥3 unit tests per action, each named after a real-world scenario | UZF-18, UZF-20 | `00` (RC-12); `11` (RC-18) |
| `RC-13` | Domain models declare ≥7 mock variations in `__mocks__/*.mocks.ts` | UZF-18 | `00` (RC-13); `07` (RC-5); `11` (RC-28) |
| `RC-14` | Components (domain-less, reusable) live under `design/` and import nothing from `react-redux`, a slice, or a Producer | UZF-5 | `00` (RC-14); `11` (RC-2) |
| `RC-15` | Fragments may `useAppSelector` but never dispatch an async thunk — intent arrives only via callback props | UZF-4, UZF-7 | `00` (RC-15); `11` (RC-3) |
| `RC-16` | RTK Query endpoints are Service-tier; their auto-generated hooks (`useGetXQuery`, …) are forbidden inside Pages/Fragments — expose a Producer thunk that delegates to `.initiate(...)` instead | UZF-16, UZF-17 | `00` (RC-16); `04` (RC-5); `11` (RC-22) |
| `RC-17` | The router is a Service — `router.navigate(...)` is invoked from a Producer, never from a component | UZF-13, UZF-16 | `00` (RC-17); `11` (RC-24) |
| `RC-18` | Memoize Adapters with `React.memo` and stable keys rather than a hand-rolled `useMemo`/`useCallback` chain | UZF-7 | `00` (RC-18); `11` (RC-11) |
| `RC-19` | Immer's draft-mutation syntax is scoped to genuinely nested state, never the default — flat slice state always goes through a pure Shifter | UZF-10 | `00` (RC-19); `03` (RC-3) |
| `RC-20` | Slices never cross-import another feature's state/selectors — cross-slice reads compose through root-level Selectors | UZF-6 | `00` (RC-20); `11` (RC-1) |
| `RC-21` | `ThunkExtra` is the single, closed manifest of every injectable service — no second injection mechanism alongside it | UZF-16 | `02` (RC-4) |
| `RC-22` | There is exactly one store-construction path, `makeStore(extra)` in `library/store.ts` — no `configureStore(...)` call anywhere else, including tests/Storybook | UZF-6 | `02` (RC-5) |
| `RC-23` | Slice registration is closed to `library/store.ts`'s `reducer` map — a slice registered only in a test/story file is not actually registered in the app | UZF-6 | `02` (RC-6) |
| `RC-24` | `State` holds domain types only, one `interface <Name>State` co-located with its slice, with any loading/loaded/failed lifecycle modeled as one discriminated-union field, never parallel optionals | UZF-8, UZF-9 | `03` (RC-1); `11` (RC-25, RC-27) |
| `RC-25` | The "Effect" in this stack is the promise `createAsyncThunk` builds — a Producer never hand-constructs `.pending`/`.fulfilled`/`.rejected` actions | UZF-14 | `04` (RC-2) |
| `RC-26` | The slice's `extraReducers` builder handles all three thunk lifecycle actions; `.fulfilled` always branches on `result.ok`, and `.rejected` fires only for genuinely unexpected failures | UZF-3, UZF-12 | `04` (RC-3) |
| `RC-27` | A hand-rolled `…Task` (`AbortController` wrapper) is reserved for cases `createAsyncThunk`'s standard form can't express — caller-held cancellation or mid-flight progress reporting — and still resolves exactly one completion event on the non-aborted path | UZF-14 | `04` (RC-4) |
| `RC-28` | A domain Model holds domain types only, one type per file, with no wire-format field names or serialization concerns | UZF-8 | `07` (RC-1) |
| `RC-29` | A `Response` type mirrors the wire format exactly (including `snake_case`); it is never imported outside the Service → Producer → Mapper path | UZF-17 | `07` (RC-2) |
| `RC-30` | A Mapper is a plain object of pure functions (`toDomain`/`fromDomain`/`toException`) — the only place wire ↔ domain ↔ exception conversion happens | UZF-17 | `07` (RC-3) |
| `RC-31` | A per-feature `<Feature>Mocks.ts` backs every Storybook story and reducer/selector test — `State` (or a preload fragment) is never constructed inline | UZF-18 | `07` (RC-6); `11` (RC-29) |
| `RC-32` | No "god" Page/Feature file mixing more than one slice's worth of reducer logic — split into a child feature or an additional Producer | UZF-6 | `11` (architecture bullet 4) |
| `RC-33` | Every new `…Service` (including an RTK Query API slice) ships a `stubbed…Service` companion plus a backing fixture — no exceptions | UZF-16 | `11` (RC-21) |
| `RC-34` | Test names describe a real scenario (`test_<event>_<condition>_<expectation>`), never `test_state`/`it('works')` | UZF-20 | `11` (RC-30) |
| `RC-35` | Tests never reach the live network — dispatch against a store built with a `stubbed…Service` in `extra`, never the live implementation | UZF-16 | `11` (RC-32) |
| `RC-36` | `reducers` and `extraReducers` are separate surfaces that never mix — sync Events only in `reducers`, thunk lifecycle only in `extraReducers` | UZF-1, UZF-3 | `01` (RC-3, partial) |
| `RC-37` | Page is the stateful container — the only artifact that calls `useAppSelector`/`useAppDispatch` for a feature; it owns no markup beyond its single Fragment call | UZF-4 | `05` (RC-4) |
| `RC-38` | Next.js `app/**/page.tsx` is a passive Server Component — param resolution and optional prefetch only, never a hook or dispatch | UZF-4 | `05` (RC-5) |
| `RC-39` | The Client Page Wrapper (`…PageClient.tsx`) is ≤10 lines and forwards props only | UZF-4 | `05` (RC-6) |
| `RC-40` | The shared Page never imports a Next.js API (`next/navigation`, `next/headers`, `next/image`, `next/link`, `next/font`) | UZF-4, UZF-6 | `05` (RC-7) |
| `RC-41` | `app/layout.tsx` is a passive Server Component; `app/providers.tsx` is the one Client Component wiring Store + Theme + Navigation | UZF-16 | `05` (RC-8) |
| `RC-42` | SSR-prefetched data enters the slice only through a dedicated `on…Hydrated` event, never bypassing the Shifter | UZF-10, UZF-17 | `05` (RC-9) |
| `RC-43` | Server Actions and route handlers are Producers, not Page logic — they call Services and return a `Result` | UZF-3, UZF-14 | `05` (RC-10); `09` (RC-9) |
| `RC-44` | Expo Router `app/**/*.tsx` route files are route bindings only, never Pages | UZF-4 | `05` (RC-11) |
| `RC-45` | `app/_layout.tsx` is the single platform-binding point — the only file permitted to import Expo Router's imperative `router` | UZF-16 | `05` (RC-12) |
| `RC-46` | The same Page mounts under both render targets unmodified | UZF-4, UZF-6 | `05` (RC-13) |
| `RC-47` | Provider — a synchronous helper module; reducers and Selectors may call it directly, never a Service | UZF-13 | `06` (RC-4) |
| `RC-48` | Platform-bound Services ship one shared interface with platform-forked `live…` files (never a runtime `Platform.OS` branch) | UZF-16 | `06` (RC-5); `08` (RC-5) |
| `RC-49` | Workspace topology — exactly four members (`{{CORE_PACKAGE}}`, `{{APP_PACKAGE}}`, `{{WEB_APP}}`, `{{MOBILE_APP}}`), cross-package imports only via `workspace:*` | UZF-6 | `08` (RC-1); `10` (RC-1, partial) |
| `RC-50` | `{{CORE_PACKAGE}}` is the single owner of the RTK state-logic tier and carries zero platform imports; it exposes a store factory, never a built singleton | UZF-6, UZF-16 | `08` (RC-2); `../architecture.md` (RC-16) |
| `RC-51` | `{{APP_PACKAGE}}` is the shared render layer, built from Tamagui + Solito, consumed unmodified by both render targets | UZF-4, UZF-5 | `08` (RC-3) |
| `RC-52` | The build graph rebuilds/typechecks `{{CORE_PACKAGE}}`/`{{APP_PACKAGE}}` against both render targets on every change | UZF-6 | `08` (RC-6) |
| `RC-53` | Toolbox — Vitest/RTL for `{{CORE_PACKAGE}}`/`{{WEB_APP}}`, Jest (`jest-expo`) + RNTL for `{{MOBILE_APP}}`, Storybook 8 (+ test-runner) on both | UZF-18 | `09` (RC-1) |
| `RC-54` | Producer and thunk-lifecycle reducer-arm tests dispatch the real thunk against a store built with the `stubbed…Service` in `extra` — never a mocked `fetch`/`axios` | UZF-18 | `09` (RC-3) |
| `RC-55` | Every Selector carries ≥3 tests, exercised against a hand-built root-state slice — never through a real store or `useAppSelector` | UZF-18 | `09` (RC-4) |
| `RC-56` | Every Shifter carries ≥3 tests (typical/boundary/no-op), pure — no store, dispatch, Provider, timers, or I/O | UZF-18 | `09` (RC-5) |
| `RC-57` | The Server Page / Client Wrapper are testing-exempt — passive shells carry no per-artifact test minimum; coverage lives in the shared Page | UZF-19 | `09` (RC-10) |
| `RC-58` | Exported thunk factories carry the `…Thunk` suffix (`fetchProfileThunk`, not `fetchProfile`) | UZF-3 | `10` (RC-6) |
| `RC-59` | Service naming — `<X>Service` interface + `live<X>Service` + `stubbed<X>Service`, lower-camel object literals, never PascalCase classes | UZF-16, UZF-17 | `10` (RC-7) |
| `RC-60` | Feature docs are language-agnostic — no file paths, type names, or framework identifiers (mermaid fences excepted) | UZF-21 | `13` (RC-2) |
| `RC-61` | React realizes the UZF stateful-wrapper/pure-renderer split as three tiers — Page, Fragment, Component — not two | UZF-4 | `../architecture.md` (RC-11) |
| `RC-62` | Render-target entry files are thin shells — param/prop resolution and rendering only, never slice logic or a direct Service call | UZF-4 | `../architecture.md` (RC-17); `08` (RC-4) |
| `RC-63` | Platform singletons (`NavigationService`, `EnvironmentProvider`'s public surface, `useAppTheme()`) are the sole import boundary for a render target's native modules | UZF-16 | `../architecture.md` (RC-18) |

## Shared-UZF ↔ React mapping

| Cross-platform (`UZF-n`) | React + RTK tightening (`RC-n`) |
|---|---|
| UZF-2 Event/action naming | RC-2, RC-36, RC-58 |
| UZF-3 Result/Exception unification | RC-7, RC-8, RC-26, RC-37, RC-43, RC-58 |
| UZF-4 Passive-renderer purity | RC-10, RC-15, RC-24, RC-37, RC-38, RC-39, RC-40, RC-44, RC-46, RC-61, RC-62 |
| UZF-5 Domain-less Components | RC-14, RC-51 |
| UZF-6 Co-location / no cross-feature imports | RC-1, RC-20, RC-21, RC-22, RC-23, RC-32, RC-40, RC-46, RC-49, RC-50, RC-52 |
| UZF-7 Active/passive split | RC-15, RC-18, RC-24 |
| UZF-8 No wire types in State | RC-8, RC-24, RC-28 |
| UZF-9 Coherent lifecycle fields | RC-9, RC-24 |
| UZF-10 Shifters | RC-4, RC-19, RC-36, RC-42 |
| UZF-11 Selectors | RC-5 |
| UZF-12 Reducer purity, event loop | RC-3, RC-26 |
| UZF-13 No service calls from a reducer | RC-3, RC-6, RC-17, RC-47 |
| UZF-14 Effects never throw | RC-7, RC-25, RC-27, RC-43 |
| UZF-15 Producers are state-free factories | RC-3 |
| UZF-16 External systems behind a DI'd Service + stub | RC-6, RC-16, RC-17, RC-21, RC-33, RC-35, RC-41, RC-45, RC-47, RC-48, RC-50, RC-59, RC-63 |
| UZF-17 Wire types cross via a Mapper | RC-16, RC-29, RC-30, RC-42, RC-59 |
| UZF-18/19/20 Test minimums / coverage floor | RC-11, RC-12, RC-13, RC-31, RC-34, RC-53, RC-54, RC-55, RC-56, RC-57 |
| UZF-21 Language-agnostic feature spec | RC-60 |
| UZF-26 Previews mirror snapshots | RC-11 |
| **React-only (no `UZF` parent listed above)** | — |

## Open items / follow-ups (Naruto G4)

**(Resolved, this pass — `<reference-repo>#34` whole-handbook harmonization.)** The four items below were open as
of the first `RC-1…35` reconciliation pass. All four are now closed; kept here, marked resolved,
as a record of what changed rather than deleted outright:

1. ~~Propagate this sequence into the rule files.~~ **Done.** `00`–`13` and `../architecture.md`
   all cite the canonical numbers in the registry above; none still carries a stale local sequence.
2. ~~Stack-level `architecture.md` + `README.md`.~~ **Done.** `../architecture.md` exists (a
   condensed, cross-cutting overview) and cites this registry rather than minting its own numbers
   — it no longer needs the numbering-collision fix described earlier in this file, since that fix
   is now applied.
3. ~~Missing topic files.~~ **Done.** `01`, `05`, `06`, `08`, `09`, and `10` all exist and are
   fully reconciled into the registry (`RC-36`–`RC-63` above). No topic remains folded awaiting a
   dedicated file.
4. ~~`placeholders.md`.~~ **Done.** `rules/placeholders.md` exists as the shared token schema for
   this stack, and its token-reconciliation notes (the `{{APP_PACKAGE}}` contested-meaning items)
   are applied across `00`, `10`, and `13` as part of this same pass.

No further open items are tracked here as of this pass. A genuine new gap (a contradiction with
`uzf-core.md`, an unresolvable token collision, a rule that still can't find a canonical number)
is a fresh `bankai:handbook-question`, not a revival of the items above.
