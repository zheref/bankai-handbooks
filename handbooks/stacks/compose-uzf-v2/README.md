# Stack scenario: `compose-uzf-v2`

| Facet | Value |
| --- | --- |
| Platform | Android (Compose-only, no XML Views) |
| Language | Kotlin 2.1+, JDK 17 toolchain, AGP 8.6+ |
| UI architecture | Jetpack Compose (Material3) + Hilt + Coroutines/Flow under **UZF v2** (`Feature`/`Outcome`/`Sink`, Page/Screen split) |
| Backend | Supabase over Ktor + Room (offline-first). **Client** of the product family's shared Postgres schema, which has a **single owning repo** (another client, or a dedicated backend repo). A compose-uzf-v2 app holds **no** `supabase/migrations/` canon of its own; `UZF-25` binds the *owning* repo, not its clients. |
| Testing | JUnit5 + `kotlinx-coroutines-test` + Turbine + Paparazzi + MockK (no Robolectric) |
| Reference implementation | a live, private Android product recorded in the consumer registry (its rules + the `SYNTHESIS_JETPACK_COMPOSE_v2` conception doc) |
| Scaffold generation scenario | Kotlin/Compose lane — **2B** (`mobile-desktop-kotlin`) / **6** family |

## Handbooks a review on this stack loads

- General: [`uzf-core.md`](../../uzf-core.md) (`UZF-{n}`),
  [`security-baseline.md`](../../security-baseline.md) (`SEC-{n}`),
  [`release-policy.md`](../../release-policy.md) (`REL-{n}`)
- Stack: [`architecture.md`](architecture.md) (`KT-{n}`)

## Onboarding note

To consume this handbook, record `compose-uzf-v2` as the repo's scenario in the consumer
registry and render its per-surface mirror from a pinned `bankai-handbooks` tag
(`CON-13`). A `bankai/` module inside an Android product may be an unrelated UDF
**library** that happens to share the name — it is not the review wiring.
