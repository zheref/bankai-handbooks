<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 06 — Producers & Effects

## Repo-specific placeholders

- `{{APP_SOURCE_ROOT}}` — app source dir that holds `Pages/` and `Fragments/` (illustrative: `Acme/Application`).

Implements `UZF-12` (reducers pure, no inline effects), `UZF-13` (no service
calls from a reducer), `UZF-14` (effects resolve a Result, never throw), and
`UZF-15` (Producers are state-free factories); tightened for TCA by `SW-10`,
`SW-11`, `SW-12`.

## What a Producer is (`SW-10`, `UZF-15`)

A Producer is a **static function** on the Feature that builds a single-shot `Effect<Action>`. It lives in `…Producer.swift`. Reducers never inline effects; they always call a Producer (`SW-10`, `UZF-12`).

```swift
// {{APP_SOURCE_ROOT}}/Pages/UserProfile/UserProfileProducer.swift
extension UserProfileFeature {

    static func produceFetchProfileEffect(
        profileId: UUID,
        client: ProfileClient
    ) -> Effect<Action> {
        .run { send in
            let result: Result<Profile, ProfileException>
            do {
                let response = try await client.fetchProfile(id: profileId)
                if let profile = response.asDomain {
                    result = .success(profile)
                } else {
                    result = .failure(.unknown(message: "Malformed profile payload"))
                }
            } catch is CancellationError {
                return                                  // cancellation is silent
            } catch let urlError as URLError {
                result = .failure(Self.mapURLError(urlError))
            } catch {
                result = .failure(.unknown(message: error.localizedDescription))
            }
            await send(.onProfileFetchCompleted(result))
        }
    }

    private static func mapURLError(_ error: URLError) -> ProfileException {
        switch error.code {
        case .notConnectedToInternet, .timedOut: return .offline
        case .userAuthenticationRequired: return .unauthorized
        default: return .unknown(message: error.localizedDescription)
        }
    }
}
```

## Producer rules

1. **Static** on `extension <Feature>`. The reducer is the call site (`SW-10`).
2. **Inputs:** the data the effect needs (ids, parameters, dependencies). **Never** the whole `State` (`UZF-15`).
3. **Returns `Effect<Action>` only.** Not `Task`, not `AsyncStream` directly.
4. **Errors are normalized** into `Result<Success, …Exception>` before `await send(.…Completed(result))`. `CancellationError` is the only allowed silent return (`SW-11`, `UZF-14`). `…Exception` is `LocalizedError, Equatable` (`SW-11`).
5. **One Producer per logical effect.** Don't bundle "fetch + persist" into one producer unless they're inseparable. Compose at the reducer with `.merge` if you must.
6. **Test the Producer indirectly** through `TestStore` with stubbed dependencies. The Producer's logic shows up as `store.receive(.…Completed)` expectations (`UZF-18`).

## What may appear inside a Producer

- `try await client.…(…)` calls.
- Pure mapping (`response.asDomain`).
- `await send(.…Completed(result))`.
- A `for await` loop **only** if the effect is a long-lived stream (rare; see below).
- `try Task.checkCancellation()` if you want explicit cancellation points.

## What must **not** appear inside a Producer

- `state.…` — Producers don't see state. The caller (reducer) reads state and passes what's needed (`UZF-15`).
- `await MainActor.run { … }` — SwiftUI dispatches state changes for you.
- `print` / `os_log` outside of an injected logger dependency.
- Direct `URLSession`, `UserDefaults`, `Calendar.current`, `FileManager.default`. Those belong inside a Client's `liveValue` (`UZF-13`).
- More than one `await send(.…)` per success path. (Multiple sends are a smell; consider splitting into two Producers and `.merge` them.)

## Long-lived effects (streams) (`SW-12`)

When the effect is a subscription (Combine publisher, AsyncStream, NotificationCenter):

```swift
static func produceProfileUpdatesEffect(stream: AsyncStream<Profile>) -> Effect<Action> {
    .run { send in
        for await profile in stream {
            await send(.onProfileUpdatePushed(profile))
        }
    }
}
```

Cancel via `.cancellable(id: …)` at the **reducer** call site (`SW-12`):

```swift
case .onViewLoaded:
    return Self.produceProfileUpdatesEffect(stream: client.updates(id: state.profileId))
        .cancellable(id: CancellationID.profileUpdates, cancelInFlight: true)
```

Cancellation IDs are declared as a private enum inside the Feature (`SW-12`):

```swift
private enum CancellationID { case profileUpdates }
```

## Persistence side effects (`UZF-13`)

Don't write to `UserDefaults` from a reducer. Two acceptable patterns:

### A. `@Shared` (preferred for simple settings)

```swift
@ObservableState
public struct State {
    @Shared(.appStorage("showCompletedTasks")) public var showCompletedTasks: Bool = false
}
```

The View binds directly; no Producer needed.

### B. A `…Store` Client (for non-trivial persistence)

```swift
@DependencyClient
public struct PreferencesStore: Sendable {
    public var read: @Sendable () async -> Preferences
    public var write: @Sendable (_ prefs: Preferences) async -> Void
}
```

Producer:

```swift
static func producePersistPreferencesEffect(
    prefs: Preferences,
    store: PreferencesStore
) -> Effect<Action> {
    .run { _ in await store.write(prefs) }   // fire-and-forget, no completion event
}
```

If you do need to confirm the write completed: send a `onPreferencesPersisted` event.

## Composing effects (`SW-10`)

In a reducer:

```swift
case .userDidTapSave:
    return .merge(
        Self.producePostUpdateEffect(profile: state.profile!, client: profileClient),
        Self.produceLogAnalyticsEffect(event: .profileSaved, analytics: analytics)
    )
```

Allowed at the reducer because both arguments are already Producer outputs.

**Never** `.merge(.run { … }, …)` — the `.run` part is the unprincipled one (`SW-10`).

## "Fire-and-forget" anti-pattern (`UZF-14`)

`.run { _ in await client.foo() }` with no `await send(...)` is allowed only when:

- The operation has no observable failure mode (audit logging, analytics).
- Failure does not need a UI surface.

Otherwise, dispatch an event so the user can see the result.
