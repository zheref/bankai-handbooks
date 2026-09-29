<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->
# Repo-specific placeholders — `react-uzf-v1`

The rule files in this directory are **canon** (product-agnostic). Everything genuinely
repo-specific is a `{{TOKEN}}`. When the mirror generator (`nen canon mirror generate`) renders a
consumer repo's per-surface mirror (`CON-13`; history: Phase 0b of `<reference-repo>#34`), it substitutes
each token from that repo's **canon-values** binding. This file is the **schema**: the token, what it means, an illustrative
example, and whether it is **shared** with the `compose-uzf-v2`/`swiftui-tca-uzf-v2` schemas or
**react**-specific. It is NOT the value store — a repo binds values in its own config.

This stack has **no live reference product yet** (unlike the native stacks), so the example column uses an illustrative product, **Acme**, rather than a real repo.
When a reference product lands, this file's example column is rebound to it, not rewritten in
kind.

Tokens marked **shared** carry the identical meaning (and reuse the exact token name) as the
native-stack schemas, so a repo spanning React and a native stack binds them once. Tokens marked
**react** have no compose/swiftui equivalent (the web/native render-target split, the shared RTK
state-logic package, the shared Tamagui/Solito render-layer package) and exist only here.

| Token | Meaning | Illustrative example | Scope |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Product name — the npm workspace scope (`@{{PROJECT_NAME}}/core`, `@{{PROJECT_NAME}}/app`), the `configureStore` devtools label, the forbidden brand type-prefix inside `{{CORE_PACKAGE}}` | `Acme` | shared |
| `{{CORE_PACKAGE}}` | The shared RTK state-logic package — every slice, State, Shifter, Selector, Producer, Service (+ `live…`/`stubbed…` pair), Mapper, and domain model; **emitted once**, consumed unchanged by both render targets. The `library/` runtime (`result.ts`, `assertNever.ts`, `store.ts`, `hooks.ts`) lives inside it | `packages/core` | react |
| `{{APP_PACKAGE}}` | The shared cross-platform render-layer package — Page/Fragment JSX built from Tamagui primitives + Solito navigation; consumed by both render targets. Depends on `{{CORE_PACKAGE}}`; neither app depends on the other | `packages/app` | react |
| `{{WEB_APP}}` | Next.js 15 App Router workspace member — the web render target | `apps/web` | react |
| `{{MOBILE_APP}}` | Expo Router workspace member (RN 0.84, New Arch + Hermes) — the native render target | `apps/mobile` | react |
| `{{THEME_ROOT}}` | Tamagui theme/config package — design tokens and theme definitions, the cross-platform twin of the Compose/SwiftUI theme root | `packages/app/theme` | shared |
| `{{DOCS_ROOT}}` | Feature-docs root (`UZF-21`) | `docs/Features` | shared |
| `{{CI_TEST_WORKFLOW}}` | Test CI workflow — runs Vitest/Jest + React Testing Library + Storybook (and, folded into the same run, the ESLint architecture rules) | `.github/workflows/test.yml` | shared |
| `{{FLAG_ENUM}}` | Platform feature-flag registry (`UZF-22`) | `featureFlags.ts` (`export const FeatureFlags = { … } as const`) | shared |

> A token that appears in a rule file MUST be listed here. Adding/renaming a token is a Naruto
> G4 change (keep the generator's substitution map in lockstep). Stack-standard libraries (Redux
> Toolkit, RTK Query, reselect, Immer, Tamagui, Solito, Vitest/Jest, React Testing Library,
> Storybook) are **not** tokenized — they are the stack, the same way TCA is fixed on the SwiftUI
> stack and Hilt defaults on the Compose stack.

## Token reconciliation notes

- **`{{APP_PACKAGE}}`'s meaning is contested across the current rule files — ruled in favor of the
  folder meaning.** `08-monorepo-and-sharing.md` — the file that formally introduces the
  React-family monorepo rules and enumerates "exactly four workspace members" — defines
  `{{APP_PACKAGE}}` as the shared render-layer **package** (`packages/app`), and
  `00-architecture-overview.md` agrees in substance (a shared cross-render-target UI package).
  `10-naming-and-layout.md` instead describes it as "the monorepo's internal workspace scope used
  in import specifiers … distinct from `{{CORE_PACKAGE}}` (the folder name) — one is a path, the
  other an import alias" — an npm-scope reading that contradicts the folder reading and is, in any
  case, already covered by `{{PROJECT_NAME}}` (08's own example imports `{{APP_PACKAGE}}` as
  `@{{PROJECT_NAME}}/app`, not `@{{APP_PACKAGE}}/…`). Ruling: `{{APP_PACKAGE}}` names the **folder**
  (workspace member), per 08/00; the npm-scope role belongs to `{{PROJECT_NAME}}`. **Resolved** (the
  `<reference-repo>#34` whole-handbook harmonization pass): `10-naming-and-layout.md`'s `{{APP_PACKAGE}}` entry now
  states the folder meaning directly, and its aside suggesting an additional `packages/ui` "should"
  package for sharing Page/Fragment/Adapter bodies — which read as a fifth, optional workspace
  member — is corrected to point at `{{APP_PACKAGE}}` itself (already one of the canonical four).
- **`{{APP_PACKAGE}}`'s illustrative example also disagreed — ruled in favor of `packages/app`.**
  `00-architecture-overview.md` illustrated it as `packages/ui`; `08-monorepo-and-sharing.md`
  illustrates the same token as `packages/app` and ties it to the dedicated RC-51 rule ("shared
  render layer: Solito + Tamagui"). Ruling: `packages/app` (08's value) is canonical, both because
  08 is the founding topology file and because "exactly four workspace members" leaves no room for
  a fifth `packages/ui`. **Resolved:** `00-architecture-overview.md`'s example is now `packages/app`,
  and `{{THEME_ROOT}}` — previously sourced from `13-feature-documentation.md` as `packages/ui/theme`
  — is renormalized to nest under `{{APP_PACKAGE}}` instead (`packages/app/theme`, reflected above).
- **`{{APP_PACKAGE}}` name-collides with `compose-uzf-v2`'s schema (different meaning, no functional
  conflict).** The compose schema also defines `{{APP_PACKAGE}}` — there, the Kotlin reverse-DNS
  package root (e.g. `com.acme.app`), scoped `compose`-only in that file. The mirror generator substitutes
  per-stack, so a repo is never resolving both schemas' generators for the same rule file — there is
  no runtime collision. It is noted here only so a human or reconciler skimming both schemas side by
  side does not conflate the two unrelated bindings.
- **`{{CORE_PACKAGE}}` is a deliberate rename of the native stacks' `{{CORE_FRAMEWORK}}`, not a
  fresh concept.** The compose/swiftui schemas call the shared pure-domain module `{{CORE_FRAMEWORK}}`
  (a Gradle module / Swift framework). React's shared state-logic tier is an npm **package**, not a
  compiled framework, so the token is renamed to fit the ecosystem rather than reusing
  `{{CORE_FRAMEWORK}}` verbatim — the underlying concept (one shared module every render/platform
  target consumes, owning models/logic/state) is identical, which is why it is called out here even
  though it is scoped `react` (not `shared`) in the table above: the **name** differs, so it fails
  the strict "identical name" bar for `shared`, even though the **role** does not.
