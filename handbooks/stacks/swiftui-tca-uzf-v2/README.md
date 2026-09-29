# Stack scenario: `swiftui-tca-uzf-v2`

| Facet | Value |
| --- | --- |
| Platforms | iOS 17+ (18 preferred), macOS (Catalyst-free native); previews via a PreviewHost target |
| Language | Swift 6 (strict concurrency), Xcode 16.3+ |
| UI architecture | SwiftUI + The Composable Architecture 1.13+ under **UZF v2 (Screen/View split)** |
| Backend (optional) | Supabase (Postgres + RLS). Where a repo on this stack is the **owning repo** of its product family's shared schema, its `supabase/migrations/` is the `UZF-25` canon; once a dedicated backend repo takes ownership it becomes a client too. Other-platform apps (e.g. compose-uzf-v2) are **clients** of the schema, never co-owners. |
| Testing | Swift Testing + XCTest (legacy); `swift-snapshot-testing` (reference env: iPhone, iOS 26.5) |
| Reference implementation | a live, private iOS/macOS product, recorded in the consumer registry |
| Scaffold generation scenario | **3** (`cross-apple`, Swift/SwiftUI) |

## Handbooks a review on this stack loads

- General: [`uzf-core.md`](../../uzf-core.md) (`UZF-{n}`),
  [`security-baseline.md`](../../security-baseline.md) (`SEC-{n}`),
  [`release-policy.md`](../../release-policy.md) (`REL-{n}`)
- Stack: [`architecture.md`](architecture.md) (`SW-{n}`)
