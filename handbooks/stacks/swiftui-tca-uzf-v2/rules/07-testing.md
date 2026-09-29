<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 07 — Testing

Implements **UZF-18** (per-artifact minimums), **UZF-19** (coverage floor),
**UZF-20** (scenario naming), **UZF-26** (visual evidence). Stack bindings:
**SW-17** (TestStore + direct View snapshots), **SW-18** (snapshot PNGs are the PR
screenshots).

## Repo-specific placeholders

Everything below is generic canon. The tokens are the only repo-local values; a
product repo substitutes its own. Illustrative example values (a fictional product, "Acme")
shown.

| Token | Illustrative value | What it is |
| --- | --- | --- |
| `{{SNAPSHOT_DEVICE}}` | `iPhone 17 Pro` | Reference simulator device for snapshot baselines. |
| `{{SNAPSHOT_OS}}` | `26.5` | Reference iOS version. Baselines recorded on any other OS mismatch on metrics/fonts. |
| `{{SNAPSHOT_DEVICE_CONFIG}}` | `ViewImageConfig` for `{{SNAPSHOT_DEVICE}}` | Snapshot layout config; must correspond to `{{SNAPSHOT_DEVICE}}` (swift-snapshot-testing ships no stock preset for iPhone 17 Pro — supply a matching `ViewImageConfig`). |
| `{{SNAPSHOT_TZ}}` | `UTC` (UTC−5) | Runner timezone for date-rendering snapshots (pinned in CI). |
| `{{XCODEPROJ}}` | `Acme.xcodeproj` | Xcode project. |
| `{{SCHEME}}` | `Acme` | Build/test scheme. |
| `{{APP_TARGET_IOS}}` | `Acme` | `@testable import` module. |
| `{{TEST_TARGET}}` | `AcmeTests` | Unit/snapshot test target root. |
| `{{UI_MODULE}}` | `AcmeUI` | Design/UI module hosting the glass fallback toggle. |
| `{{CI_TEST_WORKFLOW}}` | `.github/workflows/tests.yml` | CI workflow that pins destination + `SNAPSHOT_TZ`. |

---

## Minimums (enforced in review — implements UZF-18)

| Artifact | Minimum | Tool |
| --- | --- | --- |
| Shifter | 3 cases (typical, boundary, no-op) per `mutating func` | `XCTest` / `swift-testing` |
| Selector | 3 cases (typical, edge, empty) per property | `XCTest` / `swift-testing` |
| Reducer arm | 3 scenario tests per non-trivial `Action` case | `TestStore` |
| **View (Screen/View split)** | **3 `#Preview` blocks + 3 snapshot tests matching them**, constructed directly from plain inputs (no Store) | `swift-snapshot-testing` |
| Screen / Fragment | optional 1 wiring smoke-snapshot with a `TestStore`; not a substitute for View-level snapshots | `swift-snapshot-testing` |
| Domain model | 7 mocks under `#if DEBUG` — **3 convenient / 1 neutral / 3 inconvenient** | hand-written |
| Producer / Mapper | covered transitively via `TestStore` (no separate test); a standalone Mapper still needs ≥3 | `TestStore` + `withDependencies` |
| Repository | 3 scenarios per query and mutation, with mocked Clients | `XCTest` / `swift-testing` |

Coverage floor per UZF-19: every touched file ≥80% line coverage; note exemptions
(pure snapshot-covered UI, generated code, mock/DI files) in the PR.

## File layout

```
{{TEST_TARGET}}/Application/UserProfile/
  UserProfileShiftersTests.swift
  UserProfileSelectorsTests.swift
  UserProfileFeatureTests.swift
  UserProfileSnapshotTests.swift
{{TEST_TARGET}}/Services/Network/
  ProfileClientFixtures.swift          // JSON fixtures for stubbedValue
{{TEST_TARGET}}/Mocks/
  Profile+Mock.swift                   // re-exports DEBUG mocks; or live under <Model>+Mocks.swift in production
```

## Shifter test template

```swift
@MainActor
final class UserProfileShiftersTests: XCTestCase {

    func test_applyLoadingStarted_setsLoadingAndClearsException() {
        var state = UserProfileFeature.State(profileId: .init())
        state.exception = .offline
        state.applyLoadingStarted()
        XCTAssertTrue(state.isLoading)
        XCTAssertNil(state.exception)
    }

    func test_applyProfileLoaded_clearsLoadingAndException_andStoresProfile() {
        var state = UserProfileFeature.State(profileId: .init())
        state.isLoading = true
        state.exception = .offline
        state.applyProfileLoaded(.mockTypical)
        XCTAssertEqual(state.profile, .mockTypical)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.exception)
    }

    func test_applyException_preservesPreviousProfile() {
        var state = UserProfileFeature.State(profileId: .init())
        state.applyProfileLoaded(.mockTypical)
        state.applyException(.notFound)
        XCTAssertEqual(state.profile, .mockTypical)
        XCTAssertEqual(state.exception, .notFound)
        XCTAssertFalse(state.isLoading)
    }
}
```

## Selector test template

```swift
final class UserProfileSelectorsTests: XCTestCase {

    func test_shouldShowEmptyStateSelector_whenIdleAndEmpty_isTrue() {
        let state = UserProfileFeature.State(profileId: .init())
        XCTAssertTrue(state.shouldShowEmptyStateSelector)
    }

    func test_shouldShowEmptyStateSelector_whenLoading_isFalse() {
        var state = UserProfileFeature.State(profileId: .init())
        state.isLoading = true
        XCTAssertFalse(state.shouldShowEmptyStateSelector)
    }

    func test_shouldShowEmptyStateSelector_whenProfileLoaded_isFalse() {
        var state = UserProfileFeature.State(profileId: .init())
        state.profile = .mockTypical
        XCTAssertFalse(state.shouldShowEmptyStateSelector)
    }
}
```

## Reducer test template

```swift
@MainActor
final class UserProfileFeatureTests: XCTestCase {

    func test_onViewLoaded_whenSuccess_transitionsToLoaded() async {
        let id = UUID()
        let response = ProfileResponse(id: id.uuidString, name: "Ada", email: "ada@x.io",
                                       avatar: nil, joined_at: "2023-01-01T00:00:00Z")
        let store = TestStore(initialState: UserProfileFeature.State(profileId: id)) {
            UserProfileFeature()
        } withDependencies: {
            $0.profileClient.fetchProfile = { _ in response }
        }
        await store.send(.onViewLoaded) { $0.isLoading = true }
        await store.receive(\.onProfileFetchCompleted) {
            $0.isLoading = false
            $0.profile = response.asDomain
        }
    }

    func test_onViewLoaded_whenOffline_surfacesOfflineException() async {
        let store = TestStore(initialState: UserProfileFeature.State(profileId: .init())) {
            UserProfileFeature()
        } withDependencies: {
            $0.profileClient.fetchProfile = { _ in
                throw URLError(.notConnectedToInternet)
            }
        }
        await store.send(.onViewLoaded) { $0.isLoading = true }
        await store.receive(\.onProfileFetchCompleted) {
            $0.isLoading = false
            $0.exception = .offline
        }
    }

    func test_userDidTapEdit_opensEditDestinationWithCurrentProfile() async {
        let profile: Profile = .mockTypical
        let store = TestStore(
            initialState: {
                var s = UserProfileFeature.State(profileId: profile.id)
                s.profile = profile
                return s
            }()
        ) { UserProfileFeature() }
        await store.send(.userDidTapEdit) {
            $0.destination = .edit(EditProfileFeature.State(profile: profile))
        }
    }
}
```

### TestStore tips

- `withDependencies` overrides exactly what you need. Anything you don't override fails the test on unexpected use (because `@DependencyClient` generated `unimplemented` for `testValue`).
- `store.receive(\.caseKey)` (case-path) works without `Equatable` on the payload. Use this rather than `store.receive(.onFooCompleted(.success(x)))` whenever payloads aren't `Equatable`.
- `await store.finish()` at the end of a test if any non-cancelled effect could still be inflight.
- Use `\.continuousClock` + `clock.advance(by:)` for time-controlled tests instead of waiting on real time.

## Snapshot tests (Screen/View split — SW-17)

Snapshot tests target **`<Name>View` directly**, with plain mock data. There is no Store, no Feature, no dependencies — the test is as cheap as a `#Preview`. Each `#Preview` name maps 1:1 to a `test_<name>` method.

> **These PNGs are also the PR's screenshots (SW-18, implements UZF-26).** The recorded snapshot images double as the mandatory UI screenshots embedded in the PR description — never take separate captures. Per UZF-26's hosting rule, mock-only PNGs are mirrored to the repo's **associated public assets repo** and referenced via SHA-pinned `raw.githubusercontent.com` URLs (a private repo's own raw URLs `404` in GitHub's proxy). The consuming repo binds `{{ASSETS_REPO}}` / `{{ASSETS_LAYOUT}}` (illustrative: `acme/acme-assets`, `Acme/pr-<n>/<scene>.png`).

### Reference environment — {{SNAPSHOT_DEVICE}} · iOS {{SNAPSHOT_OS}} (never Mac Catalyst)

All snapshot baselines are recorded against the **{{SNAPSHOT_DEVICE}} simulator running iOS {{SNAPSHOT_OS}}** — the canonical reference. Re-record only on that environment; a baseline recorded on a different OS (e.g. iOS 18) will mismatch on metrics/fonts and fail CI.

- **Never use Mac Catalyst** as a snapshot reference. `swift-snapshot-testing`'s `UIImage`/`AttachableAsImage` path does not even compile under Mac Catalyst, and it is not an iPhone screen.
- The CI workflow (`{{CI_TEST_WORKFLOW}}`) pins `platform=iOS Simulator,name={{SNAPSHOT_DEVICE}},OS={{SNAPSHOT_OS}}` so local recordings and CI agree. Record locally against the same destination:
  ```bash
  xcodebuild -project {{XCODEPROJ}} -scheme {{SCHEME}} \
      -destination 'platform=iOS Simulator,name={{SNAPSHOT_DEVICE}},OS={{SNAPSHOT_OS}}' \
      -only-testing:{{TEST_TARGET}}/<Name>SnapshotTests test
  ```
- Glass-backed views (anything using `glassEffect` / `.buttonStyle(.glassProminent)`) must opt into `liquidGlassFallback()` and be wrapped in an opaque backdrop in their snapshot test — otherwise they record blank on iOS 26 (see "Snapshot rendering pitfalls" below). The toggle lives in `{{UI_MODULE}}/Environment/LiquidGlassFallback.swift` and any glass view can read `@Environment(\.usesLiquidGlassFallback)`.
- **Timezone for date-rendering views.** Views that render an absolute `Date` through a SwiftUI `DatePicker` display it in the **simulator's timezone**, which equals the host Mac's. `DatePicker` ignores in-process `\.calendar` / `NSTimeZone.default` overrides, so the timezone can't be pinned in the test — the recording machine's timezone IS the reference. CI pins the runner timezone to match via `SNAPSHOT_TZ` in `{{CI_TEST_WORKFLOW}}` (`{{SNAPSHOT_TZ}}`). **Record date-bearing snapshots in that timezone, or update `SNAPSHOT_TZ` to wherever you record.** Locale/format *is* pinnable and should be pinned via `.environment(\.locale, Locale(identifier: "en_US_POSIX"))` so the format is machine-independent.

```swift
import SnapshotTesting
import SwiftUI
import XCTest
@testable import {{APP_TARGET_IOS}}

final class UserProfileSnapshotTests: XCTestCase {

    func test_loaded_typical() {
        let view = UserProfileView(
            displayName: "Ada Lovelace",
            avatarURL: nil,
            isLoading: false,
            exception: nil,
            canEdit: true
        )
        assertSnapshot(of: view, as: .image(layout: .device(config: {{SNAPSHOT_DEVICE_CONFIG}})))
    }

    func test_loading() {
        let view = UserProfileView(
            displayName: "—",
            avatarURL: nil,
            isLoading: true,
            exception: nil,
            canEdit: false
        )
        assertSnapshot(of: view, as: .image(layout: .device(config: {{SNAPSHOT_DEVICE_CONFIG}})))
    }

    func test_offline_exception() {
        let view = UserProfileView(
            displayName: "Ada Lovelace",
            avatarURL: nil,
            isLoading: false,
            exception: .offline,
            canEdit: false
        )
        assertSnapshot(of: view, as: .image(layout: .device(config: {{SNAPSHOT_DEVICE_CONFIG}})))
    }
}
```

Snapshots **must** match the previews of the same View 1:1. Each `#Preview` name lines up with a `test_<name>` method. If previews and snapshots diverge, one of them is wrong.

### Optional: Screen wiring smoke-snapshot

If the Screen's navigation wiring is non-trivial (sheet, scoped action, alert state), one extra snapshot of the Screen with a `TestStore`-style fixture is allowed — but it is *additive*, not a replacement for View-level snapshots. Keep these rare.

### Snapshot rendering pitfalls (iOS 26)

A snapshot run that "passes" or "records cleanly" is not proof the PNG is usable. The recorded image can be **blank** in two distinct ways. Always verify a fresh recording by opening one PNG in your diff viewer before committing.

#### Symptom 1 — every recorded PNG has the same file size

iOS 26's `glassEffect(.regular.tint(...), in: shape)` requires GPU-backed compositing to render. Under offscreen snapshot rendering (the path `swift-snapshot-testing` uses with `UIHostingController` + `drawHierarchy`) it produces an invisible / opaque-white surface, hiding every glass-backed view — pill, toast, FAB, GlassCard, anything else relying on the iOS 26 API.

Telltale: every PNG in `__Snapshots__/<TestClass>/` is **identical bytes**.

```bash
# Quick check from the project root
ls -la {{TEST_TARGET}}/.../__Snapshots__/MySnapshotTests/
# If every PNG is exactly the same size, the glass effect ate the view.
```

**Workaround.** Expose a `liquidGlassFallback()` environment toggle on the glass surface that swaps `glassEffect` for the legacy `.ultraThinMaterial` + tint path. Snapshot tests apply it; production never reads it. The recorded PNG is no longer pixel-identical to production, but it faithfully captures geometry, tint hue, and layout — which is what snapshot tests are for. Live visual fidelity stays the responsibility of `#Preview` + PreviewHost runs.

```swift
// In the View module — keep production untouched.
public struct LiquidGlassFallbackKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    var usesLiquidGlassFallback: Bool {
        get { self[LiquidGlassFallbackKey.self] }
        set { self[LiquidGlassFallbackKey.self] = newValue }
    }
}

public extension View {
    func liquidGlassFallback(_ enabled: Bool = true) -> some View {
        environment(\.usesLiquidGlassFallback, enabled)
    }
}

private struct PillBackground: ViewModifier {
    @Environment(\.usesLiquidGlassFallback) private var usesFallback
    func body(content: Content) -> some View {
        if !usesFallback, #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular.tint(tint), in: shape)
        } else {
            content.background(.ultraThinMaterial).background(tint).clipShape(shape)
        }
    }
}

// In the snapshot test:
let view = AnyView(MyView(...).liquidGlassFallback())
assertSnapshot(of: view, as: .image(layout: .device(config: {{SNAPSHOT_DEVICE_CONFIG}})))
```

#### Symptom 2 — the PNG looks blank in your diff viewer or on GitHub, but file inspection finds real RGB pixels

The PNG is RGBA and every pixel ships with `alpha == 0`. The RGB carries the gradient and view, but any viewer that honors alpha renders the whole image transparent (so it picks up the viewer/page background — typically white in diff tools, transparent on GitHub).

Telltale:

```bash
# Easy: flatten to JPG (no alpha) and the actual content appears.
sips -s format jpeg path/to/snapshot.png --out /tmp/check.jpg
open /tmp/check.jpg

# More precise: walk the PNG bytes and print alpha min/max for two
# scanlines (top row + middle row). Min == 0 across both means the
# whole image is transparent. Min == 255 means it's fully opaque.
# Works on the system Python — no third-party deps.
/usr/bin/python3 - <<'PY' path/to/snapshot.png
import struct, zlib, sys
with open(sys.argv[1], 'rb') as f:
    data = f.read()
pos = 8                                   # skip PNG signature
ihdr = b''
idat = b''
while pos < len(data):
    length = int.from_bytes(data[pos:pos+4], 'big')
    chunk_type = data[pos+4:pos+8].decode('ascii')
    if chunk_type == 'IHDR':
        ihdr = data[pos+8:pos+8+length]
    elif chunk_type == 'IDAT':
        idat += data[pos+8:pos+8+length]
    pos += 8 + length + 4
w = int.from_bytes(ihdr[:4], 'big')
h = int.from_bytes(ihdr[4:8], 'big')
ctype = ihdr[9]
assert ctype == 6, f"not RGBA (ctype={ctype})"
raw = zlib.decompress(idat)
bpp = 4
stride = 1 + w * bpp                      # 1 filter byte + RGBA samples
for label, y in (('top', 0), ('mid', h // 2)):
    row = raw[y * stride + 1 : (y + 1) * stride]
    alphas = [row[i * bpp + 3] for i in range(w)]
    print(f"row {label}: alpha min={min(alphas)} max={max(alphas)} avg={sum(alphas)//len(alphas)}")
PY
```

**Workaround.** Apply an opaque `.background(Color.black)` (or any opaque color — pick something that contrasts so the view content remains visible) *outside* the snapshotted ZStack. The hosting view's CALayer then has an opaque backing, so the recorded PNG ships with `alpha == 255` everywhere.

```swift
private func backdrop<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
    AnyView(
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(...)
            content().padding(...)
        }
        .background(Color.black)   // opaque flatten — fixes alpha=0 snapshots
        .ignoresSafeArea()
        .liquidGlassFallback()     // skip iOS 26 glass — fixes blank glass surfaces
    )
}
```

#### Re-recording: delete the PNGs first

`swift-snapshot-testing` records a new baseline only if no reference exists on disk. When debugging blank snapshots, **`rm` the stale PNGs first** — otherwise the next run silently compares against the broken baseline and reports success ("Test SUCCEEDED") while the file on disk is still wrong.

```bash
rm -f {{TEST_TARGET}}/.../__Snapshots__/MySnapshotTests/*.png
xcodebuild ... -only-testing:{{TEST_TARGET}}/MySnapshotTests test
```

A fresh run always "fails" on the first record-and-write pass with `No reference was found on disk. Automatically recorded snapshot: …`. That's the success signal — open the recorded PNG, eyeball it, then re-run for parity confirmation.

#### Don't skip the visual inspection

Snapshot tests that pass but show blanks regress as silently as a broken assert. Before committing a fresh set of snapshots:

1. `ls -la __Snapshots__/<TestClass>/` — confirm sizes vary (they should differ per scene). All-identical sizes = blank.
2. Open one PNG in the diff viewer (Xcode source control nav, `gh pr` web preview, or just `open path/to.png`). It must render with the expected content against the expected background.
3. Re-run the tests — second run asserts cleanly. If it fails on rerun, the snapshot was non-deterministic (typically a glass effect leaking through — re-check `liquidGlassFallback()`).

> A demonstrated capture-tooling gap (a scene that renders blank/incorrect across multiple genuine strategies) is the only sanctioned skip — mark it `XCTSkip` with a reason referencing a tracked issue and list it per scene in the PR (UZF-26's second, narrow exception). A missing snapshot-capable runner is a runner problem, not a waiver (UZF-26 bankai-mode timed deferral).

## Mocks

```swift
#if DEBUG
extension Profile {
    public static let mockTypical    = Profile(/* … convenient */)
    public static let mockNewUser    = Profile(/* … */)
    public static let mockNoAvatar   = Profile(/* … neutral */)
    public static let mockLongName   = Profile(/* … inconvenient */)
    public static let mockEmptyName  = Profile(/* … inconvenient */)
    public static let mockUnicode    = Profile(/* … inconvenient */)
    public static let mockOldAccount = Profile(/* … convenient, edge */)
}
#endif
```

- The 7 variants must span: **3 convenient** (sunny day), **1 neutral**, **3 inconvenient** (empty, unicode, oversized). (UZF-18 mock split.)
- Mock files are excluded from production builds via `#if DEBUG`.

## What NOT to test

- `liveValue` of a Client (it talks to the network). Test against `testValue` instead, possibly with a `stubbedValue` for end-to-end smoke.
- The View's pixel layout outside snapshot tests. SwiftUI's renderer is Apple's contract, not yours.
- Pure framework code (URLSession, Codable).

## Test naming (implements UZF-20)

`test_<event>_<condition>_<expectation>`. Examples:

- `test_userDidPullToRefresh_whileOffline_surfacesOfflineException`
- `test_withProfileLoaded_clearsLoadingAndException`
- `test_shouldShowEmptyStateSelector_whenProfileLoaded_isFalse`

Reject: `test_action1`, `test_works`, `test_state` — they don't describe a scenario.
