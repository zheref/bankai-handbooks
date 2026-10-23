<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 11 — Forbidden Patterns (quick reference)

Reject any PR or generated code that contains a pattern below. This file is the
**single greppable reject list** for the React UZF stack — every other rule file
points back here. Each entry is tagged with its parent cross-platform **`UZF-{n}`**
concept (where one exists) and the React/Redux Toolkit stack binding **`RC-{n}`**
(the React-family analog of the Compose stack's `KT-{n}` / the SwiftUI stack's
`SW-{n}`). Codes are **stable and append-only** — never renumber. An `RC-{n}` may
tighten its `UZF-{n}` parent but never contradicts it.

Recall the key model: React web ({{WEB_APP}}, Next.js App Router) and React
Native/Expo ({{MOBILE_APP}}) **share** the RTK state-logic tier — slices,
reducers, selectors, shifters, producers, services, mappers — in
`{{CORE_PACKAGE}}`. Only the UI render layer differs, so most entries below apply
identically to every render target present; where one is render-target-specific it says so.

## Repo-specific placeholders

| Token | Illustrative value | What it is |
| --- | --- | --- |
| `{{PROJECT_NAME}}` | `Acme` | Product/brand name; also the prefix of product-specific type names. |
| `{{CORE_PACKAGE}}` | `packages/core` | Shared package holding the RTK state-logic tier (slices, selectors, shifters, producers, services, mappers) consumed by every render target present — `{{WEB_APP}}`, `{{MOBILE_APP}}` and, on 2A, `{{DESKTOP_APP}}`. Must stay render-target-free — no JSX, no `next/*`, no `expo-*` imports. |
| `{{WEB_APP}}` | `apps/web` | Next.js App Router application — the web render target. |
| `{{MOBILE_APP}}` | `apps/mobile` | Expo Router application — the React Native (New Arch + Hermes) render target. |
| `{{DESKTOP_APP}}` | `apps/desktop` | Electron application — the desktop render target, on scaffold scenario 2A only (`14-electron-desktop-shell.md`). |

> A token that appears in a rule file MUST be listed here. Adding or renaming a
> token is a Naruto G4 change (keep the generator's substitution map in lockstep).
> Stack-standard libraries (Redux Toolkit, RTK Query, reselect, Immer, Tamagui,
> Solito, Vitest/Jest, React Testing Library, Storybook) are **not** tokenized —
> they are the stack, the same way TCA is fixed on the SwiftUI stack.

---

## Architecture

- Cross-slice state imports — a slice, selector, shifter, or producer in one
  feature importing state or selectors from a sibling feature's slice module
  directly (`import { selectFoo } from '../otherFeature/otherFeatureSlice'`).
  Slices communicate only through selectors composed at the root `RootState`
  level. (UZF-6, UZF-7, RC-20)
- A Component (under `design/`) importing anything from `react-redux`, a slice,
  or a Producer. Components are domain-less and reusable across both render
  targets — RTK knowledge stops at the Fragment/Page boundary. (UZF-5, RC-14)
- A Fragment dispatching an async thunk. Fragments may read state via
  `useAppSelector` but receive intent only through callback props; dispatching
  the Producer-built effect is the Page's job. (UZF-4, UZF-7, RC-15)
- A "god" Page/Feature file mixing more than one slice's worth of reducer logic.
  Almost always means a missing child feature or a missing Producer split.
  (UZF-6, RC-32)

## Electron desktop shell (`{{DESKTOP_APP}}`, scenario 2A only)

- A slice, Selector, reducer or store in the Electron main process, or
  `{{CORE_PACKAGE}}` importing `electron`, `electron-updater`, `better-sqlite3`
  or a Node built-in. The UZF loop runs in the renderer; the main process hosts
  Services, never state. (UZF-6, UZF-16, RC-50, RC-64)
- A `BrowserWindow` created with `nodeIntegration: true`,
  `contextIsolation: false`, `sandbox: false`, `webSecurity: false`,
  `allowRunningInsecureContent: true`, a remote-module shim, or without
  a preload — on any window, dev-only included. (SEC-9, RC-65)
- `ipcRenderer`, `require` or any Node module exposed through `contextBridge`;
  a bridge function that forwards a caller-supplied channel name; a channel
  name typed as a string literal instead of read from the closed
  `DesktopChannels` map in `src/shared/channels.ts`, or that map declared in
  a `.d.ts`. (UZF-16, RC-65)
- A Page or Fragment calling `window.desktop.*`, registering an IPC
  subscription, importing a router directly, or calling `NavigationService`
  itself — the bridge is reached only from a Producer through a
  `live…Service.desktop.ts`, and desktop navigation only by a Producer through
  `NavigationService`. (UZF-16, RC-3, RC-15, RC-17, RC-64, RC-65)
- An `ipcMain.handle` handler or a migration without its ≥3 scenario tests.
  (UZF-18, RC-64)
- A store or slice in a second `BrowserWindow` — a further window is a passive
  view or re-reads a main-process Repository. (UZF-6, RC-64)
- A desktop Page importing `{{APP_PACKAGE}}`, Tamagui, Solito or
  `react-native-web`; a `react-native-web` alias or a `.web.ts` extension in
  the renderer's `electron.vite.config.ts`; Chakra UI imported into
  `{{APP_PACKAGE}}`, `{{CORE_PACKAGE}}` or `{{MOBILE_APP}}`. The desktop
  render layer is desktop-owned and Chakra UI is React DOM only. (UZF-4,
  RC-50, RC-64)
- A desktop Page or Fragment without its ≥3 Storybook stories, a desktop
  Component with store access, or a desktop surface that is not
  keyboard-operable with a visible focus state. (UZF-18, RC-11, RC-14, UX-1,
  UX-2)
- A `Database` opened in the renderer or the preload, a second handle beside
  `main/storage/LocalStoreRepository.ts`, a string-built SQL statement, or a credential
  stored in SQLite / `localStorage` instead of `safeStorage`. (SEC-2, SEC-7,
  RC-68)
- An unsigned or unnotarized artifact uploaded as a release or served by the
  update feed; a signing credential outside CI secrets; a second packager or
  updater beside electron-builder / electron-updater; an update feed over
  plain HTTP or computed from user input; `quitAndInstall()` without a user
  intent event or a quit. (SEC-1, SEC-4, SEC-14, RC-66, RC-67)
- A second `BrowserWindow` opened by a feature outside its feature spec; a
  renderer `Worker` holding feature state; a performance number from a dev
  build or with DevTools attached presented as a budget check. (QA-12, QA-15,
  RC-69)

## React & hooks

- `useState` for anything that's part of feature state inside a Page or
  Fragment. If it needs to survive a re-render for a domain reason, it belongs
  in the slice, not local component state. (UZF-4, RC-4)
- Direct `fetch` / `axios` (or any HTTP client) call from a component or a Page,
  on either render target. Effects are built by Producers; components
  `dispatch(...)` a thunk instead. (UZF-13, UZF-16, RC-3)
- `useEffect(() => { fetch(...) }, [])` (or any variant performing I/O inside an
  effect hook) in a Page. Kick the load off via `dispatch(...Thunk())` from the
  Producer-owned lifecycle event instead. (UZF-12, UZF-13, RC-3)
- Using the `connect()` HOC. Only hooks-based bindings (`useAppSelector` /
  `useAppDispatch`) are permitted. (RC-10)
- Raw `useSelector` / `useDispatch` from `react-redux` instead of the typed
  `useAppSelector` / `useAppDispatch` wrappers. (RC-10)
- A selector defined inline inside a `useAppSelector(state => ...)` arrow
  function instead of a `createSelector` export in `…Selectors.ts`. (UZF-11,
  RC-5)
- Memoizing a list Adapter with a hand-rolled `useMemo`/`useCallback` chain
  instead of `React.memo` + stable keys, where a plain memo would do. (RC-18)

## Redux Toolkit — producers & reducers

- Throwing out of a `createAsyncThunk` payload creator. Normalize every
  outcome — success and failure alike — into `Result<T, …Exception>`; `.rejected`
  exists only as a defensive fallback, never the primary error path. (UZF-14,
  RC-7)
- A Producer (thunk) returning, or a reducer arm consuming, anything other than
  `Result<T, …Exception>` from an effect. (UZF-14, RC-7)
- A Producer that takes the entire `State` (or reaches into `getState()` beyond
  what one effect needs) instead of narrow, explicit inputs (ids, params,
  injected services). (UZF-15, RC-3)
- An action name lacking the `userDid…` / `on…` / `on…Completed` /
  `child…Delegated…` prefix, or named after the effect it triggers
  (`fetchProfile`, `loadData` instead of `userDidPullToRefresh`,
  `onProfileLoadCompleted`). (UZF-2, RC-2)
- A state mutation inside a reducer arm that isn't `Object.assign(state,
  withFoo(state, args))` (or a single primitive assignment) — hand-rolled
  multi-field Immer mutation instead of a pure, unit-tested Shifter. (UZF-10,
  RC-4)
- A `switch`/`if`-chain over an `Exception`'s discriminated cases with no
  terminal `assertNever(...)` exhaustiveness check. (UZF-9, RC-9)
- A reducer arm merged without ≥ 3 scenario-named unit tests in the same PR.
  (UZF-18, RC-12)

## Services & dependency injection

- A `Service` instantiated ad hoc inside a component or a thunk body instead of
  injected via the thunk `extra` argument configured in `configureStore`.
  (UZF-16, RC-6)
- A reducer or a Selector importing a `Service` directly. Only Producers
  receive services (through `extra`); reducers and selectors never see the
  world. (UZF-13, UZF-16, RC-6)
- A new `…Service` (including an RTK Query API slice) without a
  `stubbed…Service` companion **and** a fixture JSON backing it. (UZF-16, RC-33)
- RTK Query auto-generated hooks (`useGetXQuery`, `useCreateYMutation`) called
  directly inside a Page or Fragment on either render target. Expose a Producer
  thunk that delegates to the RTK Query endpoint under the hood instead.
  (UZF-16, RC-16)
- A Page importing anything from `{{CORE_PACKAGE}}/services`. Only Producers
  talk to services. (UZF-13, UZF-16, RC-6)
- Navigation invoked directly from a component (`router.push(...)`,
  `router.navigate(...)`) instead of from a Producer that treats the router as
  a Service. (UZF-16, RC-17)

## Data layer

- Wire-format `…Response` types, raw fetch/axios payloads, or a platform error
  object stored in `State`. Map to a domain type via a Mapper before the
  reducer ever sees it. (UZF-8, UZF-17, RC-24)
- `string` or `Error` used anywhere in `State` (or in a thunk's rejected value)
  to represent a user-facing problem instead of a discriminated `…Exception`
  union. (UZF-8, RC-8)
- Two or more parallel optional fields representing one lifecycle
  (`isLoading` + `error` + `data` as independent optionals) instead of one
  `Status` union (`{ kind: 'loading' } | { kind: 'loaded'; data } | { kind:
  'failed'; exception }`). (UZF-9, RC-24)

## Models & mocks

- Domain models with fewer than 7 `mock` variations in `__mocks__/*.mocks.ts`.
  (UZF-18, RC-13)
- A Page or test constructing `State` inline instead of via the feature's mocks
  file. (UZF-18, RC-31)

## Testing

- A test name that doesn't describe a real scenario (`test_state`, `it('works')`).
  (UZF-20, RC-34)
- Fewer than 3 Storybook stories for a Page/Fragment, or stories that don't
  mirror the same states as the snapshot tests. (UZF-18, RC-11)
- Live `fetch`/`axios` calls (or a live RTK Query base query) reaching the
  network from a Vitest/Jest test instead of the `stubbed…Service`. (UZF-16,
  RC-35)

## Commit messages

- `Co-Authored-By: Claude …`, `Co-Authored-By: GPT …`, `Co-Authored-By: Gemini …`,
  `Co-Authored-By: Copilot …`, or any `Co-Authored-By:` trailer crediting an LLM
  model. Commits are clean Conventional Commits attributed to the human author
  only. (`CONVENTIONS.md` in `bankai-handbooks`)
- Multi-page commit bodies with exhaustive bullet lists rehashing what the diff
  already shows. Subject ≤ 72 chars; the body (when present) is one or two
  short paragraphs explaining the *why*. (`CONVENTIONS.md` in `bankai-handbooks`)
