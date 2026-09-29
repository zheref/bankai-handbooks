<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 09 — Testing

Implements **UZF-18** (per-artifact minimums), **UZF-19** (coverage floor),
**UZF-20** (scenario naming), **UZF-26** (visual evidence). Stack binding:
**KT-22** (JUnit5 + Turbine + Paparazzi). The artifacts under test are the ones
defined by their own rules — Shifters (**KT-6**), Selectors (**KT-7**), Producers
(**KT-8**), Effects/`uiEffects` (**KT-8**/**KT-9**), Pages (**KT-1**/**KT-18**),
Services (**KT-10**), and Mappers (**KT-20**).

## Repo-specific placeholders

Everything below is generic canon. The tokens are the only repo-local values; a
product repo substitutes its own. Illustrative example values (a fictional product, "Acme")
shown.

| Token | Illustrative value | What it is |
| --- | --- | --- |
| `{{TEST_TARGET}}` | `app/src/test/java` | Kotlin unit + snapshot test source root. |
| `{{APP_PACKAGE}}` | the app's root package | App's root Kotlin package, in directory form under the test root. |
| `{{SNAPSHOT_DEVICE}}` | `PIXEL_5` | Paparazzi reference `DeviceConfig` device for snapshot baselines. |
| `{{DI_FRAMEWORK}}` | `Hilt` | DI framework that binds the `Stubbed…Service` used in tests. |
| `{{CI_TEST_WORKFLOW}}` | `.github/workflows/build-test.yml` | CI workflow running the JVM test + Paparazzi suite. |

---

## Minimum coverage per feature (enforced in review — implements UZF-18)

| Artifact | Tests required |
| --- | --- |
| Shifter | ≥ 3 cases per function (typical / boundary / no-op), each annotated with a real-world scenario in the test name |
| Selector | ≥ 3 cases (typical / edge / empty) |
| Producer method | ≥ 3 cases (happy / failure / edge) using Stubbed Services |
| Feature | ≥ 3 cases per `Event` case, via Turbine on `state` and `uiEffects` |
| Page | ≥ 3 Paparazzi snapshots matching the `@Preview` count |
| Service | Stubbed counterpart + scenario-based integration tests (Live impl smoke-tested) |
| Mapper | ≥ 3 cases for `toDomain`, `fromDomain`, `toException` each |
| Model | ≥ 7 mock variants (see [`07-models-mocks-mappers.md`](07-models-mocks-mappers.md)) |

Coverage floor per **UZF-19**: every touched file ≥ 80 % line coverage; note
exemptions (pure snapshot-covered UI, generated code, mock/DI files) in the PR.

## Toolbox

- JUnit 5 (`junit-jupiter`), `kotlinx-coroutines-test`, `app.cash.turbine`,
  `app.cash.paparazzi`, MockK.
- A reusable `MainDispatcherRule` (JUnit 5 extension or JUnit 4 rule) under the test
  source root (`{{TEST_TARGET}}/{{APP_PACKAGE}}/test/`).
- A `Stubs.kt` file aggregating pre-canned Stubbed Service instances.
- A `<Feature>Mocks.kt` per feature for canned `State` variants — **both previews and
  snapshot tests consume the same source** (never construct `State` inline; KT-18).

## Test file naming

```
<Feature>ShiftersTest.kt
<Feature>SelectorsTest.kt
<Feature>ProducerTest.kt
<Feature>FeatureTest.kt
<Feature>PageSnapshotTest.kt
<Feature>MapperTest.kt
```

## Patterns

### Shifter / Selector / Mapper tests

Pure. No dispatcher, no Turbine, no mocks. The test name encodes the real-world
scenario (UZF-20):

```kotlin
@Test fun `withLoading clears exception — pull to refresh after a previous error`() { … }
```

### Producer tests

Use the `Stubbed<X>Service`. Collect dispatched events into a list. Assert. The
Producer never throws — a failure surfaces as `Result.failure` dispatched as a single
completion event (KT-8), so the "failure" case asserts on that event, not on a thrown
exception.

### Feature tests

Construct the Feature directly with stubs (no `hiltViewModel()` in tests). Drive it
through the single `onEvent` entry point and observe both `state` and `uiEffects` with
Turbine:

```kotlin
sut.state.test {
    assertEquals(UserProfileState(), awaitItem())
    sut.onEvent(UserProfileEvent.OnAppeared)
    assertEquals(LoadState.Loading, awaitItem().load)
    assertEquals(1, (awaitItem().load as LoadState.Loaded).data.size)
    cancelAndIgnoreRemainingEvents()
}
```

One-shot navigation/snackbar signals are asserted the same way against the
`uiEffects` `SharedFlow` (KT-9).

### Snapshot tests

Snapshot tests target the **stateless `<Feature>Page`** directly, fed a canned `State`
from `<Feature>Mocks` — no Feature, no DI, no dispatcher. Each `@Preview` maps 1:1 to a
snapshot test; if previews and snapshots diverge, one of them is wrong.

```kotlin
@get:Rule val paparazzi = Paparazzi(deviceConfig = DeviceConfig.{{SNAPSHOT_DEVICE}})

@Test fun `loading state`() = paparazzi.snapshot {
    AppTheme { UserProfilePage(state = UserProfileMocks.loadingState, onEvent = {}) }
}
```

Paparazzi renders on the JVM (no emulator), so snapshots stay hermetic and run in the
same JUnit pass as the logic tests.

> **The recorded Paparazzi PNGs double as the PR's mandatory UI screenshots
> (UZF-26 / KT-22).** Record one per user-visible state, mirroring the preview/snapshot
> set 1:1 — never take separate captures. Hosting/mirroring mechanics for the PNGs live
> in [14-ui-screenshots.md](14-ui-screenshots.md).

## Mocks

Domain models ship **≥ 7 `mock…` fixtures** in a `companion object`, spanning: **happy,
empty, long, non-ASCII, missing optional fields, stale-timestamp, just-updated**. The
fixtures live in the same file as the model, inside a `// region Mocks` band so a Detekt
rule can strip them from production builds if desired.

Per-feature `<Feature>Mocks.kt` files produce the canned `State` variants
(`loadingState`, `loadedState`, `erroredState`, `partiallyLoadedState`, …) that both
previews and snapshot tests consume — a single source of truth for every rendered state
(KT-18).

## What NOT to test / Forbidden

- **Robolectric for unit-test layers.** Use Paparazzi for hermetic snapshots; use JVM
  JUnit for logic.
- **`runBlocking`** — use `runTest` (from `kotlinx-coroutines-test`).
- **Hand-constructed mocks-of-mocks.** If MockK feels heavy, write a small handwritten
  stub.
- **Tests that construct `<Feature>State` inline** instead of via `<Feature>Mocks`.
- **Tests that hit Retrofit or Room directly** without a Stubbed boundary — go through
  the `Stubbed<X>Service` (KT-10).
- **The `Live<X>Service`'s real I/O** — it talks to the network/DB. Test against the
  `Stubbed` counterpart; smoke-test the Live impl only.
- **Tests gated on `@Ignore`** for longer than the PR that introduced them. Either
  delete or fix.

## Test naming (implements UZF-20)

Every test name encodes a real-world scenario, not a mechanical label. Backtick names
read as a sentence: `` `withLoading clears exception — pull to refresh after a previous
error` ``. Reject `test1`, `works`, `state` — they don't describe a scenario.

## Enforcement

Beyond review, wire these into CI (`{{CI_TEST_WORKFLOW}}`) and a Detekt/Konsist ruleset:
fail the build when a `@Composable` Page is missing its `@Preview`s, when `runBlocking`
appears outside test code, or when `Retrofit`/`Room` are imported outside the services
layer.
