<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 15 — Expo SDK baseline (verified against Expo SDK 55)

## Repo-specific placeholders

- `{{MOBILE_APP}}` — the Expo Router workspace member, e.g. `apps/mobile`. Every command below runs
  from it unless the command says otherwise.
- `{{CORE_PACKAGE}}` — the shared RTK state-logic package, e.g. `packages/core`. It is named only
  where the install layout bears on `RC-50`.

## What was verified, and against what

**Expo SDK 55** is the baseline. It means `expo@55.0.32`, the npm registry's `sdk-55` dist-tag, and
it is the SDK declared on 2026-10-31 by an Expo product built on this stack (one not yet
registered as a consumer). The versions, app configuration and commands **in this file** were
verified that day against two sources: the Expo pages dated below, and the npm registry's `sdk-55`
packages. On 2026-11-01 the commands were also run in a scratch app scaffolded from
`default@sdk-55` (Node 24.16, npm 11.13, Xcode 27, `eas-cli` 27.2.0). The run resolved `expo`
55.0.32, React Native 0.83.10 and React 19.2.0, with the routes in `src/app/`. Every `npx expo install`
line exited 0, `expo-doctor` passed 20 of 20 checks, and a render test passed under Jest 29.7.0,
React Native Testing Library 13.3.3 and `react-test-renderer` 19.2.0. Metro started, and
`npx expo export --platform ios` bundled the app. `eas update` lists `--environment`. The run did not
cover the commands that need an Expo account (`eas login`, `eas build:configure`, `eas build`,
`eas update`). On 2026-11-02 `npx expo run:ios` was run on the same app and failed to build under
Xcode 27. Two pods (`SDWebImage`, `ReachabilitySwift`) set deployment targets below the 15.0 that
Xcode 27 accepts. With those raised to 15.1 in the Podfile, `expo-router`'s own Swift then failed:
"'subtitle' is only available in iOS 16.0 or newer". The Xcode 26.3 on that machine had no iOS 26.2
platform installed, so it built nothing. A native build on SDK 55 is therefore unproven here, and
Xcode 27 does not build it as shipped. This repository renders nothing. Expo's guide pages
(unit testing, Router installation, monorepos, EAS) are unversioned and written for the current
SDK, so each command taken from them was cross-checked against the `sdk-55` packages.

**SDK 55 is not the newest SDK.** SDK 58 was current on the verification date (`expo@latest` →
`58.0.22`). Moving this baseline to a newer SDK re-verifies every row and command below and bumps
`handbooks/VERSION`. Until then, a `{{MOBILE_APP}}` on another SDK reads this file as SDK 55's facts,
not its own.

| What | On Expo SDK 55 | Source (page date) |
| --- | --- | --- |
| React Native | 0.83 | [SDK 55 reference](https://docs.expo.dev/versions/v55.0.0/) (2026-09-17) |
| React | 19.2 | same |
| React Native Web | 0.21 | same |
| Node.js | `^20.19.4`, `^22.13.0`, `^24.3.0` or `^25.0.0` | [SDK 55 changelog](https://expo.dev/changelog/sdk-55) (2026-02-25) |
| Platforms and toolchain | Android 7+, iOS 15.1+, Xcode 26.2 or later 26.x. Xcode 27 does not build the SDK 55 template (run of 2026-11-02, above) | SDK 55 reference (2026-09-17); the 2026-11-02 run |
| Architecture | New Architecture only; the Legacy Architecture is removed | SDK 55 changelog (2026-02-25) |
| JavaScript engine | Hermes. Hermes v1 is opt-in, not the default | SDK 55 changelog (2026-02-25) |
| Expo module versions | the SDK's `expo-*` modules share its major (`expo-router ~55.0.18`, `expo-constants ~55.0.17`). A few packages keep their own lines (`@expo/vector-icons ^15`, `@expo/fingerprint ~0.16`) | SDK 55 changelog; `expo@55.0.32` `bundledNativeModules.json` |
| Unit-test preset | `jest-expo` 55 (`55.0.22`), on Jest 29: it depends on `babel-jest`, `@jest/globals` and `jest-environment-jsdom` at `^29.2.1` | npm registry, `jest-expo@sdk-55` dependencies (read 2026-10-31) |
| Render-test library | `@testing-library/react-native` 13 (`node >=18`, peer `react-test-renderer >=18.2.0`). Release 14 needs Node `^22.13.0 \|\| >=24` | npm registry, `@testing-library/react-native` metadata (read 2026-10-31) |
| Test renderer | `react-test-renderer` 19.2.0: `jest-expo` 55.0.22 depends on exactly that version, and each `react-test-renderer` release peers `react ^<its own version>` | npm registry, `jest-expo@55.0.22` and `react-test-renderer` metadata (read 2026-10-31) |

## App configuration SDK 55 no longer accepts

"New Architecture + Hermes" describes the runtime. It is not a setting to write.

- **`newArchEnabled` is gone.** SDK 55 removed the option from `app.json`, because the New
  Architecture is the only one. A config that still sets it is written for an older SDK.
- **`edgeToEdgeEnabled` is gone too.** SDK 55 removed it as well.
- **Hermes v1 is not switched on by naming it.** It needs `expo-build-properties`' `useHermesV1`,
  together with `buildReactNativeFromSource: true` and a `hermes-compiler` override. The SDK 55
  changelog does not recommend it for Android in monorepos. It also carries a later update that
  reports memory and startup regressions under the opt-in and recommends SDK 57 (`expo@57.0.17` or
  later) for anyone who needs Hermes v1. Nothing in this handbook requires Hermes v1.
- **The route directory is `app/` or `src/app/`.** The SDK 55 default template creates `src/app/`.
  Expo Router also reads a root `app/`, but "only the src/app directory will be used if you have
  both" ([src directory](https://docs.expo.dev/router/reference/src-directory/), 2026-07-28). `RC-44`
  and `RC-45` bind whichever one `{{MOBILE_APP}}` has, and a project has exactly one.
- **Expo writes the monorepo Metro configuration itself.** It has done so since SDK 52. The page
  lists `watchFolders`, `resolver.nodeModulesPath`, `resolver.extraNodeModules` and
  `resolver.disableHierarchicalLookup` as settings to remove from `metro.config.js`, followed by one
  `npx expo start --clear`. pnpm's isolated installs are supported from SDK 54, and the fallback for
  a dependency that breaks under them is `nodeLinker: hoisted` in `pnpm-workspace.yaml`
  ([monorepos](https://docs.expo.dev/guides/monorepos/), 2026-10-16). Under `hoisted`, packages
  `{{CORE_PACKAGE}}` does not declare become resolvable, so the install layout no longer stops an
  `RC-50` violation.

## Commands, as documented for SDK 55

`npx expo install` resolves each package to the version the installed `expo` pins. `pnpm add` and
`npm install` do not. A package outside Expo's pinned set carries its version, or its `@latest`,
explicitly below. Outside that set are `jest`, `@types/jest`, `react-test-renderer`,
`@testing-library/react-native` and the EAS CLI. Unpinned, `jest` and `@types/jest` resolve to 30,
which Expo's unit-testing page requires only from SDK 58, while `jest-expo` 55 is built on Jest 29.
`react-test-renderer` is React Native Testing Library 13's required peer. Pin it at 19.2.0, the
version `jest-expo` 55.0.22 depends on, so one copy installs. Its `latest` peers on a newer React:
npm refuses it with `ERESOLVE`, and pnpm installs a second, mismatched renderer with only a
warning. The pinned set resolves with no peer conflict: a lockfile-only resolution of the SDK 55
template plus the test line below exits 0 under npm 11 and under pnpm 11 with strict peers
(2026-10-31). `npx expo-doctor@latest` declares Node `^22.13.0 || ^24.3.0 || ^26.0.0 || >=27.0.0`,
so on SDK 55's Node 20 and 25 lines it runs with an engine warning at best.

```sh
# New app. Pin the template: a bare `create-expo-app@latest` does not scaffold SDK 55.
npx create-expo-app@latest <path> --template default@sdk-55

# Add or realign a dependency at the version SDK 55 pins.
npx expo install <package>
# Expo Router in an existing app, then set "main": "expo-router/entry" in package.json by hand.
npx expo install expo-router react-native-safe-area-context react-native-screens expo-linking expo-constants expo-status-bar

# Health check after any upgrade.
npx expo-doctor@latest

# Dev server.
npx expo start

# Unit and render tests (RC-53). Then add "jest": { "preset": "jest-expo" } to package.json.
npx expo install jest-expo --dev
npx expo install jest@^29 @types/jest@^29 react-test-renderer@19.2.0 @testing-library/react-native@^13 --dev

# EAS setup, once per project. The CLI is `npm install --global eas-cli`, or `npx eas-cli@latest`.
eas login
eas build:configure         # writes eas.json, including the development profile used below

# Development build: EAS in the cloud (add --local to build on this machine), or no EAS at all.
npx expo install expo-dev-client
eas build --platform ios --profile development
npx expo run:ios            # or: npx expo run:android

# Store builds.
eas build --platform all

# Over-the-air updates: configure once, then publish.
npx expo install expo-updates
eas update:configure
eas update --channel <channel> --message "<message>" --environment <environment>   # --environment is required from SDK 55
```

The command sources are the Expo pages for [unit testing](https://docs.expo.dev/develop/unit-testing/)
(2026-10-13), [Router installation](https://docs.expo.dev/router/installation/),
[EAS Build setup](https://docs.expo.dev/build/setup/) and
[EAS Update](https://docs.expo.dev/eas-update/getting-started/) (each 2026-10-16), the
[development builds](https://docs.expo.dev/develop/development-builds/create-a-build/) page
(2026-09-10), and the SDK 55 changelog for the template flag and `--environment`. The unit-testing
page marks `react-test-renderer` deprecated and without React 19 support. React Native Testing
Library 13 still lists it as a peer, but render tests go through the library's API (`RC-53`) and
never call it directly.
