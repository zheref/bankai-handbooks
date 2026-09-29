# Stack: `bankai-machinery` — Framework / Machinery Review Handbook

The review rules for **Bankai's own machinery** — the reusable workflows, the
consumer/self-hosting `bankai.yml` callers, the guard scripts, the scaffolder
plumbing, and the toolchain/dependency upkeep that live in **Bankai's machinery
repositories** (the CI plane, the CLI, the local plugin, a scaffolder). This is the
**self-review** scenario: the framework eats its own dogfood, so Sasuke and Tenma review
its **machinery** PRs the same way they review a product repo's. Sasuke/Tenma cite these
as **`BC-{n}`**. (Scenario id `bankai-machinery` — renamed at v0.6; the prefix is
unchanged — see [`README.md`](README.md) § *Name and prefix*.)

This scenario **does not generate product code** — there is no UI, no store, no
device. It exists so the framework's own CI has a rule set to apply to itself.

**The general handbooks still apply on top, as for any stack.** A `bankai-machinery`
review loads the general canon —
[`../../uzf-core.md`](../../uzf-core.md) (`UZF-{n}`, insofar as its process/testing
/docs rules bind machinery),
[`../../security-baseline.md`](../../security-baseline.md) (`SEC-{n}`, the primary
family here — CI is a security surface), and
[`../../release-policy.md`](../../release-policy.md) (`REL-{n}`) — **plus** this
folder. `BC-{n}` refines those for the machinery lane; it never contradicts them.
Where a `BC-{n}` rule names a `SEC-{n}`/`CON-{n}`/`CWE` parent, cite both.

Selected by the scenario `bankai-machinery` recorded for a machinery repo in the consumer
registry. Rule numbers are append-only and stable.

Spec/policy authoring is **not** what these `BC-{n}` machinery rules gate. Per `CON-3`
(as amended by `<reference-repo>#304`), `CONSTITUTION.md` + top-level governance are **Naruto's** — CI-deployed
(its governance-author workflow), with `CONSTITUTION.md` allowed by the lane-guard
script's `governance-author` tier; the `handbooks/`, the
Stack Matrix, `schemas/` content, and `agents/*/AGENT.md` are **Yamamoto's** CI
paired-spec lane; machinery is **Kisuke's**. All reach `main` only via a human G4 merge
(`CON-3`, `CON-7`, `CON-24`). These `BC-{n}` rules gate **machinery** diffs (Kisuke); a
Yamamoto paired-spec PR is reviewed by the same pair against the canon it changes.

---

## A. Reusable-workflow contract & permission hygiene (the machinery core)

**BC-1 — A reusable workflow may not out-scope its caller's `GITHUB_TOKEN` grant
(the big one).** A caller's top-level `permissions:` is a hard ceiling: if a called
reusable workflow (or a job in it) requests **more** `GITHUB_TOKEN` scope than the
caller granted, GitHub fails the **entire caller workflow at compile** —
`startup_failure`, **zero jobs, no logs**, nothing to debug from. The Bankai callers
grant only `permissions: contents: read` and do every privileged write with a
**per-agent App token** (`create-github-app-token`), so:
- A reusable workflow's job `permissions:` must stay **within `contents: read`** —
  never request `issues: write`, `pull-requests: write`, `actions: write`, etc. from
  `GITHUB_TOKEN`. Privileged writes go through the minted App token
  (`steps.token.outputs.token`), not `secrets.GITHUB_TOKEN`.
- A new/edited reusable workflow whose jobs raise `permissions:` above the caller
  grant is a **blocking** finding (`request_changes`) — it silently bricks every
  caller.
- *Provenance:* this is exactly what broke `RA-PR-#267` — a reusable asked
  for `issues: write` / `pull-requests: read` while the caller granted only
  `contents: read`, so the whole workflow died at `startup_failure` with no jobs and
  no logs. (`CWE-250` over-privilege is the inverse smell; here the failure mode is a
  hard compile break.)

**BC-2 — Reusable ↔ caller interface hygiene.** A caller's `with:` and `secrets:`
must match the reusable's declared `inputs:` / `secrets:` **exactly**: every
`required: true` input/secret is supplied; no unknown key is passed; types line up.
A required secret referenced in the reusable but not forwarded by the caller (or a
caller passing a secret the reusable never declares) is a finding — it surfaces only
at run time as a confusing failure. When a reusable adds a required input/secret,
the change is **breaking for callers** and must carry a migration note (`BC-8`,
`REL-{n}`) and, for a *consumed* reusable, a `CON-22` fan-out flag.

**BC-3 — Private-repo checkouts use the App token.** Any `actions/checkout` of a
**private** repo (the caller repo itself, or a second machinery/product checkout)
must pass `token: ${{ steps.token.outputs.token }}` — the default `GITHUB_TOKEN`
cannot read a *different* private repo, and an unauthenticated checkout of a private
ref fails opaquely. The App token is minted **owner-scoped** when a cross-repo
checkout is needed (e.g. a scaffolder calling into a private machinery repo).

## B. Trust boundary & fork safety (CI is a security surface — cite `SEC-{n}`/`CWE`)

**BC-4 — Finite `allowed_bots`, never `*` (implements `SEC-14`/`CWE-1357`).** Every
`claude-code-action` step pins `allowed_bots` to the **finite** Bankai trust set
(`roy-bankai,kisuke-bankai,sasuke-bankai,tenma-bankai,gon-bankai,github-actions,
dependabot,renovate` — the set current in canon), never `"*"`. A wildcard lets any
bot actor reach a `bypassPermissions` agent step; the finite list is defense-in-depth
behind the job `if:` guard. A reintroduced `"*"` is a **blocking** finding.

**BC-5 — Every privileged, secret-bearing job is actor-gated in its `if:`.** A job
that mints an App token and/or runs a `bypassPermissions` agent must not wake for an
untrusted actor. Reviews check that the job `if:` enforces, per wake condition:
- **Release / sender-gate:** a stage-label trigger (`bankai:stage/building`) runs
  only when the **sender** is an authorized releaser (`roy-bankai[bot]`, or the
  repo owner as a manual override) — labelling an attacker-controlled issue must not
  wake a privileged job (`CWE-862`, prompt-injection escalation).
- **Reviewer trust:** a `pull_request_review` wake accepts `changes_requested`/state
  only from a **trusted reviewer** (the Bankai reviewer bots or an
  `OWNER`/`MEMBER`/`COLLABORATOR` association) — a review submission needs no write
  access, so an untrusted account must not drive the loop.
- **Fork safety:** a `check_suite`/remediation (or any same-repo-only) path must
  verify the PR is **same-repo, non-fork**, authored by the expected bot — never a
  fork/untrusted head (`CWE-829`). Self-hosted runners serve **private repos only**,
  never fork PRs.
- **Self-trigger break:** the job never wakes on its **own** bot's events
  (`github.actor != '<agent>-bankai[bot]'`), except a bounded remediation path capped
  by a round limit rather than the actor guard.
An added or widened wake condition that skips one of these gates is a **blocking**
finding.

## C. Lane, authorship & the review contract

**BC-6 — Machinery must not encode spec or policy (`CON-3`).** A workflow/script may
**enforce** a rule that already exists in canon, but must not **author** one. A hard
threshold, gate, taxonomy value, or process rule that isn't already in
`CONSTITUTION.md` / a handbook / `schemas/` is a policy decision — it belongs in a
**Naruto spec PR** (merged by the human at G4), and the machinery **waits** on it. A
machinery PR that bakes in a new rule (rather than citing an existing `CON-{n}` /
handbook rule) is a lane violation — the reviewer flags it and points to the required
`bankai:handbook-question` scope-routed to the owning lane (`CON-37`): a `BC-{n}`/handbook gap
is canon (`bankai:agent/yamamoto`), a `CON-{n}` gap is governance (`bankai:agent/naruto`).
Only **Kisuke** authors machinery; the spec it
implements is authored by **Naruto** (governance) or **Yamamoto** (handbooks/schemas/
agent-defs) per `CON-3`/`CON-24`.

**BC-7 — Commit & attribution discipline.** Conventional Commits, always. **Never**
`--no-verify` (the commit-msg guard hook is not bypassable). **No AI/assistant
attribution** in commit messages or bodies. Builder-tier machinery commits carry the
agent's author identity + `Bankai-Agent:` / `Bankai-Run:` trailers
(the shared agent conventions (`_conventions.md`)). An agent never merges its own PR and never force-pushes.

**BC-8 — The automated-review round and a machinery `## How to verify` are
mandatory (`CON-16`, `CON-17`).** No machinery PR merges before its automated-review
round is addressed or rebutted on the record (`CON-16`). Every machinery PR carries a
`## How to verify` section (`CON-17`) written as the **machinery observable proxy**:
the workflow **run** that now fires/passes (link it), the specific **job log line** or
step that proves the behavior, and/or the **guard that now blocks** the thing it's
meant to block — plus, for a *consumed reusable-workflow* change, an explicit
`CON-22` fan-out note (which consumers are affected, computed from
the consumer registry, `nen/repos.json`, and that the governance lane owns the repin). A PR with no usable
verification proxy is not merge-ready.

*Reviewer audit-parity.* The review pair itself must not **abstain** on the very
author whose output this scenario exists to review: the review workflows' author gate
(and their `allowed_bots`) treat **`kisuke-bankai[bot]`** and **`yamamoto-bankai[bot]`** as
audited builder-tier authors, on par with the product builders — otherwise their
machinery / paired-spec PRs pass the
required review check **unreviewed** (`CON-24`; a builder omitted from the reviewed set
is a blocking finding).

## D. Scripts, guards & dependencies

**BC-9 — Machinery logic carries a test.** A non-trivial script or guard (a
`scripts/*.{sh,py,ts}`, a `ci_scripts/*`, a guard hook) ships with its test in the
**same PR** — **bats** for shell, **pytest** for Python, **vitest** for TypeScript
(harness choice per language is `BC-9`'s own mapping; `BC-11` governs which
language a given script may be written in) — covering the behavior and its
guard/failure path, and that suite must actually **execute** in `unit-tests.yml`: a
harness that exists but is never wired into CI does not satisfy this rule (already
true for the Python suites, wired ahead of this PR). A
workflow-embedded shell block with real branching should be extracted to a tested
script rather than grown inline. A logic change with no test delta is a finding unless
the diff is purely declarative (YAML wiring with no branching).

**BC-10 — No major dependency/toolchain bump without a migration note.** A **major**
version bump of an action, CLI, runtime, or SDK lands as a **researched, tested**
change with a migration note describing the breaking delta and how callers/consumers
absorb it; a silent major bump is a **blocking** finding. Patch/minor pins are
mechanical but still pinned (prefer a pinned tag/SHA over a floating ref). Toolchain
changes that alter the execution surface are `SEC`-relevant — review the trust
implications, not just the version number.

**BC-11 — Language choice for machinery (`CON-3`).** Which language machinery is
written in, and what enforcement each language carries, is a process rule — not a
style preference a PR author picks freely:

- **TypeScript is the default** for any machinery carrying branching logic, a
  predicate, a threshold comparison, or a verdict.
- **Shell is permitted only** for: non-branching workflow `run:` glue (interpolating
  `${{ }}`, writing `$GITHUB_OUTPUT`, a single command invocation); environment
  bootstrap that cannot depend on the toolchain it installs (e.g.
  `scripts/install_claude_cli.sh`); the binary-fetch bootstrap; and generated shims
  that forward to the CLI. **Runner-admission gating is not a fifth case.** A script
  that decides whether a job may proceed — a concurrency/capacity check, a
  poll/retry/timeout loop, a threshold comparison against a cap, a three-way verdict —
  carries exactly the predicate/threshold/verdict shape the default clause names,
  whether or not it happens to run before a toolchain-fetch step in the same job.
  Running early is a **workflow-ordering choice**, not a toolchain dependency: the
  bootstrap clause exempts a script that *cannot presuppose* the toolchain it installs
  (`install_claude_cli.sh` cannot depend on the CLI it is fetching); it does not exempt
  a script that merely presupposes *other* tools (`gh`, `jq`) and runs before an
  ordering choice fetches a *different*, unrelated toolchain. Such gating is
  TypeScript, invoked after the CLI's own binary-fetch bootstrap (itself still shell,
  per the clause above) — including where that means paying the fetch cost on a job a
  capacity check then denies a slot to.
- **Python is frozen** at its current six scripts (`scripts/*.py`) — maintained and
  tested (`BC-9`), never extended. New Python machinery is a finding. **The freeze
  reaches embedded Python inside a shell script exactly as it reaches a `.py` file.**
  Python embedded in a shell script (a heredoc, an inline `python3 -c`/`-m` block)
  already present in the repo **before this rule's adoption** (`RR-PR-#753`, merged
  2026-08-25) is frozen debt — maintained under whatever harness already covers it,
  never extended — not a `BC-11` violation merely for being hosted in a `.sh` wrapper
  rather than a `.py` file. Adding or growing embedded Python in *any* shell script,
  the pre-existing ones included, is new Python machinery and a finding, identically
  to adding a seventh `.py` file. A `.sh` extension is not a loophole back into Python.
- **Source-in-git.** A compiled artifact is a build output, never the source of
  truth — machinery logic must be readable in the repository at all times.
  Distributing logic that exists only as a binary is a **blocking** finding: it
  defeats both agent reasoning over the diff and the human gate over what actually
  ships.

`BC-6` already holds that machinery may **enforce** a rule that exists in canon but
must never **author** one; this rule is that principle applied to the choice of
implementation language itself, so a machinery PR cites `BC-11` rather than inventing
a language rule of its own.

*Both bullets above are amendments settling RR-IS-#822:
runner-admission gating (`scripts/wait_for_self_hosted_slot.sh`,
`scripts/count_active_self_hosted_jobs.sh`) is **not** exempt and is tracked as
existing debt on RR-IS-#821's
shrink-only allowlist pending its TypeScript port; the embedded Python inside
`scripts/ichigo_board.sh` and `scripts/ichigo_prompt.sh` predates `RR-PR-#753` and is
frozen-but-not-new, scheduled for the TypeScript port at
RR-IS-#737.*

**BC-12 — Two release lines, and only one of them accepts new logic.** `BC-11` says
which language machinery *may* be written in. This says which release line a given
change may *land on*, because consumers pin to a tag and a rule that only governs
`main` says nothing about what they actually run.

- **`v0.11.x` is the frozen line.** It is the last `<reference-repo>` release on which **every
  consumer-executed machinery path is shell or Python**. The line is not free of
  TypeScript — `cli/` exists from `v0.11.0` and its suite runs in `unit-tests.yml` —
  but nothing a *consumer* executes out of a checked-out `<reference-repo checkout>/` is
  TypeScript, and no binary is published for it. That is the property being frozen:
  **the consumer-facing execution surface**, not the repository's contents. The line
  stays **patchable** — a fix a consumer needs before it can adopt `v0.12.0` lands
  here as `v0.11.z` — but it accepts **no new capability**, and such a patch is shell
  because the binary distribution does not exist on that line to invoke.
- **`v0.12.0` onward is the TypeScript line.** New machinery logic, new subcommands
  and every fix that is not a `v0.11.x` unblock land here, under `BC-11`.
- **A `v0.11.x` patch does not imply a `v0.12.x` port, and the reverse is not
  assumed either.** Where a fix belongs on both, it lands on `main` first and is
  backported deliberately, with the backport PR naming the forward fix. A fix that
  exists **only** on `v0.11.x` is a **finding**: it is a regression waiting for the
  consumer that upgrades.
- **Which line a consumer is on is a fact, never a target** (`CON-14`).
  the consumer registry (`nen/repos.json`) records each consumer's actual
  pin; a consumer sitting on `v0.11.x` after `v0.12.0` ships is not a violation, it
  is a **migration still owed**, tracked as a `CON-22` fan-out.

The freeze exists because the two lines have **different runtime requirements**, not
because one is older. `v0.11.x` needs `bash` + `jq` + `yq` + `gh` present on every
runner that executes a checked-out `<reference-repo checkout>/scripts/*`; `v0.12.0` needs one
binary. That is a consumer-visible change of prerequisites, which is why it is a
`MINOR` bump carrying a `BC-10` migration note rather than a silent continuation.

*Settles the release-line half of
RR-IS-#733 — the epic decided the
language, and left "what happens to the tag consumers are already pinned to"
unstated.*

## E. Anti-patterns (auto-reject)

Reusable job `permissions:` above the caller's `contents: read` grant (`BC-1`) ·
`allowed_bots: "*"` (`BC-4`) · a privileged job whose `if:` omits the sender /
reviewer-trust / fork-safety gate (`BC-5`) · a private-repo `checkout` without the
App token (`BC-3`) · a caller `with:`/`secrets:` that doesn't match the reusable's
declared interface (`BC-2`) · a new hard threshold/gate/taxonomy value baked into
machinery instead of citing canon (`BC-6`) · `--no-verify` or AI-attributed commits
(`BC-7`) · a script/guard with real branching and no bats/pytest/vitest test, or one
whose suite never executes in `unit-tests.yml` (`BC-9`) · a major dependency bump with
no migration note (`BC-10`) · a *consumed* reusable-workflow change with no `CON-22`
fan-out flag in the PR body (`BC-8`) · new branching logic authored in shell —
including runner-admission/concurrency gating — or new/grown Python machinery: outside
the frozen six scripts, or growth of embedded Python beyond its pre-`RR-PR-#753`
baseline within one of them (`BC-11`).

## Glossary (machinery term → where it lives)

| Term | Where |
| --- | --- |
| Reusable workflow | `.github/workflows/*.yml` with `on: workflow_call` in the CI-plane repo |
| Caller / self-hosting caller | a `bankai.yml` that `uses:` the reusables (a product repo's, or the CI-plane repo's own) |
| App token | `create-github-app-token` → `steps.token.outputs.token` (per-agent, scoped) |
| Caller permission ceiling | the caller's top-level `permissions:` (`contents: read`) — caps every reusable job (`BC-1`) |
| Trust set | the finite `allowed_bots` list + the job `if:` actor gates (`BC-4`, `BC-5`) |
| Guard / script | `scripts/*`, `ci_scripts/*`, guard hooks — tested with bats/pytest/vitest, executing in `unit-tests.yml` (`BC-9`); TypeScript is the default language for new branching logic (`BC-11`) |
| Consumed reusable | a reusable a product `bankai.yml` references (the consumer registry's `consumes` field) — its change is a `CON-22` fan-out trigger |
