<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 14 — Electron Desktop Shell (scenario 2A render target)

## Repo-specific placeholders

- `{{PROJECT_NAME}}` — the product name; the npm scope of every workspace package (`@{{PROJECT_NAME}}/core`, `@{{PROJECT_NAME}}/app`). Illustrative example: `Acme`.
- `{{CORE_PACKAGE}}` — the shared RTK state-logic package, e.g. `packages/core`. Every slice, Shifter, Selector, Producer, Service interface + `stubbed…` double, Mapper and domain model lives here and runs **unchanged in the Electron renderer**.
- `{{APP_PACKAGE}}` — the shared Tamagui + Solito render-layer package, e.g. `packages/app`, consumed by `{{WEB_APP}}` and `{{MOBILE_APP}}`. **The desktop shell does not consume it** (maintainer's ruling of 2026-10-22 on BH-IS-#15): the desktop Page layer is desktop-owned, built from Chakra UI, and named here only to say so.
- `{{WEB_APP}}` / `{{MOBILE_APP}}` — the Next.js and Expo Router workspace members, e.g. `apps/web` / `apps/mobile`. Named only where a rule says how the desktop shell differs from them.
- `{{DESKTOP_APP}}` — the Electron workspace member, e.g. `apps/desktop`: the `main/`, `preload/` and `renderer/` entries electron-vite builds and the electron-builder configuration.
- `{{DESKTOP_APP_ID}}` — the reverse-DNS application id electron-builder writes as `appId` (the bundle identifier on macOS, the AppUserModelID on Windows), e.g. `com.acme.desktop`.

**Every `react-uzf-v1` consumer binds `{{DESKTOP_APP}}` and `{{DESKTOP_APP_ID}}`**, whatever its scaffold scenario: every mirrored rule file that uses the token — `08`, `09`, `10`, `11` and this file — is mirrored to every consumer of the stack, and the mirror generator fails closed on an unbound token. A repository that is not on scenario 2A binds both to the values its desktop member *would* take (`apps/desktop`, its reverse-DNS id) and carries no such member; the rules below bind only where the member exists, and a consumer on scenario 1 or 5 is reviewed against them only if it adds one.

(Electron, electron-vite, electron-builder, electron-updater, better-sqlite3, Chakra UI and Playwright are stack names, never tokenised — they are what [`../../../stack-matrix.md`](../../../stack-matrix.md) scenario 2A composes, the way Tamagui and Solito are fixed for the other two targets.)

---

**Decision (BH-IS-#15, recorded in [`README.md`](README.md) → *Reconciliation decisions*):** the
Electron desktop shell of scaffold scenario 2A is a **third render target of `react-uzf-v1`**,
not a scenario of its own. `react-uzf-v1` already spans several platforms as render targets over
one ui-architecture (React 19 + Redux Toolkit) and one shared core (`../architecture.md` § H,
`RC-50`, `RC-51`, `RC-62`); 2A adds one more host — Chromium driven by a Node main process —
to that family. Everything `{{CORE_PACKAGE}}` owns is consumed by the desktop window as the other
targets consume it; the render layer is **desktop-owned** — the maintainer ruled on 2026-10-22 that
2A's Electron renderer renders its own **Chakra UI** layer over the shared core rather than the
Tamagui `{{APP_PACKAGE}}` Page, exactly as `RC-38`–`RC-45` already give Next.js and Expo their own
target-specific layers; what is new is the process boundary a Chromium shell imposes, and that
boundary is what the six rules below fix. This file introduces **RC-64**
(the three-process boundary and where Feature, Store and Service live across it), **RC-65** (IPC
is a Service: typed channels behind a context-isolated preload bridge), **RC-66** (packaging and
signing through electron-builder), **RC-67** (auto-update through electron-updater, surfaced as a
Service), **RC-68** (local storage lives in the main process: better-sqlite3) and **RC-69** (the
desktop performance budget for a Chromium shell). They refine `UZF-6`, `UZF-16`, `UZF-17` and
`UZF-18`–`UZF-20`, and the stack's own `RC-48`, `RC-49`, `RC-50`, `RC-62` and `RC-63`; where a
rule has no `UZF-{n}` parent it says so and names the cross-cutting handbook that governs it, and
where no handbook covers a clause it says that too.

## The three processes, and where Feature, Store and Service live (RC-64; implements `UZF-4`, `UZF-6`, `UZF-16`)

An Electron application is three runtimes, not one, and the UZF loop lives in exactly one of them:

| Process | Runtime | What it holds | What it never holds |
|---|---|---|---|
| **renderer** | Chromium, no Node | the `{{CORE_PACKAGE}}` store built by `makeStore(desktopExtra)` (`RC-22`), every slice, Shifter, Selector and Producer, and the **desktop-owned Chakra UI Page tree** | a Node API, a native module, a file-system path, a database handle, a Tamagui or `{{APP_PACKAGE}}` import |
| **preload** | an isolated world, sandboxed — `contextBridge` and `ipcRenderer` only, no Node built-ins | the one typed bridge object `contextBridge.exposeInMainWorld(...)` publishes (RC-65) | a slice, a store, a Service body, domain logic of any kind |
| **main** | Node | the `BrowserWindow` lifecycle, the OS integration (menus, tray, dialogs, protocol handlers), the main-process **Repositories** that hold a handle or a download (the local store RC-68, the updater RC-67 — `UZF-16`'s stateful service-tier artifact), `ipcMain.handle` handlers | a slice, a store, a Selector, a reducer — the main process is **never a second state tier** |

- **The store runs in the renderer, once, in one window.** `{{DESKTOP_APP}}` owns its Page layer (below), so it is not itself a thin shell; its two entry files are — `renderer/main.tsx` and `main/index.ts` are `RC-62` shells. `main.tsx` builds the store with `makeStore(desktopExtra)` (`RC-22`) from that target's own `live…Service` bindings, wraps the Chakra provider (`<ChakraProvider value={system}>` from `@chakra-ui/react`), and mounts the desktop-owned root Page — param resolution and rendering only, never slice logic. There is no Server Page / Client Wrapper split here (the window is always a client) and no route file.
- **The desktop render layer is desktop-owned, built from Chakra UI, and bound by the stack's Page rules.** `{{DESKTOP_APP}}/src/renderer/features/<Feature>/` holds the desktop `<Feature>Page.tsx`, its Fragments and its stories; `renderer/design/` holds the desktop Components; `renderer/theme/system.ts` holds the one Chakra system (`createSystem(defaultConfig, defineConfig({...}))`, `@chakra-ui/react` **v3**, read at chakra-ui.com on 2026-10-22; installed with `@emotion/react`). Chakra UI is React DOM only — no React Native support (the ruling's note of 2026-10-22) — which is exactly right for Chromium and exactly why it never enters `{{APP_PACKAGE}}` or `{{MOBILE_APP}}`. A desktop Page is the same artifact the stack already defines, on a different primitive set: the three-tier split (`RC-61`), the Page as the only stateful container calling `useAppSelector`/`useAppDispatch` (`RC-37`, `RC-10`), Fragments reading through selectors and never dispatching an async thunk (`RC-15`), domain-less Components under `design/` (`RC-14`), Selectors in `…Selectors.ts` (`RC-5`), effects only through Producers (`RC-3`), memoised Adapters (`RC-18`), ≥3 Storybook stories per Page and Fragment (`RC-11`) backed by `<Feature>Mocks.ts` (`RC-31`), and the platform singletons as the sole native-module boundary (`RC-63`). It is also bound by the always-load UX baseline as any user-visible UI is: `UX-1` (contrast and a visible focus state), `UX-2` (keyboard-operable with accessible names — a desktop user's primary input), `UX-5` (semantic design tokens, never raw literals — Chakra's system tokens are those tokens on this target), `UX-9` (motion honouring reduced-motion) and `UX-13` (adapt the desktop idiom, mirror the product). A desktop Page dispatches the same actions, reads the same Selectors and triggers the same Producers as the Tamagui Page of the same feature on the other targets — only the markup is its own.
- **Navigation on desktop is the imperative half only.** The electron-vite renderer has no Next.js router behind it and no Solito: every navigation on desktop goes through the injected `NavigationService` (`RC-17`, `RC-63`), whose desktop binding is built over an in-renderer memory or hash history at `renderer/main.tsx` — the one file that may import that router (`RC-63`) — and a desktop Page's link is a Chakra element whose activation **dispatches an action**; the Producer that handles it calls `NavigationService` (`RC-17`). A Page or Fragment that imports a router, or calls `NavigationService` itself, on this target as on the others, is the `RC-17` violation.
- **`{{CORE_PACKAGE}}` stays framework-blind (`RC-50`): it never imports `electron`, `electron-updater`, `better-sqlite3` or any Node built-in.** A slice or Producer that needs the desktop host (a file, the database, the updater, a native dialog) reaches it only through a Service interface declared in `{{CORE_PACKAGE}}`, whose desktop `live…` binding is the renderer-side bridge client of RC-65. The main process is a *Service host*, not a Feature host.
- **A second window is never a second store.** A single renderer holds the store; a further `BrowserWindow` (RC-69 admits one only as a recorded product decision) is a **passive view**: it mounts no store and no slice, renders Components and Fragments from props it receives over the bridge (RC-65) from the window that owns the store, and sends intent back the same way — or, where two windows genuinely share mutable truth, that truth moves into a main-process Repository that each window's Producer re-reads through a Service, and the slice holds a projection of it, never a second source. A slice instantiated in two renderers is the duplication `08`'s *Forbidden* list names, with a process boundary added.
- **`{{DESKTOP_APP}}` is the member scenario 2A adds, and only 2A.** `RC-49`'s member set is per scaffold scenario — scenario 1: `{{CORE_PACKAGE}}`, `{{APP_PACKAGE}}`, `{{WEB_APP}}`, `{{MOBILE_APP}}`; **scenario 2A: `{{CORE_PACKAGE}}`, `{{APP_PACKAGE}}`, `{{MOBILE_APP}}`, `{{DESKTOP_APP}}`, plus `{{WEB_APP}}` if web is added later**; scenario 5's composition is settled by the separate canon issue on web styling (the matrix's 5 names Tailwind + shadcn/ui, not Tamagui or Solito, so its set is a `bankai:handbook-question`, not asserted here). `{{DESKTOP_APP}}` depends on `{{CORE_PACKAGE}}` through `workspace:*` — **not on `{{APP_PACKAGE}}`**, whose Tamagui layer it does not consume — and is depended on by nothing; `{{APP_PACKAGE}}` stays in the 2A set because `{{MOBILE_APP}}` consumes it. The build graph rule (`RC-52`) then typechecks `{{CORE_PACKAGE}}` against every render target present.
- **One `electron.vite.config.ts` declares the three entries** (`main`, `preload`, `renderer`), each with its own bundle; the renderer bundle is built with the browser platform target and carries **no `react-native-web` alias** — nothing from Tamagui or `{{APP_PACKAGE}}` is resolved into it.
- **Desktop Service bindings are injected explicitly; nothing is resolved by extension.** `RC-48`'s `.web.ts` / `.native.ts` forks are siblings inside `{{CORE_PACKAGE}}` resolved by the Next.js and Metro bundlers; the Electron renderer uses neither, so it does **not** add `.desktop.ts` to `resolve.extensions`, never resolves a `.web.ts` variant, and never relies on `makeStore`'s default `extra`. Instead `renderer/main.tsx` builds `desktopExtra`, typed as the stack's closed `ThunkExtra` manifest (`RC-21`), by importing each desktop binding **by name**: for every Service `RC-48` forks (storage, secrets, system integrations), the `{{DESKTOP_APP}}/src/renderer/services/live<Name>Service.desktop.ts` bridge client (a plain file, named by convention, imported by path); for every platform-neutral Service, the shared `live<Name>Service` from `{{CORE_PACKAGE}}`. The fall-through is total and mechanical: a forked Service with no `desktopExtra` entry is a **typecheck failure** against `ThunkExtra`, never a silent fallback to a web or native fork.
- **Tests (`UZF-18`, `UZF-19`, `UZF-20`; toolbox `RC-53`).** Every `ipcMain.handle` handler and every migration (RC-68) carries ≥3 scenario-named tests under Vitest — a handler against a stubbed `ipcMain` and a stubbed Repository, a migration against a throwaway database — and the touched-file coverage floor applies to the main process as to the core. Only `main/index.ts` and `renderer/main.tsx` are testing-exempt, as `RC-62` shells, the way `RC-57` exempts the Server Page and the Client Wrapper.

```
apps/desktop/                          # {{DESKTOP_APP}}
  electron.vite.config.ts              # main + preload + renderer entries
  electron-builder.yml                 # appId: {{DESKTOP_APP_ID}}; mac/win targets; publish feed (RC-66)
  src/
    shared/
      channels.ts                      # DesktopChannels — the closed `as const` map, a real module (RC-65)
    main/
      index.ts                         # app lifecycle, BrowserWindow, menu, protocol handlers (RC-62 shell)
      ipc/<Name>Handlers.ts            # ipcMain.handle(...) per channel group (RC-65)
      storage/LocalStoreRepository.ts  # the one better-sqlite3 Database (RC-68) — a Repository
      update/UpdateRepository.ts       # electron-updater wiring (RC-67) — a Repository
    preload/
      index.ts                         # contextBridge.exposeInMainWorld('desktop', api) (RC-65)
      api.d.ts                         # the bridge's TypeScript surface (DesktopApi), shared with the renderer
    renderer/
      index.html
      main.tsx                         # makeStore(desktopExtra) + <ChakraProvider value={system}> + the root Page (RC-62 shell)
      theme/system.ts                  # createSystem(defaultConfig, defineConfig({...})) — the one Chakra system (UX-5)
      design/                          # desktop Components — Chakra primitives, domain-less (RC-14)
      features/<Feature>/
        <Feature>Page.tsx              # desktop-owned Page: useAppSelector/useAppDispatch from {{CORE_PACKAGE}} (RC-37)
        <Feature>Page.stories.tsx      # ≥3 stories from <Feature>Mocks.ts (RC-11, RC-31)
        <Feature>Fragment.tsx          # selector reads, callback props, never a thunk (RC-15)
      services/live<Name>Service.desktop.ts   # bridge clients (RC-48 desktop fork), imported by name into desktopExtra — never resolved by extension (RC-65)
```

## IPC is a Service: typed channels behind a context-isolated bridge (RC-65; implements `UZF-16`, `UZF-17`; refines `RC-48`)

Every crossing between the renderer and the main process is an **Operation on a Service**, never
an ad-hoc message. The pattern is `RC-48`'s platform fork with the desktop `live…` file being a
bridge client:

- **Window hardening is not optional and is not configurable per window.** Every `BrowserWindow` is created with `webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, preload: <the preload bundle> }`. `nodeIntegration: true`, `contextIsolation: false`, `webSecurity: false`, `allowRunningInsecureContent: true` and a remote-module shim are forbidden on every window, including a dev-only one — a renderer that can reach Node turns every XSS into remote code execution on the user's machine. `SEC-9`'s words apply as written: *no broad or speculative capability grants* — Node in the renderer is exactly such a grant, and a window takes only the capability the feature uses.
- **The preload exposes one narrow, typed object and nothing else.** `contextBridge.exposeInMainWorld('desktop', api)` publishes a plain object of functions, each wrapping exactly one `ipcRenderer.invoke(channel, payload)`; it never exposes `ipcRenderer` itself, never a function that forwards an arbitrary channel name, and never a Node module. `preload/api.d.ts` declares that object's type (`DesktopApi`) and is the **only** type the renderer imports from the preload.
- **Channel names are a closed, typed map in a real module.** `src/shared/channels.ts` exports `DesktopChannels` as one `as const` object, imported by the main process's handlers and by the preload — a value, so it exists at runtime (a `.d.ts` carries types only and is erased). A string literal typed at an `invoke`/`handle` call site is a review-reject. Each channel carries a wire `…Request`/`…Response` pair in the sense of `RC-29`: they cross the process boundary as structured-clone data, and the **Producer's** Mapper (`RC-30`) turns the response into a domain type — the live Service takes and returns wire shapes, as every live Service does (`RC-6`, `RC-33`), and never maps.
- **Request/response only, from the renderer.** `ipcRenderer.invoke` ↔ `ipcMain.handle` is the one admitted shape for a renderer-initiated Operation; the fire-and-forget `ipcRenderer.send` / `ipcMain.on` pair is reserved for main-initiated events (the updater's progress, a tray action, an OS theme change), and those arrive in the renderer only as a subscription the bridge exposes (`onUpdateDownloaded(cb)`) that a Producer turns into a dispatched event (`RC-3`) — never a listener registered inside a Page.
- **The main-process handler validates before it acts.** Every `ipcMain.handle` validates the payload's shape (`SEC-7`: untrusted input is validated), checks `event.senderFrame` is the application's own top-level frame, and returns a wire `…Response` or a wire error the Producer's Mapper turns into an `…Exception` (`RC-8`) — it never throws across the bridge and never returns a raw `Error`.
- **The desktop `live…Service` is the bridge client; the stub stays shared.** `live<Name>Service.desktop.ts` calls `window.desktop.<op>(...)` and nothing else; `stubbed<Name>Service` is the same in-memory double `{{CORE_PACKAGE}}` already ships (`RC-33`, `RC-48`). Unit tests of a renderer Service run against a stubbed `window.desktop`; unit tests of a main-process handler run under Vitest with a stubbed `ipcMain` (≥3 per handler, RC-64); the end-to-end path runs under Playwright's Electron driver (the `react-uzf-v1` (Electron) row of [`../../../quality-baseline.md`](../../../quality-baseline.md) → *Tooling matrix*).

```ts
// src/shared/channels.ts — a value, imported by main and preload
export const DesktopChannels = {
  profileRead: 'profile:read',
  profileWrite: 'profile:write',
  updateCheck: 'update:check',
} as const;
```

```ts
// src/preload/api.d.ts — the one surface the renderer sees (types only)
export interface DesktopApi {
  profileRead(req: ProfileReadRequest): Promise<ProfileReadResponse>;
  profileWrite(req: ProfileWriteRequest): Promise<ProfileWriteResponse>;
  updateCheck(): Promise<UpdateCheckResponse>;
  onUpdateDownloaded(cb: (info: UpdateDownloadedEvent) => void): () => void;
}
declare global { interface Window { desktop: DesktopApi } }
```

```ts
// src/renderer/services/liveProfileStorageService.desktop.ts — a bridge client, RC-48 fork
// Wire in, wire out: the Producer's ProfileMapper does toDomain/fromDomain (RC-30).
export const liveProfileStorageService: ProfileStorageService = {
  read: (req: ProfileReadRequest) => window.desktop.profileRead(req),
  write: (req: ProfileWriteRequest) => window.desktop.profileWrite(req),
};
```

## Packaging and signing (RC-66; no `UZF-{n}` parent — governed by `SEC-1` and `SEC-14` where they speak, and by the release policy)

electron-builder is the one packager, and a release artifact is signed or it is not a release
artifact:

- **One `electron-builder.yml` in `{{DESKTOP_APP}}`** declares `appId: {{DESKTOP_APP_ID}}`, `asar: true`, the macOS target (`dmg`, hardened runtime, notarization on) and the Windows target (`nsis` → `.exe`, or `msi`, Authenticode-signed), exactly the artifacts scenario 2A names. A second packager (`electron-packager`, `electron-forge`) beside it is forbidden: two packagers produce two artifact sets with two signing paths.
- **Signing and notarization run only in CI, from secrets.** The Apple Developer ID certificate, the notarization credentials and the Windows code-signing certificate are CI secrets (`SEC-1`: never in source, history or logs; `SEC-14`: *secrets are scoped to the least workflow that needs them* — the packaging workflow alone), consumed on `macos-latest` and `windows-latest` runners as the matrix's CI line states. A local `electron-builder` run produces an **unsigned** build for the developer's own machine and for pull-request E2E runs (the `QA-7` row) and is never uploaded, attached to a release or fed to the updater.
- **The build is reproducible from the lockfile and the pinned Electron.** `electron`'s version is pinned exactly (not a caret range) in `{{DESKTOP_APP}}/package.json`, as electron-builder requires to resolve the matching binary; native modules (better-sqlite3, RC-68) are rebuilt against that Electron ABI by electron-builder's `npmRebuild` / `@electron/rebuild`, never shipped prebuilt against Node. The CI workflow installs with a frozen lockfile. (No `SEC-{n}` states the exact-pin or rebuild clause; both are this rule's own.)
- **An unsigned or unnotarized artifact fails the release, it does not ship with a warning.** The CI job asserts the signature after packaging (`codesign --verify --deep --strict` and `spctl --assess` on macOS, `signtool verify /pa` on Windows) and fails closed; a Gatekeeper or SmartScreen prompt on first launch of a release build is a finding against this rule, never a known limitation.

## Auto-update (RC-67; implements `UZF-16`; governed by `SEC-4` for the feed; refines `RC-3`, `RC-65`)

electron-updater is the one update mechanism, it runs in the main process, and the renderer learns
about it only through a Service:

- **The feed is what electron-builder published.** `electron-updater` consumes the `latest-mac.yml` / `latest.yml` manifests and the signed artifacts of RC-66, from the `publish` provider the builder configuration names (GitHub Releases, or a generic HTTPS server) — over HTTPS only (`SEC-4`), and never from a feed the application computes at runtime from user input. Differential (`blockmap`) updates are on; a full download is the fallback, not the default.
- **The updater is a main-process Repository, `{{DESKTOP_APP}}/src/main/update/UpdateRepository.ts`, and lives nowhere else** — it holds the download and the check state, which is what makes it a Repository rather than a Service (`UZF-16`). `autoUpdater.checkForUpdates()` is called on launch and on a user-initiated check; `autoDownload` is set deliberately (on by default for a background download); install is **never silent**: `quitAndInstall()` runs only on an explicit user intent event or at the next quit, so a user never loses in-flight work to an update.
- **The renderer sees an `UpdateService`, not the updater.** The bridge (RC-65) exposes `updateCheck()`, `updateInstall()` and the `onUpdateAvailable` / `onUpdateDownloaded` / `onUpdateError` subscriptions; the renderer's `liveUpdateService.desktop.ts` wraps them, a Producer (`checkForUpdatesThunk`, `userDidAcceptUpdate…`) dispatches the lifecycle into an `updates` slice through its Shifters, and the Page renders the state (`RC-3`, `RC-4`). A Page or Fragment that subscribes to update events directly, or calls `window.desktop.updateInstall()` from an `onClick`, is the `RC-15`/`RC-17` violation in desktop clothing. On `{{WEB_APP}}` and `{{MOBILE_APP}}` the same `UpdateService` interface binds to a no-op or to the platform's own mechanism (EAS Update on mobile) — the slice never knows which.
- **A failed signature check aborts the update and is reported, never retried silently.** electron-updater verifies the downloaded artifact's signature against the running application's (macOS and Windows); an `error` event with a verification failure is a finding against this rule, never a retry loop. (No `SEC-{n}` states an update-feed integrity clause; whether one belongs in the security baseline is a `bankai:handbook-question`, not this rule's to decide.)

## Local storage lives in the main process: better-sqlite3 (RC-68; implements `UZF-16`; refines `RC-48`)

better-sqlite3 is a synchronous native module, and the renderer has no Node, so there is exactly
one place it can run:

- **One `Database` handle, opened once, by the main-process Repository `{{DESKTOP_APP}}/src/main/storage/LocalStoreRepository.ts`, at `path.join(app.getPath('userData'), '<name>.sqlite')`** — a Repository because it holds the handle (`UZF-16`). The renderer never opens, imports or paths a database; every read and write is an Operation on a `StorageService`-shaped interface in `{{CORE_PACKAGE}}` whose desktop `live…` half is a bridge client (RC-65) and whose main-process handler calls the Repository. This is `RC-48`'s storage fork — `expo-sqlite` on `{{MOBILE_APP}}`, browser storage on `{{WEB_APP}}`, better-sqlite3 behind the bridge on `{{DESKTOP_APP}}` — behind one shared interface and one shared stub.
- **Schema migrations are versioned, idempotent and applied at open.** The Repository applies numbered migrations in order inside a transaction and records the applied version (`PRAGMA user_version`); a schema change ships with its migration and its ≥3 tests (RC-64) in the same PR, and a migration is never edited after it has shipped — the same discipline `UZF-25` fixes for the shared backend schema, applied to the local store.
- **Queries are prepared and parameterised, never string-built** (`SEC-7`); the handler returns wire rows (`…Response`) that the Producer's Mapper turns into domain models (`RC-29`, `RC-30`). A synchronous better-sqlite3 call blocks the main process's event loop, so a query the primary flow waits on stays within RC-69's main-process reading — a long scan moves to a prepared statement with an index, or to a `utilityProcess` worker, never to the renderer.
- **Secrets never go in the database.** A token, a key or a credential is stored through Electron's `safeStorage` (`encryptString` / `decryptString`, backed by the OS keychain or DPAPI) behind the same bridge, as `SEC-2` requires of a platform keystore; better-sqlite3 holds domain data only, and `SEC-8`'s data-minimisation applies to what is persisted at all.

## The desktop performance budget for a Chromium shell (RC-69; no `UZF-{n}` parent — governed by `QA-11`, `QA-12`, `QA-13`, `QA-15`)

A Chromium shell carries the weight scenario 2A's trade-off line names, and the budget turns those
numbers into a gate. The seven metrics are `QA-11`'s, measured by the `react-uzf-v1` (Electron) row
of the *Measurement matrix*; the regression-relative gate is `QA-13`'s. The absolute ceilings a
desktop target adds, floored on the matrix's own trade-off line, are:

| Metric | Ceiling | Where it is read |
|---|---|---|
| **P1** cold launch → first interactive window | **≤ 2000 ms** median (`QA-13`'s absolute) | `app.whenReady()` → the first window's `ready-to-show` plus the renderer's navigation timing, under Playwright's Electron driver |
| **P2** warm launch / foreground resume | regression-relative only (`QA-13`) | the window's `restore` / `show` (from the tray or minimised) → the renderer's next painted frame, under the same driver |
| **P4** peak resident memory, **summed across main + renderer + GPU** | **≤ 300 MB** on the primary flow | `app.getAppMetrics()` working-set high-water |
| **P5** shipped artifact size, per platform installer | **≤ 200 MB** (`.dmg`, `.exe`/`.msi`) | the electron-builder artifact on disk |
| **P7** longest main-thread block | **INP ≤ 200 ms** (`QA-13`'s web ceiling, since the renderer is Chromium) | INP via the Event Timing API (`web-vitals`' `onINP` in the renderer under the driver); long-task entries and the main process's `perf_hooks.monitorEventLoopDelay` are the **diagnosis** beside it (`QA-12`), not a second metric — a synchronous better-sqlite3 call (RC-68) shows up there |

- **One window, one renderer, by default.** A second `BrowserWindow` is a deliberate product decision recorded in the feature spec (`UZF-21`), not a convenience — each renderer costs the P4 budget again, and it is a passive view, never a second store (RC-64). `backgroundThrottling` stays on; a window hidden to the tray does not keep animating.
- **Heavy work leaves the renderer.** CPU-bound work on the primary flow (parsing, indexing, image work) runs in the main process or a `utilityProcess` and reaches the renderer as a Service result, never as a renderer `Worker` holding a copy of the state — the renderer's job is the Page.
- **The budget is measured, not estimated** (`QA-15`): Release build, signed artifact, no DevTools attached, n ≥ 5 runs with the first discarded, median and p90, on the recorded reference machine. A number from a dev build or with DevTools open is a diagnostic, never a budget check (`QA-12`).

## Forbidden

- A `BrowserWindow` created with `nodeIntegration: true`, `contextIsolation: false`, `sandbox: false`, `webSecurity: false`, `allowRunningInsecureContent: true`, a remote-module shim, or without a preload — on any window, including a dev-only one (`RC-65`, `SEC-9`).
- `ipcRenderer`, `require`, or any Node module exposed through `contextBridge`, or a bridge function that forwards a caller-supplied channel name (`RC-65`).
- A channel name typed as a string literal at an `invoke`/`handle` call site instead of read from `DesktopChannels` in `src/shared/channels.ts`; `DesktopChannels` declared in a `.d.ts` (`RC-65`).
- A Page or Fragment calling `window.desktop.*` directly, registering an IPC subscription, importing a router, or calling `NavigationService` itself — the bridge is reached only through a `live…Service.desktop.ts` from a Producer, and navigation only by a Producer through `NavigationService` (`RC-3`, `RC-15`, `RC-17`, `RC-64`, `RC-65`).
- A slice, Selector, reducer or store in the main process; a store in a second window; `{{CORE_PACKAGE}}` importing `electron`, `electron-updater`, `better-sqlite3` or a Node built-in (`RC-50`, `RC-64`).
- A desktop Page importing `{{APP_PACKAGE}}`, Tamagui, Solito or `react-native-web`; a `react-native-web` alias or a `.web.ts` extension in the renderer's `electron.vite.config.ts`; Chakra UI imported into `{{APP_PACKAGE}}`, `{{CORE_PACKAGE}}` or `{{MOBILE_APP}}` (`RC-64`, `RC-50`).
- A desktop Page or Fragment without its ≥3 stories, a desktop Component outside `renderer/design/` with store access, or a desktop surface that fails keyboard operation or the focus-state rule (`RC-11`, `RC-14`, `UX-1`, `UX-2`).
- A `Database` opened in the renderer or in the preload; a second `Database` handle beside the one `LocalStoreRepository` holds; a string-built SQL statement (`RC-68`, `SEC-7`).
- A credential or token stored in SQLite, `localStorage` or a plain file instead of `safeStorage` (`RC-68`, `SEC-2`).
- An unsigned or unnotarized artifact uploaded as a release or served by the update feed; a signing certificate or notarization credential anywhere but CI secrets (`RC-66`, `SEC-1`).
- A second packager or a second updater beside electron-builder / electron-updater; an update feed URL computed from user input or served over plain HTTP; `quitAndInstall()` called without a user intent event or a quit (`RC-66`, `RC-67`).
- A `BrowserWindow` opened by a feature outside the feature spec; a renderer `Worker` holding feature state; a performance number from a dev build presented as a budget check (`RC-69`).
- An `ipcMain.handle` handler or a migration without its ≥3 scenario tests (`RC-64`, `UZF-18`).
