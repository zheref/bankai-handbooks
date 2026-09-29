# Release Policy Handbook

Numbered, citable versioning and release rules. Natsu supervises releases against
these and cites `REL-{n}`; the release itself is **G3-gated** (human go/no-go).

**Scope:** any product repo that ships to an app store or deploys a backend. Rule
numbers are **append-only and stable**.

---

## A. Versioning

**REL-1 — Semantic Versioning only.** Product versions are `MAJOR.MINOR.PATCH`.
MAJOR = breaking user-facing/API change; MINOR = backward-compatible feature;
PATCH = backward-compatible fix. The version bump is justified by the Conventional
Commits range since the last release.

**REL-2 — Release notes are derived, not hand-waved.** Notes are drafted from the
Conventional Commits history of the milestone (`feat`→features, `fix`→fixes),
grouped for users. No release without notes.

## B. Gates & flow

**REL-3 — No submission without G3.** Nothing is tagged, submitted to a store, or
deployed until the human gives G3 go/no-go. Natsu prepares the release PR and
waits; it never self-approves a release.

**REL-4 — Pre-flight completeness.** Before a release PR: the milestone has no open
blockers, CI is green, and the **pre-release quality verification** has been run against the
release candidate with its report attached ([`quality-baseline.md`](quality-baseline.md)
`QA-20`). That verification is performed **locally, on demand, on the human's own
credentials** by **Ichigo's Hollow nature** — adversarial QA plus the `QA-11` performance
budgets, over the product **and** the process machinery. Its `Quality-Gate:` line is
**advisory** (`QA-21`): a `fail` is a recommendation with a stated action (`QA-22`), never an
automatic block — the human owns the go/no-go at G3 (`REL-3`, `CON-6`). An incomplete
milestone is escalated, not shipped.

> **The CI counterpart is future work.** A wired, post-merge offensive-QA gate (**Rukia**, a
> GitHub App running these same `QA-{n}` rules in CI) is not provisioned; until it is,
> `QA-20` is satisfied by the local run above. Same phasing as
> [`ux-baseline.md`](ux-baseline.md), where the `UX-{n}` baseline landed as process first and
> the CI gate (Bisky) followed.

**REL-5 — Release from a dedicated ref.** Releases proceed on `release/*` branches
via ruleset; the release commit/tag is created by the release pipeline, not by
ad-hoc pushes to `main`.

## C. Pipeline discipline

**REL-6 — The pipeline is deterministic; the agent supervises.** Release steps
(tag, GitHub Release, Fastlane submission / deploy) are scripted and reproducible.
Natsu verifies, retries, diagnoses, and reports — it never improvises a pipeline
step or runs a store submission by hand.

**REL-7 — Store credentials live only in the pipeline environment.** App Store
Connect keys, Play service-account JSON, signing certs, and deploy tokens exist
only as pipeline/environment secrets — never in agent context, never in the repo
(reinforces `security-baseline.md` `SEC-1`). macOS build/notarize steps run on the
designated CI (Xcode Cloud).

## D. Post-release

**REL-8 — Watch to live, then soak.** Natsu watches store review to completion;
metadata-level rejections it addresses, code-level rejections become a diagnosis
issue for the build agents. After go-live it confirms the version is live, checks
rollout %, and holds until monitors are green for the soak window. A failed
rollout halts and pages the human.

---

## Rejection & rollback

- **Metadata rejection** (screenshots, description, privacy answers) → Natsu fixes
  and resubmits.
- **Code/behavioral rejection** → a diagnosis issue routed to the build tier; the
  release pauses at G3 until resolved.
- **Failed staged rollout / bad monitor** → halt the rollout, page the human;
  roll back per the platform's mechanism. Never push a fix straight to production
  outside the pipeline.
