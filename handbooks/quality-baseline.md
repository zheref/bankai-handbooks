# Quality Baseline Handbook

Numbered, citable rules for **adversarial QA and performance** across every Bankai
scenario. These make delivery quality a **deterministic, evidence-backed** part of the
process — the quality counterpart to how `security-baseline.md` (`SEC-{n}`) governs
security, `ux-baseline.md` (`UX-{n}`) governs design quality, and `uzf-core.md`
(`UZF-{n}`) governs architecture.

The offensive-QA gate (**Rukia**, future — CI, a GitHub App) will cite these as `QA-{n}`.
**Today there is no CI quality gate**: **Ichigo's Hollow nature** self-runs these
**locally**, on the human's own credentials, **on demand**, before a release is cut — and
the human reads the verdict at **G3** (`CON-6`). Rukia is provisioned later. This is the
same phasing `ux-baseline.md` used: the baseline lands as process first, the CI gate
follows.

> **Adding or changing a rule?** Do not hand-edit this file in place — see
> **[Growing this handbook — how to add a `QA-n` rule](#growing-this-handbook--how-to-add-a-qa-n-rule)**
> at the bottom. A `QA-{n}` rule is authored/changed only through a G4 PR the human merges.

**Scope:** every Stack Matrix scenario — **including `bankai-machinery`, the machinery itself**. The machinery
is a product under test: a guard that fails open, or a wake condition that never fires,
breaks delivery exactly the way a product defect does.

**This layer sits *above* the test pyramid, never beside it.** `UZF-18`/`UZF-19`/`UZF-20`/
`UZF-26` and each stack's `rules/0x-testing.md` already own unit, selector/producer, and
snapshot/preview coverage. `QA-{n}` adds only the **E2E / adversarial / performance**
layer. A missing unit test or a coverage-floor breach is **Sasuke's `UZF-19` finding**, not
a `QA-{n}` one (`QA-9`).

**Cite these rules; never invent them.** Same discipline as `CON-11` / `SEC-15` / `UX`: a
quality concern with **no** matching `QA-{n}` rule is a `bankai:handbook-question`, **scope-routed**
(§ *Quality discipline*) — never an improvised threshold.

Rules are **grouped by topic** and numbered **sequentially within this version**. Numbers
are **append-only and stable**: a later version appends the next number in the relevant
topical section; a retired rule is marked `RETIRED` in place, never renumbered or
re-purposed.

---

## A. Method & evidence

**QA-1 — Every finding is proven, never asserted.** A filed quality finding MUST carry one
of exactly two evidence forms: **(a)** a committed automated test that **fails against the
candidate build**, or **(b)** a measured number with its full method block (`QA-15`).
Anything else is a note, not a finding. This is the quality lane's floor, the same way
`CON-11` and `SEC-15` floor the reviewer lanes — an unprovable quality report is
indistinguishable from an opinion and will not survive a release argument.

**QA-2 — Hypotheses come from the fixed class list, generated before any test is written.**
The eight classes: **(1)** boundary and edge values; **(2)** concurrency, races and
re-entrancy; **(3)** offline and degraded network — loss, latency, partial response,
mid-flight drop; **(4)** malformed and hostile input; **(5)** permission-denied and
interrupted flows — auth revoked, OS permission refused, call or system interrupt
mid-flow; **(6)** state restoration and process death — background kill, cold resume, deep
link into restored state; **(7)** accessibility failure modes — screen-reader traversal,
largest Dynamic Type / font scale, keyboard-or-switch-only operation; **(8)** abuse and
misuse paths — double-tap, replay, rate abuse, tamper. A fixed list makes adversarial
*coverage* auditable instead of mood-dependent. Class 7 deliberately exercises `UX-1`,
`UX-2` and `UX-3` at runtime rather than restating them.

**QA-3 — Every hypothesis gets a recorded verdict.** Each of the eight classes is
dispositioned `reproduced`, `not-reproduced`, or `not-testable-here`. No class is silently
dropped; a `not-testable-here` names the missing capability — no device, no runner, no
driver — and becomes a tooling issue. A non-reproduction is *evidence of quality* and
belongs in the record; an undeclared skip is how a class quietly stops being tested,
release after release.

**QA-4 — Three-of-three, or it is a flake finding.** A defect finding's test MUST fail
**3/3** consecutive runs against the candidate. A failure that reproduces intermittently is
filed as a **flake finding** carrying its observed rate (`k/n` runs) plus the suite and
test id — never as a functional defect. These are two different defects with two different
owners, and conflating them is what makes a flaky suite un-actionable.

**QA-5 — Test the candidate, never a patched tree.** Adversarial and performance work runs
against the exact commit proposed for release. The quality lane never edits product source
to make a test pass or a number improve. This preserves the never-fixes-what-it-breaks
separation and guarantees the report describes the artifact that would actually ship.

**QA-6 — Search before filing; one open finding per distinct defect.** Before opening a
finding, search the target repo's open issues by subject and comment on a match — yours or
another agent's, even within the same run (`CON-11`, the shared agent conventions (`_conventions.md`) *Idempotency*).
This lane generates issues in bursts and would otherwise flood the human's queue.

---

## B. Test tooling — per scenario

**QA-7 — One default automation tool per scenario, per layer; a deviation states its
reason.** See the *Tooling matrix* below. **Selenium and Appium are not defaults on any
Bankai scenario** — they apply only where a target has no first-party driver (a legacy
browser matrix, a physical-device farm, an embedded or OEM surface), and that condition is
named in the report. An options list produces a different toolchain every release and
non-comparable evidence; one default makes a red test reproducible by whoever picks it up.

**QA-8 — A red-test artifact has a fixed shape.** A defect finding links: **(a)** a branch
`ichigo/<slug>` in the target repo containing **only** test-target files; **(b)** the exact
reproducing command; **(c)** the failing assertion excerpt; **(d)** the environment block
(`QA-15`). The branch name carries no issue number — the finding may precede the issue.
The fixer starts from red, as the retired offensive-QA contract required.

**QA-9 — Extend the pyramid; never duplicate it.** The Hollow/QA layer adds **only** E2E,
adversarial and performance coverage on top of the stack's existing minimums. A missing
unit test, an untested reducer arm, or a coverage-floor breach is **Sasuke's `UZF-19`
finding**. This prevents a second, competing testing canon.

**QA-10 — Test data is synthetic and local.** No production store, no live user data, no
real payment rails, no third-party account the human owns. Hostile-input corpora are
committed under the test target. Network degradation is **simulated** — Network Link
Conditioner, emulator shaping, Playwright route interception — never induced against a live
service. This hardens the inherited "never test in production stores" anti-goal and
composes with `SEC-8`: an adversarial suite is exactly the thing that must not touch real
PII.

### Tooling matrix

| Scenario | E2E / UI automation (default) | Adversarial logic layer | Not used |
| --- | --- | --- | --- |
| `swiftui-tca-uzf-v2` | **XCUITest** (`XCUIApplication`, launch arguments for seeded state) via `xcodebuild test -scheme {{SCHEME}} -destination 'platform=iOS Simulator,name={{SNAPSHOT_DEVICE}},OS={{SNAPSHOT_OS}}'` | **swift-testing** (`@Test`) for hostile-input and boundary suites; `TestStore` for race and effect-ordering hypotheses | Appium, Selenium |
| `compose-uzf-v2` | **Compose UI Test** (`androidx.compose.ui.test.junit4`, `createAndroidComposeRule`) on a **Gradle Managed Device**; **Espresso Intents / UIAutomator** only for cross-app and system-dialog flows (class 5) | JUnit5 + **Turbine** for effect and race hypotheses | Appium, Selenium |
| `react-uzf-v1` (web / Next.js) | **Playwright** (`@playwright/test`; `page.route` for network degradation; `--repeat-each=3` for `QA-4`) | **Vitest** for hostile-input and boundary suites | Selenium (unless a legacy browser matrix is named), Cypress |
| `react-uzf-v1` (Expo / RN target) | **Maestro** flows against a dev-client build | Jest (`jest-expo`) + React Native Testing Library | Detox, Appium (unless a device farm is named) |
| `bankai-machinery` | **bats** (`tests/*.bats`) driving `scripts/*.sh`, plus `yq` assertions over `.github/workflows/*.yml` | **pytest** for the Python guards (`tests/test_*.py`) | — |

---

## C. Performance budgets

**QA-11 — The Performance Metric Set is fixed, and measured on every pre-release run.**
Seven metrics: **P1** cold launch to first interactive frame; **P2** warm launch /
foreground resume; **P3** frame hitch rate (jank %) over the primary scroll-and-navigate
flow; **P4** peak resident memory (high-water) over that flow; **P5** shipped artifact size
— download size of the app binary / AAB, or initial JS+CSS transfer; **P6** network on the
primary flow, **both** total payload bytes **and** request count; **P7** longest
main-thread block. A fixed set is what makes release N comparable to release N−1. P6's
request count is separate because payload-only budgets hide chatty designs.

**QA-12 — Measurement is tool-pinned per scenario** (see the *Measurement matrix*). A
number produced by a tool other than the pinned one is reported as a **diagnostic**, never
as a budget check. Cross-tool numbers are not comparable — an Instruments launch time and
an `XCTApplicationLaunchMetric` launch time measure different intervals — so pinning the
tool is what makes `QA-13`'s percentage mean anything.

**QA-13 — Budgets are regression-relative to the last released tag, floored by absolute
ceilings.** Default gate: a **>10% median regression** on any metric versus the recorded
baseline is a **`high`** finding; **>25%** is **`critical`**. Independently, these
absolutes hold regardless of baseline: **P1 ≤ 2000 ms** median on the reference device;
**P7 ≤ 250 ms** (Apple hang threshold) / **jank frames ≤ 5%** (Android) / **INP ≤ 200 ms**
(web); **P5 web initial transfer ≤ 300 KB** compressed. Absolute-only budgets are
unenforceable across a maturing product — they are either always green or always red;
relative-only lets a slow app stay permanently slow. Relative is primary because it catches
what releases actually do: drift.

**QA-14 — Baselines and results live in the repo, not in a transcript.** Baselines live at
`docs/Quality/perf-baseline.json`, keyed `<scenario>/<device-key>/<metric>`, and are updated
**only** in the release PR, **only** after the human accepts the new numbers at G3. Each
run's full report is committed at `docs/Quality/reports/<version>-hollow.md`. This is
`CON-33`'s reconcile-don't-remember principle applied to numbers: a budget whose baseline
lives in a chat is a memory, and the next session cannot compare against it.

**QA-15 — A number without its method block is void.** Every reported number names: device
or runner model and OS version; build configuration — **Release**, optimizations on, **no
debugger attached**, no instrumentation overhead; **n ≥ 5 runs with the first discarded**;
the statistic reported — **median and p90**, never a single sample and never a bare mean;
and thermal/network conditions. This is the whole difference between a performance budget
and a vibe, and it is what makes a regression claim defensible when a builder disputes it.

### Measurement matrix

| Scenario | P1/P2 launch | P3 hitches | P4 memory | P5 size | P6 network | P7 main thread | Diagnosis | Reference device |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `swiftui-tca-uzf-v2` | `XCTApplicationLaunchMetric` | `XCTOSSignpostMetric` over `os_signpost` intervals + Animation Hitches instrument | `XCTMemoryMetric` | Xcode archive **App Thinning size report** | `URLSession` metrics via a test-only `URLProtocol` recorder | Instruments **Hangs** / Time Profiler; `XCTClockMetric` | **Instruments** (Time Profiler, Allocations, Animation Hitches, Hangs) | `{{PERF_DEVICE}}` — defaults to the `{{SNAPSHOT_DEVICE}}`/`{{SNAPSHOT_OS}}` pair in `stacks/swiftui-tca-uzf-v2/rules/07-testing.md` |
| `compose-uzf-v2` | Macrobenchmark `StartupTimingMetric` (`COLD`/`WARM`), `BaselineProfile` applied | Macrobenchmark `FrameTimingMetric` | Macrobenchmark `MemoryUsageMetric` | AAB/APK analyzer download size | `TraceSectionMetric` around the HTTP span + OkHttp `EventListener` | `FrameTimingMetric` P99 + Perfetto main-thread slice | **Perfetto** trace | `{{PERF_DEVICE}}` — a Gradle Managed Device matching `{{SNAPSHOT_DEVICE}}` |
| `react-uzf-v1` (web) | Lighthouse **LCP/FCP** | Lighthouse **CLS** + long-animation-frame entries | CDP heap sample via Playwright | `next build` output + `@next/bundle-analyzer` | Playwright `page.on('request'\|'response')` totals | Lighthouse **TBT** + field **INP** | **Lighthouse CI** (`@lhci/cli`), pinned mobile preset | the pinned Lighthouse mobile emulation preset (Moto-G-class, 4× CPU throttle, Slow 4G) |
| `react-uzf-v1` (Expo) | reuse the Apple / Android row for the native build under test | — | — | EAS build artifact size | RN network inspector, as web | — | — | as above |
| `bankai-machinery` | wall-clock of `make test` from a clean checkout | — | — | — | — | per-guard-script wall clock | `gh run view --json jobs` durations | the human's local machine, model recorded |

> **The `bankai-machinery` budget is deliberately narrow but real:** a guard script that takes
> minutes taxes every PR in every consuming repo. Default ceilings: `make test` ≤ **120 s**;
> any single `scripts/*.sh` guard ≤ **5 s** on the recorded machine.

---

## D. Process-machinery adversarial testing (`bankai-machinery`)

**QA-16 — The machinery is a product under test.** A `bankai-machinery` pre-release run MUST:
have `make lint` and `make test` green **from a clean checkout**; and drive every changed
`scripts/*.sh` guard with the hostile-input corpus — empty file, missing file, malformed
JSON/YAML, non-UTF-8 bytes, oversized input, a path containing spaces, and an unexpected
extra field. Each MUST **fail closed** — non-zero, with a message — never pass silently.
`BC-9` requires that machinery logic *carries* a test; `QA-16` is the layer above, asking
whether that test *holds under abuse*.

**QA-17 — Workflow wake conditions are asserted, not eyeballed.** Every `if:` gating a
privileged, secret-bearing, or wake-bearing job MUST have a bats assertion that reads the
**live YAML** with `yq` and greps **each conjunct independently** — event name, action,
label name, author login, sender/actor gate. A new or changed wake condition shipping
without one is a **`high`** finding. An `if:` cannot be exercised at runtime without firing
the real event, so the YAML assertion is the only pre-release evidence that exists; it is
also the direct enforcement surface for `BC-5`.

**QA-18 — Fail-closed is proven by a negative test.** Every guard MUST have at least one
test asserting that it **rejects** — non-zero exit, red check, refusal message. A suite
that only proves the happy path is treated as **untested** for `QA-16`'s purposes. For a
guard, the failure mode that matters is the **false green**, and a happy-path-only suite is
precisely blind to it.

**QA-19 — Machinery findings carry no fix.** The quality lane files the red bats case plus
the finding, routed to **Kisuke** (machinery) or **Naruto/Yamamoto** (spec), and stops
(`CON-3`). Same separation as `QA-5`, applied to the framework itself.

---

## E. The pre-release gate

**QA-20 — The gate runs before the cut, on the candidate, on demand.** It is triggered
**locally by the human** and runs before **(a)** a `CON-33(b)`/`CON-41` framework tag cut,
and **(b)** any product store submission, deploy, or publish (`REL-3`, `CON-6`). It runs
against the **exact commit proposed for the tag** — which under `CON-41` must already be
reachable from `origin/main`. It is **not** wired to CI, to `push`, to `pull_request`, or to
a schedule. Pre-release is the last moment a defect is cheaper than a rollback, and the
first moment the artifact is real.

**QA-21 — The verdict is one line, and it is advisory.** The report ends with exactly one
of: `Quality-Gate: pass ✅`, `Quality-Gate: fail ❌`, `Quality-Gate: inconclusive ⚠️`.
**PASS** = every `QA-2` class attempted and dispositioned, **zero open `critical`/`high`
findings from this run**, every metric within `QA-13`, machinery suites green. **FAIL** =
any `critical`/`high` finding, or any budget breach. **INCONCLUSIVE** = one or more classes
`not-testable-here` (`QA-3`), each enumerated.

> **The marker is `Quality-Gate:`, never `Verdict:`.** `Verdict:` is a machine-parsed
> marker reserved for the review gates (Sasuke, Tenma, Bisky) in the shared agent conventions (`_conventions.md`),
> and a malformed one fails a check closed. A quality report pasted onto a PR must not be
> able to collide with it. `Quality-Gate:` is collision-free today and already parseable for
> Rukia tomorrow.

**A `fail` never blocks, never halts a pipeline, never withholds a tag, and never applies a
stage label** — the human owns G3 (`CON-6`). An un-reviewed local agent must never acquire
release-blocking power it was not granted.

**QA-22 — A `fail` is a recommendation plus a decision record.** The report states one
recommended action — **hold**, **ship-with-known-issue**, or **fix-first** — and the human's
decision is recorded in the release PR body. A finding shipped as a known issue is labeled
and carried into the next milestone; it is **never closed** by the release. This keeps human
ownership of G3 intact while making the trade-off auditable — closing a known issue at
release is how a deferred defect becomes an invisible one.

---

## F. Severity, routing & escalation

**QA-23 — Severity maps onto the existing `bankai:severity/*` labels**, per the table
below. **Data-loss, corruption, and security-relevant findings are `critical` regardless of
how rarely they reproduce** — they page the human immediately and tag **Tenma** (`CON-8`).
Frequency-independence matters because a 1-in-50 data-loss race is still data loss.

**QA-24 — Findings route by lane, with labels set in the create call.** Product defect →
the target product repo, `bankai:bug` + `bankai:qa/pre-release` + `bankai:severity/*` +
`bankai:stage/triage`, assigned to the human (wakes Tanjiro after triage). Machinery defect
→ the machinery repo that owns the defect, `bankai:agent/kisuke` + `bankai:qa/pre-release` + severity. Canon or rule
gap → `bankai:handbook-question` (`CON-11`, search-first, comment on a match). Performance
regression → as a product defect. Labels and assignee go **in the create call**
(the shared agent conventions, *Human-glance fields*), never as a follow-up edit.

### Severity guidance

| Severity | Use when a finding… |
| --- | --- |
| `critical` | Causes data loss or corruption, is security-relevant (→ tag Tenma, `CON-8`), leaves a user in an unrecoverable state, crashes a primary flow, or is a **>25%** regression / absolute-ceiling breach on P1 or P7. **Pages the human.** |
| `high` | A reproducible defect on a primary flow with a known trigger; an accessibility failure that makes a flow unusable (class 7 / `UX-1`–`UX-3`); a fail-open guard (`QA-18`); an unasserted privileged wake condition (`QA-17`); or a **>10%** regression. Recommended **hold**. |
| `medium` | A reproducible defect on a secondary flow or under a contrived precondition; a flake at ≥20% rate; a budget within 10% but trending. |
| `low` / `nit` | Cosmetic under adversarial conditions; a flake below 20%; a diagnostic observation. Never a hold. |

---

## G. Non-goals

**QA-25 — The quality lane explicitly never:** fixes what it breaks (Tanjiro's, the
Shinigami builder's, or Kisuke's lane); edits **any** non-test source file; tests against
production stores, live user data, or real payment rails (`QA-10`); **blocks, gates, halts,
or withholds** a release — advisory only (`QA-21`, `CON-6`); merges anything; runs a store
submission or deploy (`REL-6` — that is Natsu's); or files a speculation-only finding
(`QA-1`). Most of these inherit live anti-goals from the retired offensive-QA definition;
the last two are new because the lane is now **local and pre-release**, and must not acquire
release-blocking power nor become a second builder.

---

## Quality discipline

- **Cite, never invent.** Every finding names a numbered `QA-{n}` rule — or a public
  reference (`CWE`, `WCAG`, platform HIG/Material) that maps more precisely. No un-cited
  quality opinions; same bar as `SEC-{n}`, `UX-{n}` and `UZF-{n}`.
- **A finding no rule covers → a `bankai:handbook-question`, scope-routed** (`CON-37` refines
  `CON-11`): a missing or ambiguous **`QA-{n}` rule is canon**, so it goes to
  **`bankai:agent/yamamoto`**; only a governance/`CON-{n}` gap goes to `bankai:agent/naruto`, and a
  machinery gap to `bankai:agent/kisuke`. Never improvised policy. Search the repo's open
  handbook-questions first and comment on a match instead of opening a duplicate (`CON-11`).
- **The human's quality calls become rules, not one-off notes.** When the human states a
  threshold or a practice-in-context on a release (e.g. "launch must stay under X here"),
  surface it as a `bankai-handbooks` issue to codify it as a `QA-{n}` rule — so the same call is
  enforced deterministically from then on rather than restated every release. Surfacing is
  not implementing (`CON-3`).

---

## Growing this handbook — how to add a `QA-n` rule

### 1. Propose the rule
Summon **Ichigo** (`/ichigo`) in a local session and describe the quality standard you
want — the defect it prevents, the scenario(s) it binds, and the threshold if it has one.
Bring evidence where you have it: a release that regressed, a defect that escaped, a
measurement you want held.

### 2. It becomes a numbered rule
The rule is written in this handbook's voice: one **normative statement**, the **concrete
threshold** (with its measurement method — a threshold without a method is not a rule,
`QA-15`), and the **rationale**. It is appended to the relevant topical section and takes
the next number in sequence. Numbers are append-only; a superseded rule is marked `RETIRED`
in place, never renumbered or re-purposed.

### 3. Where it lives + INDEX wiring
It lives **here**, in `handbooks/quality-baseline.md` — a **general** handbook that applies
across scenarios, not in a `stacks/<scenario>/` folder. The general-set row already exists
in [`INDEX.md`](INDEX.md) and the cross-cutting row in
[`stack-matrix.md`](stack-matrix.md); a new rule needs no manifest change, but a change to
this handbook's **scope** does.

### 4. Source → mirror: `QA-{n}` is **not** mirrored
The per-surface mirror (`CON-13`) is rendered from `handbooks/stacks/<scenario>/rules/`
**only**. General handbooks — this one, `security-baseline.md`, `ux-baseline.md`,
`uzf-core.md`, `release-policy.md` — are **not** part of that mirror. `QA-{n}` therefore
reaches agents **live**, from a checkout of `bankai-handbooks` at the consumer's pin
(`nen canon resolve`) or through the `bankai-quality` skill. Folding the general set into
the mirror would be a machinery change; no mirror work is required for a `QA-{n}` rule.

### 5. Version bump + consumer cascade (`CON-21` / `CON-22`)
- **Bump [`handbooks/VERSION`](VERSION)** in the same PR: a **new rule** or a wording
  clarification is a **MINOR** bump; a change to a rule's *meaning*, a removal, or a prefix
  restructure is a **MAJOR** bump (pre-`v1.0` carve-out per [`README.md`](README.md)).
  Agents stamp this token verbatim.
- This handbook is **not** a reusable workflow, so a new or changed rule does **not**
  trigger a `CON-22` reusable-workflow fan-out on its own. Consumers adopt it when they next
  **repin their handbooks pin** to a `bankai-handbooks` tag containing it; `CON-21` then cascades that repin down
  any live `integration/*` branches. The affected-consumer determination is recorded in the
  PR.

### 6. It ships as a G4 PR the human merges
The authoring agent opens the PR (`CON-20` real-commit authoring), drives it through the
review gauntlet, and **the human merges at G4** (`CON-7`). No agent merges its own spec
change.
