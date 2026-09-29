# Stack: `swiftui-tca-uzf-v2` — SwiftUI + TCA Architecture Handbook

> **Operational rule files:** this handbook is the condensed, ID'd (`SW-{n}`) form. The full
> operational rules an agent follows day-to-day live in [`rules/`](rules/) (the canonical set a
> consumer repo mirrors into each agent surface's rules location, `CON-13`); repo-specific values
> are [`rules/placeholders.md`](rules/placeholders.md).


Concrete UZF bindings for **SwiftUI + The Composable Architecture (TCA 1.13+),
Swift 6, iOS 17+/macOS**, under **UZF v2 (Screen/View split)**. Sasuke cites these
as `SW-{n}`. They **implement** the cross-platform rules in
[`../../uzf-core.md`](../../uzf-core.md) (`UZF-{n}`) with TCA specifics — a `SW-{n}`
rule may tighten but never contradict its `UZF-{n}` parent.

Reference implementation: a live, private iOS/macOS product recorded in the consumer registry. Rule numbers are append-only.

---

## A. Layering & artifacts (implements UZF-4, UZF-5, UZF-6, UZF-7)

**SW-1 — Screen/View split.** Each UI feature is a TCA-aware wrapper
(`<Name>Screen.swift` or `<Name>Fragment.swift`) plus a TCA-free renderer
(`<Name>View.swift`). New `<Name>Page.swift` files are forbidden (the `Page`
suffix is retired).

**SW-2 — Views are TCA-free (implements UZF-4).** `<Name>View.swift` must not
`import ComposableArchitecture` and must not reference `Store`/`StoreOf`/`Action`.
It takes plain values + `@escaping` closures (defaulting to no-ops) and compiles
in the `PreviewHost` target in isolation. CI lint:
`grep -rl 'ComposableArchitecture' **/*View.swift` must be empty.

**SW-3 — Layout lives in the View.** A Screen/Fragment only declares
`@Bindable var store`, constructs `<Name>View(...)` from selectors + closures, and
mounts navigation (`.task`, `.sheet`, `.alert`, `.navigation*`). No `VStack`/
padding/colors in a Screen.

**SW-4 — `@MainActor` only at the view boundary.** Screens, Fragments, and Views
may be `@MainActor`; a `@Reducer` `Feature` and its `State` must not be.

**SW-5 — Design components are domain-less (implements UZF-5).** Reusable UI under
`Design/` is plain SwiftUI — no TCA, no `@Dependency`, no domain types — and joins
the `PreviewHost` target.

## B. State (implements UZF-8, UZF-9)

**SW-6 — `@ObservableState`, no view models.** `State` is `@ObservableState`. Feature
state is never held via `@Observable`/`@StateObject`/`WithViewStore`/`viewStore`/
`EnvironmentObject`.

**SW-7 — `@Presents` for presented state.** Any child state driving `.sheet`,
`.popover`, `.navigationDestination`, `.fullScreenCover`, or `.alert` is
`@Presents` with a `@Reducer enum Destination`/`Path` and `.ifLet`/`.forEach`.
Plain optional child state is forbidden (breaks effect cancellation).

## C. Shifters, Selectors (implements UZF-10, UZF-11)

**SW-8 — Direct `inout` mutation is the default; extract on cause.** Mutating
`inout state` in a reducer arm is idiomatic. Extract `mutating func apply…` only on
an invariant, reuse, or independent-testability trigger. The value-returning
`with…` form exists under `#if DEBUG` for test/preview assembly only — never in a
reducer body.

**SW-9 — Selectors are `…Selector` on `extension State`.** Every value the View
reads is a `…Selector` computed property on `extension Feature.State`, reading only
`State`.

## D. Actions, Effects, Producers (implements UZF-2, UZF-3, UZF-12, UZF-13, UZF-14, UZF-15)

**SW-10 — No inline effects.** A reducer body never contains `.run`, `.send`,
`.cancel`, `.merge`, or `.concatenate` over raw closures. Effects come from a
`static func produce…Effect(...) -> Effect<Action>` in `<Name>Producer.swift`.
`.merge` is allowed only over already-produced Producer outputs.

**SW-11 — Producers normalize to `Result<Success, …Exception>`.** A Producer maps
via a Mapper and does one `await send(.on…Completed(result))`.
`catch is CancellationError { return }` is the only silent exit. `…Exception` is
`LocalizedError, Equatable`.

**SW-12 — Cancellation at the call site.** Long-lived/cancellable effects use
`.cancellable(id:)` (with `cancelInFlight:` where apt) at the reducer call site,
with a private `CancellationID` enum on the Feature.

**SW-13 — Bindings via `BindableAction`.** Field bindings use `BindableAction` +
`BindingReducer()` + `$store.field`. Hand-written "set field" actions alongside
`binding` are forbidden.

**SW-14 — Scoped presentation.** `.sheet/.popover/.navigationDestination/
.fullScreenCover(item:)` bind through `$store.scope(state:action:)`; alerts use
`AlertState` + `@Presents` + `.alert($store.scope(...))`. Hand-rolled
`Binding(get:set:)` for `isPresented` is forbidden.

## E. Services & dependencies (implements UZF-16, UZF-17)

**SW-15 — `@DependencyClient` clients.** A service is
`@DependencyClient struct …Client: Sendable`. `liveValue` and a deterministic
`previewValue` are mandatory; `testValue` is macro-generated and never
hand-written. No `fatalError` in a `liveValue` closure — omit unimplemented
operations. First-party system deps (`@Dependency(\.date.now)`, `\.uuid`,
`\.continuousClock`) replace raw `Date()`/`UUID()`/`Task.sleep`; debounce with
`.debounce(id:for:clock:)`.

**SW-16 — Wire types + Mapper.** Client operations return `…Response`; a
`Mapper` (`enum …Mapper { static func toDomain(...) }`) converts inside the
Producer. `Profile` never gains `Codable`; `…Response` never gains `Identifiable`.

## F. Testing (implements UZF-18, UZF-19, UZF-20, UZF-26)

**SW-17 — TestStore + direct View snapshots.** Reducer arms are tested with
`TestStore` (+ `withDependencies`); the auto-generated `unimplemented` `testValue`
fails on unexpected use. `<Name>View` snapshots are built directly from mock data
(no Store), mirror the `#Preview` blocks 1:1, and record against the pinned
reference environment (**iPhone simulator, iOS 26.5**, never Mac Catalyst). Glass
surfaces opt into `liquidGlassFallback()` for snapshots.

**SW-18 — Snapshot PNGs are the PR screenshots (implements UZF-26).** The recorded
`__Snapshots__` PNGs from SW-17 double as the UI screenshots embedded in the PR
description — one per user-visible state, mirroring the preview/snapshot set 1:1.
Never stage separate captures. Per UZF-26's hosting rule, the (mock-only) PNGs are
mirrored to the repo's **associated public assets repo** and referenced via
SHA-pinned `raw.githubusercontent.com` URLs (a private repo's own raw URLs `404`
in GitHub's proxy). The consuming repo automates this and pins the concrete repo in
its rules — the `{{ASSETS_REPO}}` / `{{ASSETS_LAYOUT}}` bindings (illustrative:
`acme/acme-assets`, `Acme/pr-<n>/<scene>.png`).

## G. Anti-patterns (auto-reject)

`WithViewStore`/`viewStore` · `@StateObject`/`@Observable` for feature state ·
`import ComposableArchitecture` in a `*View.swift` · `StoreOf<…>` param on a View ·
new `*Page.swift` · a Screen without a sibling View · layout in a Screen · a Screen
in the `PreviewHost` target · wire types in `State` · optional child state without
`@Presents` · `@MainActor` on a `Feature` · throwing out of an `Effect` ·
`await Task.sleep` for debouncing · `fatalError` in a `liveValue`.

## Glossary (UZF → Swift/TCA)

| UZF | Swift/TCA |
| --- | --- |
| Interactor / store | `@Reducer struct …Feature` / `StoreOf<…Feature>` |
| State | `@ObservableState struct State` |
| Event | `enum Action` case |
| Reducer | `var body: some ReducerOf<Self>` |
| Shifter | `mutating func apply…` (+ `#if DEBUG func with… -> Self`) |
| Selector | `var …Selector: T` on `extension State` |
| Producer | `static func produce…Effect(...) -> Effect<Action>` |
| Effect | `Effect<Action>` (`.run`) from a Producer |
| Wrapper / renderer | `…Screen`/`…Fragment` (TCA-aware) / `…View` (TCA-free) |
| Service | `@DependencyClient struct …Client: Sendable` |
| Result / Exception | `Result<Success, …Exception>` / `enum …Exception: LocalizedError` |
