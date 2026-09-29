<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 05 — State, Shifters, Selectors

## Repo-specific placeholders

- `{{APP_SOURCE_ROOT}}` — app source dir that holds `Pages/` and `Fragments/` (illustrative: `Acme/Application`).

Implements `UZF-8`/`UZF-9` (State), `UZF-10` (Shifters), `UZF-11` (Selectors);
tightened for TCA by `SW-6`, `SW-8`, `SW-9`.

## State (`SW-6` implements `UZF-8`)

```swift
@ObservableState
public struct State {
    public var profileId: UUID
    public var profile: Profile?
    public var isLoading = false
    public var exception: ProfileException?
    @Presents public var destination: Destination.State?

    public init(profileId: UUID) { self.profileId = profileId }
}
```

- Fields are `var` (TCA's `Reduce { state, action in … }` mutates `inout state`).
- Default values inline when sensible.
- `Equatable` conformance is automatic via `@ObservableState` when all fields are `Equatable`.
- Avoid storing **derived** values. Derive in a Selector (`UZF-11`).
- If you must store a derived value for performance, prefix with `cached…` and add `// Redundancy: <reason>` (`UZF-11`).
- Two or more fields that represent a single lifecycle (loading / loaded / failed) are modeled as one enum, not parallel optionals (`UZF-9`).
- State holds domain types only — never wire-format `…Response`, raw payloads, platform error types, or in-flight task handles (`UZF-8`).

## Direct mutation is the default (`SW-8` implements `UZF-10`)

TCA's reducer signature is `Reduce { state, action in … }` — `state` is `inout`. Direct mutation is the API contract, not a smell.

`@ObservableState` (TCA 1.7+) tracks observation per *key-path*. Writing `state.isLoading = true` only re-renders views that actually read `store.isLoading`. There is no whole-view refresh. This is the same model as `@Observable` in vanilla SwiftUI 5.

```swift
case .userDidTapDismissBanner:
    state.bannerVisible = false                  // ✅ idiomatic; no Shifter needed
    return .none
```

Don't extract a `mutating func applyBannerDismissed()` just to wrap one line.

## When to extract a Shifter (`SW-8`, `UZF-10`)

Extract a `mutating func apply…` in `…Shifters.swift` only when **at least one** is true:

1. **Invariant.** The mutation touches ≥ 2 fields that must change together (e.g. "starting a load clears any prior exception").
2. **Reuse.** The same mutation appears in ≥ 2 reducer arms.
3. **Independent testability.** The mutation has logic (branches, math, ordering) worth verifying without going through `TestStore`.

If none of those apply, mutate inline.

## Shifter shape — `mutating func apply…`

```swift
// {{APP_SOURCE_ROOT}}/Pages/UserProfile/UserProfileShifters.swift
extension UserProfileFeature.State {

    /// Invariant: starting a load clears any prior exception. Used by .onViewLoaded and .userDidPullToRefresh.
    mutating func applyLoadingStarted() {
        isLoading = true
        exception = nil
    }

    /// 3-field invariant: a loaded profile clears loading and any exception.
    mutating func applyProfileLoaded(_ profile: Profile) {
        self.profile = profile
        isLoading = false
        exception = nil
    }

    /// Failure stops loading; profile is intentionally preserved (last-good-value UX).
    mutating func applyException(_ exception: ProfileException) {
        self.exception = exception
        isLoading = false
    }
}
```

### Rules for `apply…` Shifters

1. **`mutating func`, returns `Void`.** Matches TCA's `inout state` grain — zero allocations.
2. **Pure** — no `@Dependency`, no `Date()`, no `print`. If you need the current date, pass it in (`UZF-10` — time and identity are passed in):
   ```swift
   mutating func applyTaskDeferred(to target: DeferralTarget, made date: Date) { … }
   ```
3. **Naming convention** (from `GENERAL_UZF_ARCHITECTURE.md` §4.2):
   - `apply…` for **mutating** Shifters used inside reducers (the common case).
   - `with…` is reserved for the optional *value-returning* variant (see below).
4. **Test every Shifter** with ≥ 3 cases (typical, boundary, no-op) (`UZF-18`).

## Optional: fluent `with…` helpers (test/preview only) (`SW-8`)

For building test or preview state fluently, you may add value-returning helpers — they internally call the `apply…` Shifter so logic stays in one place:

```swift
#if DEBUG
extension UserProfileFeature.State {
    func withProfile(_ profile: Profile) -> Self {
        var s = self; s.applyProfileLoaded(profile); return s
    }
    func withException(_ exception: ProfileException) -> Self {
        var s = self; s.applyException(exception); return s
    }
}
#endif

// In a test:
let state = UserProfileFeature.State(profileId: id)
    .withProfile(.mockTypical)
    .withException(.offline)
```

**Hard rule:** `with…` helpers are **never called from inside a reducer body** — reducers always `apply…` on `inout state`. The `with…` form is sugar for test/preview composition only, and lives under `#if DEBUG` (`SW-8`).

## Common Shifter anti-patterns

- ❌ Wrapping a single-field assignment in a Shifter. (`mutating func applyLoadingStarted() { isLoading = true }` — just write `state.isLoading = true` inline.)
- ❌ Calling another Shifter inside a Shifter that already does the same job. Compose at the call site.
- ❌ Branching on dependency state. Branch in the reducer, then call the precise Shifter.
- ❌ Returning a `Result` from a Shifter. Validation belongs in the reducer or a Selector.
- ❌ Using `with…` returning `Self` *inside a reducer body* — that's the v1 form, retired.

## Selectors — computed `…Selector` on `State` (`SW-9` implements `UZF-11`)

```swift
// {{APP_SOURCE_ROOT}}/Pages/UserProfile/UserProfileSelectors.swift
extension UserProfileFeature.State {
    var shouldShowEmptyStateSelector: Bool {
        !isLoading && profile == nil && exception == nil
    }

    var avatarAccessibilityLabelSelector: String {
        guard let name = profile?.displayName, !name.isEmpty else { return "User avatar" }
        return "Avatar of \(name)"
    }

    var canEditSelector: Bool { profile != nil && exception == nil }
}
```

### Rules for Selectors

1. **Pure**, no side effects, no allocations beyond cheap ones.
2. **Cheap** — if it iterates a large collection, mark it and memoize at the call site.
3. **Suffix `…Selector`** on every property the View reads. This is a greppability rule, not a Swift requirement (`SW-9`).
4. **Test** every Selector with ≥ 3 cases (`UZF-18`).
5. **Never** call `@Dependency` from a Selector. State is the only input (`UZF-11`).

## When derived data needs caching (`UZF-11`)

When a Selector becomes provably expensive (profiling shows it taking > 1 ms on a hot path):

```swift
@ObservableState
public struct State {
    // … inputs …
    // Redundancy: `groupedTasks` is O(n log n) over `allTasks`; recomputing it on every View
    // update caused 60 → 40 fps in the Day timeline. Refreshed in `applyTasksLoaded`.
    fileprivate(set) var cachedGroupedTasks: [DayGroup] = []
}

extension State {
    mutating func applyTasksLoaded(_ tasks: [Task]) {
        allTasks = tasks
        cachedGroupedTasks = TasksGrouper.group(tasks)
    }

    var groupedTasksSelector: [DayGroup] { cachedGroupedTasks }
}
```

The Shifter is the only place allowed to mutate the cache. The Selector reads it.

## Where computed properties of *the domain model* live

Domain models (`Profile`, `Endeavor`, …) can have their own computed properties — they aren't Selectors and they don't need a suffix. Selectors are specifically `extension Feature.State`. Domain helpers go in `<Model>+Computed.swift`.
