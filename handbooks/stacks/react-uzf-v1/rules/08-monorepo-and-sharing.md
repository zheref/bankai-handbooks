<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 08 — Monorepo & Sharing

## Repo-specific placeholders

- `{{PROJECT_NAME}}` — the product name, used as the npm scope for every workspace package (`@{{PROJECT_NAME}}/core`, `@{{PROJECT_NAME}}/app`). Illustrative example: `Acme`.
- `{{CORE_PACKAGE}}` — the shared RTK state-logic package, e.g. `packages/core`. Holds every slice, Shifter, Selector, Producer, Service interface + `live…`/`stubbed…` pair, Mapper, and domain model — **emitted once**, consumed by both render targets.
- `{{APP_PACKAGE}}` — the shared cross-platform render-layer package, e.g. `packages/app`. Holds the actual Page/Fragment JSX, built from Tamagui primitives and Solito navigation, consumed by both render targets.
- `{{WEB_APP}}` — the Next.js App Router workspace member, e.g. `apps/web`.
- `{{MOBILE_APP}}` — the Expo Router workspace member, e.g. `apps/mobile`.

(Package names in the tree below — `packages/core`, `packages/app`, `apps/web`, `apps/mobile` — and file names like `UserProfileFeature.ts` are **illustrative**, not repo config. `Turbo`, `pnpm`, `Solito`, `Tamagui` are stack/framework names and are never tokenized: this stack is **RTK + Solito + Tamagui**, so that trio is fixed the way TCA is fixed on the SwiftUI stack.)

---

React web (`{{WEB_APP}}`, Next.js 15 App Router) and React Native (`{{MOBILE_APP}}`, Expo SDK 55) are **two render targets of one stack family**, not two stacks. The monorepo layout is how this satisfies `UZF-6` (co-locate a feature's artifacts; cross-feature/cross-app shared logic goes to a core layer, never a sibling) when the "sibling" is an entire second runtime — a browser/Node bundle and a Hermes/New-Arch bundle that cannot share a single build output. This file introduces the React-family monorepo rules **RC-49** (workspace topology), **RC-50** (`{{CORE_PACKAGE}}` ownership), **RC-51** (`{{APP_PACKAGE}}` — Solito + Tamagui), **RC-62** (apps are thin shells), **RC-48** (platform-bound Services), and **RC-52** (build graph).

## Workspace topology (RC-49)

```
{{PROJECT_NAME}}/
  pnpm-workspace.yaml         # packages: ["apps/*", "packages/*"]
  turbo.json                  # build / lint / test / typecheck pipeline, dependsOn ["^build"]
  packages/
    core/                     # {{CORE_PACKAGE}} — @{{PROJECT_NAME}}/core
    app/                      # {{APP_PACKAGE}}  — @{{PROJECT_NAME}}/app
  apps/
    web/                      # {{WEB_APP}}      — Next.js App Router
    mobile/                   # {{MOBILE_APP}}   — Expo Router
```

- Exactly **four** workspace members for this stack: `{{CORE_PACKAGE}}`, `{{APP_PACKAGE}}`, `{{WEB_APP}}`, `{{MOBILE_APP}}`. A fifth "shared" package is a smell — it means one of the four above absorbed the wrong responsibility (see RC-50/RC-51 for what belongs where).
- Cross-package imports are **only** via the `workspace:*` protocol (`"@{{PROJECT_NAME}}/core": "workspace:*"` in `{{APP_PACKAGE}}`'s and each app's `package.json`) — never a relative `../../packages/core/src/...` reach-through, which bypasses the package's own build/typecheck boundary.
- `{{APP_PACKAGE}}` depends on `{{CORE_PACKAGE}}`. Neither app depends on the other. `{{CORE_PACKAGE}}` depends on neither app nor on `{{APP_PACKAGE}}` — the dependency graph is a strict DAG pointing away from the platform shells.

## `{{CORE_PACKAGE}}` — the shared state tier, emitted once (RC-50)

```
packages/core/src/
  library/                    # store.ts, hooks.ts, result.ts, assertNever.ts
  models/                     # domain models + Mappers (toDomain/fromDomain/toException)
  services/
    network/<Name>Service.ts  # interface + live…Service + stubbed…Service (per UZF-16/UZF-17)
  features/<Feature>/
    <Feature>Feature.ts       # the slice (Interactor)
    <Feature>Shifters.ts
    <Feature>Selectors.ts
    <Feature>Producer.ts
```

- `{{CORE_PACKAGE}}` is the **single** owner of every slice, Shifter, Selector, Producer, Service interface + doubles, Mapper, and domain model. This is `UZF-6`'s "core layer" made into a physical package boundary instead of just a folder convention, because here the "sibling" reaching into it is a whole second app, not just a neighboring feature.
- **Zero platform imports.** `{{CORE_PACKAGE}}` never imports `next/*`, `expo-*`, `react-native`, or `react-dom`. It may depend on `react` and `@reduxjs/toolkit` only. A network `Service`'s `live…Service` uses `fetch`, which is available unmodified in the browser, in Next.js's server runtime, and in Hermes — this is precisely what makes it safe to hoist into the shared package (contrast with Storage/System Services, RC-48).
- Every Feature folder here is otherwise identical to the React + RTK synthesis: one slice per feature, Shifters pure, Selectors built with `createSelector`, Producers built as `createAsyncThunk`s that inject Services through the thunk `extra` argument and never throw (`UZF-14`, `UZF-15`).
- `library/store.ts` exports a **factory**, not a built store: `configureAppStore(services: ThunkExtra)`. `{{CORE_PACKAGE}}` never constructs the final store itself — each app supplies its own platform Services at construction time (RC-48; this is the same "factory, not a singleton" principle as `RC-22`'s `makeStore`). This is what lets one package serve two runtimes without importing either runtime's native modules.

## `{{APP_PACKAGE}}` — shared render layer: Solito + Tamagui (RC-51)

```
packages/app/src/
  features/<Feature>/
    <Feature>Page.tsx          # Tamagui-built renderer, imports state from {{CORE_PACKAGE}}
    <Feature>Page.stories.tsx
  fragments/<Fragment>/
  design/                      # Components — Tamagui primitives, domain-less (UZF-5)
  theme/                       # Tamagui theme tokens + useAppTheme()
```

- `UZF-4` requires a stateful-wrapper/pure-renderer split; on this stack the renderer half is what `{{APP_PACKAGE}}` supplies, and it renders **identically on both targets** because it is built from Tamagui primitives (`YStack`, `XStack`, `Text`, `Image`, …) — which compile to `react-native-web` under `{{WEB_APP}}` and to Fabric-backed native views under `{{MOBILE_APP}}` — instead of raw DOM elements or bare `react-native` components.
- Navigation inside `{{APP_PACKAGE}}` uses **Solito** (`useRouter`, `useParams`, `<Link>` from `solito/navigation` / `solito/link`) for the *declarative*, in-render navigation a Page or Fragment issues directly — this is what lets one `<Feature>Page.tsx` render and link correctly on both `{{WEB_APP}}` and `{{MOBILE_APP}}`. Solito is the app layer's implementation of the navigation boundary, not a replacement for it: `{{CORE_PACKAGE}}` never imports Solito (or `next/navigation`, or `expo-router`) — a core Producer that needs to navigate does so only through an injected `NavigationService` (Service-tier, per `RC-17`'s "router as a Service" and `RC-50`'s framework-blind core), exactly like any other external system behind a DI'd Service (`UZF-16`). The app layer supplies the **live** `NavigationService` binding — built on Solito so the same implementation serves both targets — registered into `configureStore`'s `extraArgument` at each target's composition root (`app/providers.tsx` / `app/_layout.tsx`, per `RC-63`). Solito (declarative, Page/Fragment call sites) and `NavigationService` (imperative, Producer call sites) are complementary halves of the same boundary, not alternatives.
- A `<Feature>Page.tsx` under `{{APP_PACKAGE}}` imports its slice/Selectors/Producer from `{{CORE_PACKAGE}}` and its layout from Tamagui — it never imports `next/*` or `expo-router` directly, and it never falls back to a bare `<div>`/`<View>` tree once a Tamagui equivalent exists (a bare fallback silently forks the two render targets' visual output).
- Reusable, domain-less UI (`UZF-5`) lives under `design/` here, built from Tamagui, with no store access — this is the cross-platform twin of the Compose/SwiftUI stacks' Component layer.

## `{{WEB_APP}}` and `{{MOBILE_APP}}` are thin shells (RC-62)

```
apps/web/                                  apps/mobile/
  app/                                       app/
    layout.tsx        # passive Server         _layout.tsx   # Store + Theme +
    providers.tsx      # Store+Theme+Solito                   Solito root
    profile/[id]/
      page.tsx         # passive Server        profile/[id].tsx
      ProfilePageClient.tsx  # "use client"                  # route file, ≤10 lines,
                                                              # forwards params only
```

- Neither app owns a slice, Shifter, Selector, or Producer — those exist only in `{{CORE_PACKAGE}}`. Neither app owns a Page's JSX body — that exists only in `{{APP_PACKAGE}}`. Each app keeps only what the platform *mandates*: for `{{WEB_APP}}`, the Server Page / Client Page Wrapper split and `app/providers.tsx` (per the Next.js synthesis); for `{{MOBILE_APP}}`, the Expo Router route file and `app/_layout.tsx` (per the Expo synthesis).
- Each app's root binding file (`app/providers.tsx` for `{{WEB_APP}}`, `app/_layout.tsx` for `{{MOBILE_APP}}`) is the one place per app allowed to call `configureAppStore(...)` with that platform's own Services (RC-48), wrap the Solito/Tamagui provider tree, and initialize the platform's theme source (`next-themes` vs. `useColorScheme()`).
- A route/page file that grows a reducer call, a `useState` holding feature state, or a hand-rolled UI tree instead of importing the `{{APP_PACKAGE}}` Page is a boundary violation, not a convenience — the file has become a second, undeclared Page, and the two platforms' UIs will drift the next time only one of them is edited.

## Platform-bound Services stay behind one shared interface (RC-48)

(Same rule as `06-services-and-data.md`'s "Cross-platform Live implementations" section — that
file is the more specific home for the Service-shape mechanics; this section states the
monorepo-topology consequence.)

- Not every Service can live entirely inside `{{CORE_PACKAGE}}`. Storage/secrets (`expo-secure-store` + `expo-sqlite` on `{{MOBILE_APP}}` vs. browser storage on `{{WEB_APP}}`) and system integrations (`expo-linking`/`expo-sharing`/`expo-clipboard`, with no web equivalent) are genuinely platform-specific.
- The **interface** (`interface StorageService { … }`) is authored once in `{{CORE_PACKAGE}}`, exactly like any other `UZF-16` Service contract. The two `live…Service` **implementations** are authored beside the platform that owns the native module — `{{MOBILE_APP}}` supplies its `expo-secure-store`-backed implementation, `{{WEB_APP}}` supplies its browser-storage-backed one — and each app injects its own implementation into `configureAppStore(...)` at its own root binding file.
- This is `UZF-16`'s "segregation by feature, not by domain" tightened into segregation-by-platform for the shared-interface case: a web bundle must never pull in `expo-sqlite`, and a mobile bundle must never pull in a browser-only API, even though both call the same `StorageService` shape from `{{CORE_PACKAGE}}`.
- The `stubbed…Service` used in tests is platform-agnostic (plain in-memory), so it lives in `{{CORE_PACKAGE}}` alongside the interface — only the `live…` half splits by platform.

## Build graph: one core, checked against both targets every time (RC-52)

- `turbo.json`'s `build`/`typecheck`/`test` tasks declare `dependsOn: ["^build"]`, so a change to any file in `{{CORE_PACKAGE}}` or `{{APP_PACKAGE}}` is rebuilt and typechecked against **both** `{{WEB_APP}}` and `{{MOBILE_APP}}` in the same `turbo run` — a Producer signature change that only one app currently exercises still fails typecheck project-wide before merge, not weeks later when the other app happens to touch that screen.
- `{{CORE_PACKAGE}}` and `{{APP_PACKAGE}}` are built **once** per `turbo` invocation and cached — the workspace protocol guarantees both apps consume the exact same build output, not two independently-recompiled copies that could silently diverge.

## Forbidden

- **A slice, Shifter, Selector, or Producer duplicated (even byte-identical) inside `{{WEB_APP}}` or `{{MOBILE_APP}}`** instead of imported from `{{CORE_PACKAGE}}`. "Emitted once" is violated the moment a second copy exists — drift is not a risk, it is a certainty on the next edit to only one copy.
- **`{{CORE_PACKAGE}}` importing `next/*`, `expo-*`, `react-native`, or `react-dom`.** The moment it does, it is no longer safe to hoist into the shared package and one render target's build breaks.
- **A `{{APP_PACKAGE}}` Page importing `next/navigation` or `expo-router` directly** instead of `solito/navigation` / `solito/link` — this re-forks the navigation boundary Solito exists to unify.
- **A platform-specific Service's `live…` implementation imported from `{{CORE_PACKAGE}}` or from the other app's bundle** (e.g. `{{WEB_APP}}` pulling in the `expo-secure-store`-backed `StorageService`).
- **Building a new screen directly inside `{{WEB_APP}}` or `{{MOBILE_APP}}` "for speed," bypassing `{{APP_PACKAGE}}`.** This is the escape hatch that reintroduces exactly the per-platform UI duplication Tamagui and Solito exist to eliminate — a second, undeclared render tree per platform is a defect, not a shortcut.
