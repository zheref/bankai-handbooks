<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 08 — Anti-Patterns (auto-reject in review)

The coded taxonomy below is the authoritative reject list. Codes are **stable and
append-only** — never renumber. Each maps to a cross-platform `UZF-{n}` and/or the
SwiftUI/TCA binding `SW-{n}`; the stack code tightens but never contradicts its
parent. See [`../architecture.md`](../architecture.md) §G for the condensed list.

## Repo-specific placeholders

| Token | Illustrative value | What it is |
| --- | --- | --- |
| `{{ARCH_DECISIONS_DIR}}` | `.claude/Architecture/` | Per-project architecture-decision folder (versioned `vN-*.md` docs + `## Revisions`). |

---

## Architectural (implements UZF-4, UZF-6, UZF-12, UZF-13, SW-1, SW-2, SW-10)

| # | Anti-pattern | Reject because | Correct |
| --- | --- | --- | --- |
| A1 | Inline `.run { … }` in a reducer body | Effects are not testable in isolation; reducer is no longer pure. (UZF-12, SW-10) | Move to `…Producer.swift` as a static `produce…Effect`. |
| A2 | A reducer that calls `URLSession`, `UserDefaults`, `Calendar.current`, `Date()` directly | Reducer becomes non-deterministic; tests need real services. (UZF-13) | Wrap in a `…Client` + `@Dependency`. |
| A3 | The **same** multi-field invariant inlined in ≥ 2 reducer arms (e.g. "start loading + clear exception + reset retry count" copy-pasted three times) | Invariant logic is duplicated at every call site; a future field added to the invariant gets forgotten in one of them. (UZF-10, SW-8) | Extract into `mutating func applyFoo(...)` Shifter and call once per arm. (Direct mutation of unrelated fields is still fine — only extract when an invariant repeats.) |
| A4 | A computed property on `State` that reads `@Dependency` | Selectors are not allowed to see the world. (UZF-11, SW-9) | Pass the value into a Shifter at mutation time; store the result. |
| A5 | Multiple `@Reducer`s declared in one file | Hurts grep, hurts incremental compile. | One Feature per file (children of the same family can co-exist *only* in a `Destination` enum). |
| A6 | A "god" Feature > 600 lines | Almost always means missing Producers, missing child Features, or both. | Split into Producers / child Features. |
| A7 | A Fragment that owns a Producer | Fragments are passive; the parent owns effects. (UZF-7) | Move Producer to the parent; have the Fragment send intent. |
| **A8** | **A new `<Name>Page.swift` file added under the Screen/View split** | `Page` suffix retired by the Screen/View split (SW-1). | Use `<Name>Screen.swift` + `<Name>View.swift`. |
| **A9** | **A `<Name>Screen.swift` without a sibling `<Name>View.swift`** | Defeats the PreviewHost split. (SW-1, UZF-4) | Extract the body into `<Name>View.swift` and consume it from the Screen. |
| **A10** | **A `<Name>View.swift` that imports `ComposableArchitecture`** | Breaks PreviewHost compatibility. (SW-2, UZF-4) | Move TCA-aware lines to the Screen; reshape the View's `init` to take plain values + closures. |
| **A11** | **A change to UZF rules or artifact shape without a corresponding `{{ARCH_DECISIONS_DIR}}` update** | Architecture decisions become un-auditable; future-me won't know the rationale. | Add a new `vN-*.md` or a `## Revisions` entry on the current version doc. |

## State (implements UZF-8, UZF-9, SW-4, SW-6, SW-7)

| # | Anti-pattern | Correct |
| --- | --- | --- |
| S1 | `var apiResponse: ProfileResponse?` in `State` | Map to domain `Profile` before storing. (UZF-8) |
| S2 | `var lastUpdated = Date()` field that the reducer updates inline | `@Dependency(\.date.now)` in Shifter args. |
| S3 | Multiple `Optional` fields that should be one `enum Status { .loading, .loaded(Profile), .failed(Exception) }` | Model as an enum. (UZF-9) |
| S4 | Plain `var destination: ChildFeature.State?` used with `.sheet(item: $store.scope)` | Add `@Presents` + `.ifLet(\.$destination, action: \.destination)` for proper effect cancellation. (SW-7) |
| S5 | `@MainActor` on `State` or `Feature` | Remove. Only the UI boundary (`<Name>Screen`/`<Name>Fragment`/`<Name>View`) may be `@MainActor` — never the `@Reducer` Feature or its State. (SW-4) |

## Actions (implements UZF-2, UZF-3, SW-13)

| # | Anti-pattern | Correct |
| --- | --- | --- |
| AC1 | Action named after the verb of the effect (`fetchProfile`, `loadData`) | Name after intent or signal (`userDidPullToRefresh`, `onViewLoaded`). (UZF-2) |
| AC2 | Two separate cases for success/failure (`onSuccess`, `onFailure`) | One case with `Result<T, …Exception>`. (UZF-3) |
| AC3 | `Action: Equatable` carried over from templates when no test needs it | Drop the conformance. |
| AC4 | `case binding(_:)` *and* manually-defined "set this field" actions | Use `BindableAction` + `BindingReducer()`; remove the manual cases. (SW-13) |

## Views (implements UZF-4, UZF-11, SW-2, SW-3, SW-9, SW-14)

| # | Anti-pattern | Correct |
| --- | --- | --- |
| V1 | `WithViewStore`, `ViewStore.init`, `viewStore.send` | `@Bindable var store` + `store.send(...)` (in the **Screen/Fragment**, not the View). |
| V2 | `@StateObject var vm = MyViewModel()` | Replace the VM with a `Feature` and a `StoreOf<>`. (SW-6) |
| V3 | `@Observable class MyVM { … }` containing business logic | Same as V2. |
| V4 | `EnvironmentObject` for app state | `@Dependency` (logic) or `@Environment` (UI-only concerns). |
| V5 | Hand-rolled `Binding(get:set:)` for `.alert(isPresented:)` | `AlertState` + `@Presents` + `.alert($store.scope(...))`. (SW-14) |
| V6 | Computed view-state inside the Screen (`let isEmpty = !store.isLoading && store.profile == nil`) | Move to a Selector. (SW-9) |
| **V7** | **`import ComposableArchitecture` in `<Name>View.swift`** | Move every TCA-aware line to the Screen/Fragment. The View reads plain values and fires closures. (SW-2) |
| **V8** | **`StoreOf<…Feature>` parameter on `<Name>View`** | View takes plain inputs + closures; the Screen reads the store and passes them down. (SW-2) |
| **V9** | **Layout (`VStack`, `padding`, colors) inside `<Name>Screen.swift`** | Move into `<Name>View.swift`. The Screen mounts navigation only. (SW-3) |
| **V10** | **A new `<Name>Page.swift` file** | `Page` suffix is retired. Use `<Name>Screen.swift` + `<Name>View.swift`. (SW-1) |
| **V11** | **`<Name>Screen.swift` added to the PreviewHost target** | Only `<Name>View.swift` joins PreviewHost. Adjust Target Membership in `project.pbxproj`. |
| **V12** | **`<Name>View.swift` references a `…Feature.Action` case directly** | The View knows only plain types and closures. The Screen translates closures into store sends. (SW-2) |

## Services (implements UZF-16, UZF-17, SW-15, SW-16)

| # | Anti-pattern | Correct |
| --- | --- | --- |
| D1 | Hand-rolled `…Client` struct with `static let testValue = ProfileClient(fetch: { _ in fatalError() })` | Use `@DependencyClient`; the macro generates `testValue` with `unimplemented` closures. (SW-15) |
| D2 | `fatalError("Implement in production")` in a `liveValue` | Omit the closure from `@DependencyClient` initializer. (SW-15) |
| D3 | A Client struct with > 8 unrelated operations | Split. (UZF-16 segregation) |
| D4 | A Client whose operations return domain types directly | Operations return `…Response`; Producer maps to domain. (UZF-17, SW-16) |
| D5 | `static let previewValue = liveValue` | Provide a deterministic stub. (SW-15) |
| D6 | Service held in a `@StateObject` or singleton | `@Dependency` + `DependencyKey`. |

## Tests (implements UZF-18, UZF-20, SW-17)

| # | Anti-pattern | Correct |
| --- | --- | --- |
| T1 | `TestStore` with `nonExhaustive` everywhere | Use `nonExhaustive` only when you're explicitly skipping non-essential mutations; default to exhaustive. |
| T2 | Test name that doesn't describe a scenario (`test_state`) | `test_<event>_<condition>_<expectation>`. (UZF-20) |
| T3 | Snapshot tests covering different scenarios than previews | Keep snapshots and previews in 1:1. (SW-17, UZF-26) |
| T4 | Live `URLSession` calls in tests | Override the Client with `withDependencies`. |
| T5 | Tests that assert against the internals of a Selector (e.g., literal string formatting) | Test the *behavior*. Strings are formatting; assert via accessibility intent. |

## Concurrency (implements UZF-12, UZF-14, SW-11)

| # | Anti-pattern | Correct |
| --- | --- | --- |
| C1 | `await Task.sleep(for: …)` for debouncing | `.debounce(id:for:clock:)` + `@Dependency(\.continuousClock)`. |
| C2 | `DispatchQueue.main.async` inside a reducer or producer | Don't. TCA dispatches state changes. |
| C3 | `Task { @MainActor in … }` inside a Producer to mutate state | Producers don't mutate state. `await send(.…)` is the only mutation path. (UZF-15) |
| C4 | `nonisolated(unsafe)` on a Dependency `previewValue`/`testValue` | Either make the Client `Sendable`-clean, or use `LockIsolated`/an actor. `nonisolated(unsafe)` is a Swift 6 escape hatch, not an architecture choice. |

## Migration smells (legacy in scope — implements UZF-24)

| # | Smell | Action |
| --- | --- | --- |
| M1 | Two screens for the same flow: a legacy `…ViewController` and a UZF `…Screen` behind a flag | Document the seam in PR; pick a sunset date. |
| M2 | A `…Repository` that exposes Combine `AnyPublisher` to the rest of the app | Wrap the repository's output in an `AsyncStream` and consume from a Producer. |
| M3 | A model used both as wire format and domain (`Codable` + SwiftUI `Identifiable` on the same struct) | Split into `…Response` + domain `…`. (UZF-17) |
