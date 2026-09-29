# Shared Agent Conventions

> **Provenance and reading notes (`zheref/bankai-handbooks`, handbook set v0.6, 2026-09-28).**
> Migrated from the frozen, private reference implementation (`<reference-repo>`, tag `v0.11.3`,
> where it sat beside the agent definitions) as the companion the constitution calls "the one
> shared edge, read by every agent" (`CON-3`). It lives at the repository root beside
> [`CONSTITUTION.md`](CONSTITUTION.md) because it applies to every agent on every stack and
> carries no rule-id family of its own — it is not one of the handbooks `handbooks/INDEX.md`
> loads; the handbooks cite it as "the shared agent conventions".
>
> *Redaction.* As in the constitution: private repositories by placeholder, their object ids by
> `RR-`/`RS-`/`RA-`/`RB-` with the number kept ([`docs/PUBLIC-REDACTION.md`](docs/PUBLIC-REDACTION.md)).
> *Machinery.* The machine-readable companions this file describes — the colour registry, the
> label registry, the consumer registry, the PR/issue templates, the readiness gate, the gate-stop
> and board helpers — are machinery, not canon, and stay with the planes (Nen carries
> `nen/colors.yml`, `nen/labels.json`, `nen/repos.json` and `nen pr ready`; Hatsu carries the
> templates and the stop/board skills). They are named here by role.
> *Precedence.* Where § *Commit attribution* names the reference implementation's trailers and
> bot identities (`Bankai-Agent:`, `Bankai-Run:`), `CON-51(c)` governs on the successor planes:
> `Hatsu-Agent: <persona>` locally, `Akatsuki-Agent: <persona>` on the CI plane, never any AI
> attribution. Every other convention here stands as written.

Every agent output MUST follow these conventions. They are what make attribution
glanceable, runs auditable, and the artifact bus parseable.

## Output header (top of every PR/issue/review/comment body)

```
> **{Character} — {Class}** · {one-line action summary}
> handbook `vX.Y` · [run ↗]({actions run url})
```

**Local-agent variant (Ichigo — no CI run).** A local agent has no Actions
run to link, so its second line replaces `[run ↗]({actions run url})` with `local, on your
creds`:

```
> **{Character} — {Class}** · {one-line action summary}
> local, on your creds · handbook `vX.Y`
```

## Machine stamp (bottom of every body, invisible)

Every agent output carries the base stamp:

```html
<!-- bankai agent={name} run={run_id} handbook={version} trigger={event} -->
```

**Local-agent variant (`CON-50(f)`) — a session mints its own identity.** A CI stamp's
`run={run_id}` is GitHub's own guaranteed-unique counter; a local session has no equivalent to
borrow, and `CON-27`'s worktree name is not a substitute — it is chosen per *effort*, not per
*session*, so two concurrent local sessions that both (mis)read the same issue as theirs can
still land on the same worktree/branch slug, which is exactly `CON-50`'s failure mode, not a fix
for it. So a local session **mints its own** token instead: on first use in a session — the
moment its own in-session state has not yet recorded one (`CON-50(a)`, before its first
authoring commit, and **never inferred from the marker file's mere presence** — see the collision
rule below) — generate an 8-hex-char random token (e.g. `openssl rand -hex 4`; 32 bits, ample
headroom for this repo's actual concurrency of a handful of simultaneous local sessions —
collision probability only becomes material near tens of thousands of concurrently-minted
tokens) and persist it as a single-line marker file at the worktree root
(`.bankai-session`); every later stamp the same session posts reads
that file back rather than minting again, so the token is **stable for the life of the session**.

**A pre-existing marker file is a collision, not a re-read.** If `.bankai-session` already exists
the first time a session that has not yet minted its own token reaches this step, that file is
**not this session's own** — it is two sessions landing on the same worktree/branch slug,
`CON-50`'s exact failure mode, not a fix for it. The session MUST fail closed: never silently
adopt the existing token as its own, and report the collision on the issue per `CON-50(d)` rather
than authoring under an identity it did not mint. Handled this way, a freshly minted token
**distinguishes two concurrent sessions that land on different worktree/branch slugs** — the one
property `CON-50` requires and a shared effort name does not give for free — while two sessions
sharing the *same* slug remain `CON-50(c)`'s claim check to catch before either authors anything,
not a case this stamp silently papers over.

```html
<!-- bankai agent={name} session={session_id} handbook={version} trigger=local -->
```

`session_id` is that minted token; `trigger` is the literal `local` (there is no GitHub event to
name, and the fixed value lets a reader tell a local stamp from a CI one at a glance without
checking `agent`). `agent` stays the session's own name (`ichigo`) unqualified by `CON-46`'s
nature: a nature doesn't distinguish two concurrent sessions of the *same* nature, which is the
whole requirement this stamp exists to satisfy, and it is already legible to a human reader from
the `Session / lane` column (Ichigo's agent definition) wherever one is shown.

**Where it appears — before a PR exists.** `CON-50(a)` requires a lane-less local build to record
its claim **on the issue**, before authoring anything, so this stamp is not only a PR footer. The
session's first action after entering its worktree and confirming the claim is its own
(`CON-50(c)`) is an **issue comment** carrying the visible local header (above) and this machine
stamp; every stamp the same session posts afterward — further issue comments, the PR body, PR
follow-up comments — carries the identical `session=` value. A reader, human or agent, can then
grep one token across an issue and its PR and see the whole session's footprint, and a peer
session reads it as `CON-50(a)`'s claim-holder before authoring anything of its own.

### Reviewer verdict (Sasuke, Tenma, Bisky)

A **review** MUST end with a final, standalone line stating the verdict on one
line — this exact line is what the workflow reads and casts as a formal GitHub
review (a status emoji trails the value, for the human — see below):

```
Verdict: approve ✅
```

Use exactly one value:

- **`request_changes`** — a **blocking** finding (`critical` or `high`). Casts a
  `REQUEST_CHANGES` review; the PR is blocked until re-review.
- **`approve`** — no blocking findings (`medium`/`low`/`nit` may still be noted,
  but the bar is met). Casts an `APPROVE` review.
- **`comment`** — advisory only. Casts a `COMMENT` review.

The workflow reads the **last** `Verdict:` line from **your own app's** review
comment for **this run**, and takes the value adjacent to it. Keep it fail-safe:

- Put the value **on the same line** as `Verdict` (`Verdict: approve`). A bare
  heading with the value on the next line (`### Verdict` then prose) is **not**
  read.
- If no `Verdict:` line is found, or the value isn't one of the three, the run
  **fail-closes**. Two things happen, and they are **not** the same thing: it casts a
  non-blocking `COMMENT` **event** — so the failure is on the record where a reader
  meets it — **and it fails the check** (`CON-35` row 3). It never greenlights, and it
  never counts as a review.
  **That `COMMENT` is the *event*, not the `comment` *verdict*.** A deliberate
  `Verdict: comment` is a real, **passing** advisory disposition (above) and is wholly
  unaffected by this bullet: **two different code paths cast the same `COMMENT` event
  with opposite check outcomes** — advisory verdict → check **passes**; no verdict →
  check **fails**. Never compress "`CON-35` row 3 is red" together with this bullet
  into "`comment` is red": that would silently delete a disposition in live use
  (RR-PR-#295 is a deliberate advisory pass; RS-PR-#5's 2026-07-25
  runs are the fail-safe). **Cite a run *attempt* — not a PR, and not even a bare run
  id.** These rows classify a single **execution**, and the same PR — even the same run
  **id** — can land in different rows on different attempts, because `gh run rerun`
  **reuses the id**. RS-PR-#9's run `30846319340` is the case in point:
  **attempt 1** (2026-08-03) took the fail-safe path, while **attempt 2** (2026-08-10,
  a re-run) is `CON-35`'s flagship **row-2** case — and on attempt 1 its **Tenma** job
  fail-safed while its **Sasuke** job produced a verdict, so even one attempt splits by
  reviewer. "PR #N is the fail-safe" is therefore never a well-formed claim, and
  "run R is" is only well-formed with the attempt.
  ⚠️ **The two are indistinguishable by review *state*** — both render `COMMENTED`.
  Only the **body** separates them (`verdict: \`comment\`` vs. *"did not complete a
  review this run"*). So never infer "a review happened" from a `COMMENTED` state
  alone — read the body, or read the check.

**A status emoji on the verdict — for the human — is required, and goes AFTER the value:**

```
Verdict: approve ✅
Verdict: request_changes ❌
Verdict: comment 💬
```

So the human grasps approve vs changes-requested at a glance without reading the body. The parser
reads the value token immediately after `Verdict:` and ignores anything trailing, so a **trailing**
emoji is safe (verified against the extraction regex). **Never put the emoji — or anything else —
*between* `Verdict:` and the value** (`Verdict: ✅ approve`): that makes the value no longer adjacent
to `Verdict:`, the match fails, and the gate **fail-closes to a red check**. Emoji trails the
value, never leads it.

**A produced verdict outranks its run's step status (`CON-35`).** The gate's question is *"did a
review happen, and what did it conclude?"* — **not** *"did the harness process exit cleanly?"* So
when a conforming `Verdict:` line exists **for this run** and the agent step **then** reports
failure, the **verdict is authoritative**: it is what **the human's own merge decision** at G2/G4
and, above all, any **dismissal** decision act on — those follow the verdict, not the check's colour
— and the reviewer's required check **MUST** be made to reflect it (`approve`/`comment` pass,
`request_changes` fails). **No agent merges past a red required check on a parsed verdict**: Roy's
`integration/*` carve-out stays gated on CI green (`CON-5`), and this rule does not widen it.
The step's exit status is only a *proxy* for "a review happened"; the posted review is the
*evidence*. When proxy and evidence disagree, the evidence governs.

⚠️ **Status — the machinery does not conform yet.** Today a reviewer job's conclusion still follows
its **agent** step, so a post-verdict failure still shows a **red check next to a valid verdict**
(RS-PR-#9 **attempt 2** and RS-PR-#16, RA-PR-#312 — fully qualified in `CON-35`'s evidence
list). Making the job's conclusion follow the **verdict-cast**
step is Kisuke's (`CON-3`, routed on RR-IS-#291). Until that lands, read the rows below as the rule for
**what to act on**, not as a description of what the check currently shows — and in particular, a red
reviewer check is **not** grounds to dismiss a posted verdict.
**`CON-32` readiness is the one exception, and it is unchanged:** *ready* is defined as every
required check passing, so a red reviewer check still blocks a readiness claim even on a valid
verdict. Do **not** report such a PR ready — take it to the human with the verdict cited as evidence
the *review* passed.

**The discriminator is the artifact, never the harness error name.** Do not enumerate failure
modes (`error_max_turns` vs. a crash vs. a timeout) — such a list rots and binds this spec to a
runner's internals. The presence of a conforming verdict already separates the cases cleanly,
because the `Verdict:` line is by rule the review's **final** line:

| Run shape | Authoritative signal | Reviewer check |
|---|---|---|
| Conforming `Verdict:` for this run, step **succeeded** | the verdict | per the verdict |
| Conforming `Verdict:` for this run, step **failed afterwards** | **the verdict** — plus a degradation record (below) | per the verdict |
| **No** conforming verdict — any cause: crash, stub comment, API stall, truncation *before* the verdict | **none — the review did not happen** | **red**, never a neutral pass (a `COMMENT` **event** is still cast so the failure is on the record — that is not the `comment` **verdict**; see the fail-safe bullet) |

Row 3 is the no-verdict fail-safe above, **unchanged and undiminished**: *never merge on an
unreviewed run* still holds in full, because every failure that actually prevents a review from
happening lands in row 3.

**Emitting the verdict asserts completeness.** Emit `Verdict:` only when your review is
**finished** — never as a placeholder, never mid-analysis, never "in case I run out of room".
Under this rule that line is what the merge gate acts on, so a premature verdict is a
**conformance defect in the agent** (fix the agent), not a reason to keep a gate that also
destroys complete reviews.

**Honouring a degraded run is never silent.** A run whose verdict is honoured over a failed step
MUST leave a **durable degradation record**, legible *without* opening the run log: on the run (a
warning annotation naming the resource consumed vs. its limit — turns used vs. `--max-turns`,
where the harness reports it) **and** on the formal review body (a line saying the review
completed on a degraded run and what ran out). Otherwise a green check hides the degradation,
"just re-run it" keeps working, the limit is never raised — and the next slightly larger PR fails
again, that time *before* the verdict, where it genuinely blocks. The record is what makes this
class **converge** instead of recur.

**A complete review is not dismissed on its run's status.** Never dismiss a formal review because
its job went red — dismissal is **irreversible** and destroys review work no re-run reproduces. A
verdict is dismissed only for a defect in the review's **content** (a finding refuted, a
superseded head per `CON-16`'s current-head rule), never for the colour of the check that carried
it.

**Verify against the LIVE artifact — never cast a blocking verdict you can't currently substantiate.**
A `request_changes` is a *blocking* claim. Before casting one on a **time-sensitive** finding — the
PR body lacks a `## Screenshots` section, a file wasn't added, a label isn't set, a review thread
wasn't answered — **re-verify it against the live artifact at review time** (`gh pr view <n> --json
body,files,…`, `gh api …/pulls/<n>/comments`), **not** the event/dispatch snapshot you were handed.
The live state can differ: a fix can land seconds after the run was dispatched, and a re-run
(`gh run rerun`) **replays the original event payload**, so that snapshot is stale by construction.
If you **genuinely cannot** verify a finding against live state (the fetch fails or is denied), you
**must not** re-assert it as blocking from the stale snapshot — cast **`comment`** (advisory) with an
explicit "**could not verify against the live PR — needs human/independent confirmation**" note, and
leave the finding non-blocking. A blocking verdict a reviewer cannot substantiate against the live
artifact is a false red that dead-caps the wave (observed: RA-PR-#223 — three consecutive false
`request_changes` on an already-resolved screenshots finding, re-asserted each time from stale
dispatch context). Only a finding you can **currently** substantiate blocks.

Non-review artifacts (epics, issues, comments) carry no verdict line.

## Readable output — tables first, emojis to scan

The human in the loop (and every downstream agent) reads a lot of these artifacts across GitHub
threads. Structure output so it can be **traversed at a glance** — the goal is to *synthesize*
information into a denser, more navigable shape, **never to drop it**. Every finding, step, and
route that a bullet list would carry is still present; it is just laid out to be scannable.

**Tables are the default for any set of ≥ 2 comparable items.** Findings, next steps, routing
decisions, gate/check status, per-item results, options — render as a Markdown table, not a bullet
list. Bullets scatter across sections and are hard to track across a long GitHub thread; a table
keeps every item's facts on one row under stable columns. Reserve bullets/prose for genuinely
*sequential* narrative (e.g. a `## How to verify` step list) or a single point.

Give a table explicit, parseable columns — so a human scans it **and** a downstream agent picks a
row apart reliably. Keep the load-bearing facts in their own cells: `file:line`, the **cited rule**
(`UZF-26`, `SEC-14`, …), severity, the concrete action, the owning agent, the issue/PR ref. A
findings table, for example:

| # | 🔴/🟡/🟢 | Finding | `file:line` | Rule | Action / owner |
|---|---|---|---|---|---|

**Lead with a one-line status** carrying a state emoji, then the tables, then any prose. Use a
**small, consistent emoji vocabulary** as scan anchors — relevant, never decorative spam:

| Emoji | Means | Emoji | Means |
|---|---|---|---|
| ✅ | done / pass / green | 🔎 | finding / observation |
| ⚠️ | warning / needs attention | ➡️ | next step |
| ❌ | blocking / failed | 🔀 | routing / hand-off |
| 🔴 🟡 🟢 | severity high / medium / low | ⏳ | waiting / in progress |

**Colours are reused across categories, and the category is what disambiguates them** — see
§ *Colour matrices* below for all three (severity, lifecycle status, agent identity) and the one
rule that keeps the reuse safe.

Character identity emojis stay as each agent's own (🟠 Naruto, 🟠 Yamamoto — the spec-plane
siblings, 🟥 Ichigo — the red **square**, deliberately, so it cannot collide with the 🔴🟡🟢
severity markers above — and each CI agent's header badge); they belong in the **output header**
(§ *Output header*), which is what keeps them clear of the severity and status circles used in
tables. This convention applies **equally** to GitHub comments/PR/issue bodies **and**
local-agent (Ichigo) responses.

**Never at the cost of machine-readability — the parsed markers are exempt and unchanged.** The
following are consumed verbatim by workflows or other agents and MUST appear **exactly** as their
own sections specify — never wrapped in a table cell, never emoji-decorated, never reworded:

| Marker | Where |
|---|---|
| the machine stamp — exact format per **Machine stamp** above, CI **or** local shape: `<!-- bankai agent={name} run={run_id} handbook={version} trigger={event} -->` (CI) or `<!-- bankai agent={name} session={session_id} handbook={version} trigger=local -->` (local, `CON-50(f)`) | bottom of every body |
| the `Verdict: <value>` line — value immediately after `Verdict:` (a status emoji may trail it, never precede it — see **Reviewer verdict**) | reviewer artifacts (Sasuke / Tenma / Bisky) |
| `Closes #<issue>` / `bankai:*` labels / stage transitions | as specified above |
| commit trailers (`Bankai-Agent:` / `Bankai-Run:` in the reference implementation; `Hatsu-Agent:` / `Akatsuki-Agent:` on the successor planes, `CON-51(c)`) | commit messages |

Tables and emojis dress the **human-facing narrative**; they never touch these. Because the
structured facts now live in explicit table columns (file, line, cited rule, action, owner),
another agent parsing your output for hand-off, resolution, or the next iteration gets **more**
reliable structure than prose bullets, not less — that is the point.

## Colour matrices — severity, status, identity

Three categories use colour, and **they deliberately share glyphs**. 🔴 is `high` severity *and*
`blocked` status; 🟠 is Naruto's and Yamamoto's badge *and* `in progress`. That is intended, not an
oversight — each category is a closed vocabulary and a colour only ever means something *inside*
one.

> **The one rule that makes the reuse safe.** Every table that renders a colour **names the
> category in its column header** (`Severity`, `Status`); identity badges appear **only in the
> output header**, never in a table cell. A bare coloured circle with no column saying which matrix
> it came from is a defect, not a shorthand — and two categories in one column is likewise a
> defect: split the column.

**The machine-readable form is the colour registry (`nen/colors.yml` on the successor planes; `schemas/colors.yml` in the reference implementation)** — glyph, hex, meaning
and precedence for all three categories. Scripts, agent specs and prompts read *that*; this section
is its prose. Never hard-code a glyph you guessed, and never let the two drift: a change here is a
change there, in the same PR.

### Lifecycle status — one per issue/PR

| Colour | Status | Applies when |
|---|---|---|
| 🔵 | **Intentionally on hold** | Deliberately parked pending another effort's resolution. **Always name what it waits on** — a blue row without a named dependency is an orange row with better manners |
| 🔴 | **Blocked** | A **G5** decision or human-only action is required before anything can move |
| 🟢 | **G2/G4-ready** | the deterministic readiness gate (`pr_ready_gate.sh` in the reference implementation; `nen pr ready` on the successor planes) reports the PR `CON-32`-Ready and mergeable — faithfully ready for human review |
| 🟡 | **G1-ready** | Ready to be started, or to have its spec iterated — at **G1** (`CON-4`) or **G1-M** (`CON-25`) |
| 🟠 | **In progress** | Work is moving: jobs queued or running, review rounds outstanding, the author iterating |

**Precedence — apply the first that matches and stop: 🔵 → 🔴 → 🟢 → 🟡 → 🟠.** An explicit hold
outranks everything, because it is an instruction *not* to act while every other colour invites
action; blocked outranks ready, because a row that is both carries a dependency the merge will not
satisfy. Without a stated tie-break, two agents render the same row differently and the vocabulary
stops being one.

**🟢 is a claim about a script's output, not an impression.** Only the readiness gate's verdict makes
a row green — never a glance at the checks page, which cannot see `CON-16`'s current-head rule (two
approvals that *predate* the latest push look identical to two that follow it, and only one of
those is Ready).

**🟠 is not a gate, and in-progress work is never 🔴.** An unfinished PR belongs to its author until
it is Ready (`CON-32`); the human is not waiting on it and must not be shown as if they were.
Reserve 🔴 for items only they can move — a secret or credential (`CON-2`), a repository setting or
ruleset, an option to pick, a policy shape to rule on, a conflict to escalate. Marking in-progress
work 🔴 inflates their queue with things nobody is asking them for, which is a reporting defect in
its own right (RR-IS-#631).

### Severity — unchanged

| Colour | Severity | Means |
|---|---|---|
| 🛑 | `bankai:severity/critical` | Blocks and **pages** the human immediately (`CON-8`), overriding normal cadence |
| 🔴 | `bankai:severity/high` | Must fix before merge/release |
| 🟡 | `bankai:severity/medium` | Fix soon |
| 🟢 | `bankai:severity/low` | Nice to fix |

`high`/`medium`/`low` keep the circles they have always had. **`critical` is the one addition** —
it previously had no glyph at all, in a four-level taxonomy rendered with three colours. It is
deliberately **not** another circle: `critical` is not "high, but more", it is the level that pages
you, and it should not be readable as a shade of the one below it. Hex values mirror
the label registry (`nen/labels.json`) and are factual (`CON-14`) — change them together or not at all.

### Agent identity — unchanged, and incomplete

🟥 Ichigo (a **square**, deliberately, so it cannot collide with the severity/status circles) ·
🟠 Naruto · 🟠 Yamamoto, the spec-plane siblings sharing a glyph by design.

**Only these three have ever defined a badge.** The colour registry lists every other agent with
`emoji: null` — *unassigned*, not absent — so that a script reads a gap instead of inventing one.
Assign the rest in a PR that touches their own `AGENT.md` files; do not backfill them into the
schema alone.

## Commit attribution (builder-tier agents)

> **Precedence note (`CON-51(c)`).** The author identity and trailers below are the reference
> implementation's (`Bankai-Agent:` / `Bankai-Run:`, the `@agents.bankai.dev` bot identities). On
> the successor planes the canonical trailer is `Akatsuki-Agent: <persona>` (CI) or
> `Hatsu-Agent: <persona>` (local), and nothing else — no model, surface, runtime, session or
> "generated-with" attribution, no `Co-Authored-By:` naming an assistant. Everything else in this
> section and its local variant — Conventional Commits, never `--no-verify`, never force-push, the
> header stanza on the PR — stands.

- Git author: `{Character} (Bankai {Class}) <{name}@agents.bankai.dev>`
- Pushing identity: the agent's GitHub App.
- Trailers: `Bankai-Agent: {name}` and `Bankai-Run: {actions run url}`
- Conventional Commits, always. `--no-verify` never.

### Commit attribution — local variant (Ichigo)

A **local** builder runs in the human's Claude Code session on the human's own credentials —
**no GitHub App, no CI run**. So the CI recipe above does not apply verbatim; use this variant
(this is how every local PR is signed, whichever nature authored it — `CON-46`):

- **Git author: the human** — the commit is pushed from the human's own clone on their creds;
  there is no bot author and no `{name}@agents.bankai.dev` identity.
- **Pushing identity: the human's credentials** (no App).
- **Trailer: `Bankai-Agent: {name}` only** (e.g. `Bankai-Agent: ichigo`). **Drop
  `Bankai-Run:`** — there is no Actions run URL for a local session.
- **Attribution also via the output-header stanza** at the top of the PR body (below): the
  `> **{Character} — {Class}** · …` line, with `local, on your creds` in place of the
  `[run ↗]` link (there is no run to link). Between the header stanza and the `Bankai-Agent:`
  trailer, the local builder's identity is stated on the PR exactly as it is for CI builders.
- Conventional Commits, always. `--no-verify` never; force-push never.

## State machine

Exactly one `bankai:stage/*` label per issue/PR at all times. Agents transition stages
only as specified in their AGENT.md; never skip stages; never touch another agent's
transitions. Add your `bankai:agent/{name}` label to artifacts you own.

## Human-glance fields (every issue/PR you create or open)

So the human can scan and filter their queue at a glance, ALWAYS set these on creation —
in the create call itself (`gh issue create --label … --assignee …`,
`gh pr create --assignee …`), not as an afterthought:

- **Labels** — the relevant `bankai:*` set: the current `bankai:stage/*`, your
  `bankai:agent/{name}`, and any **kind** marker — an **epic gets `bankai:epic`**, a bug
  gets `bankai:bug`, plus severity where it applies.
- **Assignee** — assign the **human maintainer** (call this "the repo owner" loosely, but be
  precise about *who*): in a **user-owned** repo it is the owner, `github.repository_owner`; in an
  **org-owned** repo `github.repository_owner` is the **org** (not a person, and GitHub won't
  accept it as an assignee), so assign a **designated human maintainer** configured for the repo —
  never the org login. Every
  issue and every PR an agent opens is assigned to the human so it surfaces in their
  "assigned to me" view.
- **Links** — connect the artifact to its context: child issues reference their parent
  epic; a PR that **completes** an issue includes `Closes #<issue>`; a PR that delivers only
  **part** of an issue writes `Part of #<issue>` (or `Refs #<issue>`) — **never `Closes` from a
  partial PR**: GitHub honours the keyword, not any qualifier after it, and auto-closes the
  umbrella on merge (observed: RR-PR-#546
  closed RR-IS-#545). Everywhere else —
  prose, tables, comments — write references in the **object notation** (§ *Object references*).

## Object references — `<CODE>-<IS|PR>-#<N>`, always clickable

A bare `#386` does not say which repo it lives in or whether it is an issue or a PR, and a
reader who follows dozens of these across the machinery repos and their consumers cannot afford to guess.
Every issue or PR mentioned in prose, tables, review findings, stamped comments and status
reports is written as:

```
<PRODUCT-CODE>-<IS|PR>-#<NUMBER>      e.g.  RR-PR-#121   RA-IS-#221   RS-PR-#9
```

- **Product codes** come from one registry — the consumer registry (`nen/repos.json →
  product_codes`); add a code there before naming a new consumer or support repo. In this public
  text the placeholder codes `RR` (the reference implementation), `RS` (the scaffold repository)
  and `RA`/`RB` (private products) stand in for real codes. `IS` = issue, `PR` = pull request.
- **The `#<N>` part is a link.** In Markdown bodies and comments, wrap the whole token in a
  Markdown link to the object (the token as the link text, the issue's or PR's URL as the
  target). In terminal output use an OSC-8 hyperlink where the renderer supports it (the local
  prompt renderer does); in plain
  text keep the token whole — never split it across lines.
- **GitHub's own wiring stays where GitHub needs it.** A closing keyword (`Closes #N`) is what
  populates the issue's *Development* panel and auto-closes on merge; `Part of #N` / `Refs #N`
  and `owner/repo#N` create a timeline cross-reference (no Development link — add one from the
  sidebar when it matters); sub-issue relations are set via the API/UI. The notation is for
  humans reading across repos and does not replace any of these.
- **Templates and examples** use the notation in their illustrative text
  (the PR/issue templates and the agent definitions); placeholders such as `#{issue}` in the
  keyword lines stay as they are.

### Every stop for the human names its gate and shows the whole picture

When an agent stops for the maintainer — G1 epic approval (`CON-4`), G1-M release into build
(`CON-25`), G2 merge (`CON-5`), G3 release go/no-go (`CON-6`), G4 policy/spec (`CON-7`), or
**G5, any other decision or human-only action** (an option to pick, a permission/secret/settings
change only they can make, a credential-bound step, a conflict to escalate) — the message
**names the gate**, states whether a **push notification** was sent for it (where a channel
exists), and reports **every** in-flight item of the run/session in a table, not only the one
being asked about: `Effort | Open issues & PRs | Status (gate) | Thought flow | Session / lane`.
The **Status** cell leads with the canon status colour (§ *Colour matrices*; machine-readable in
the colour registry) — the same circle, meaning the same thing, as on a `bankai:backlog-state`
board or a `backlog-loop` cycle table.
The local reference implementation is Ichigo's prompt protocol
(Ichigo's agent definition and its gate-stop helper — which raises an OS
notification and an audible cue before drawing the banner, since only a MAIN session can fire the
harness push, `RR-IS-#614`); CI agents express the same in their stamped comment.

**On a surface that can render one, the gate board is where the stop happens
(RR-IS-#693).** The board renderer
publishes the same data as an Artifact, and the accompanying chat is then **about five lines** —
the banner, one line naming the gate and the single most important ask, the link. Three rules make
the difference between a board and a bulletin:

- **The board's content is the REPO's live backlog, not the session's held work**
  (RR-IS-#700). Every other rule here says how
  to paint; this one says what to paint, and its absence is why a cleared session once answered a
  board request with *"I have nothing in progress."* Resolve the repo from the working directory's
  `origin` against the consumer registry — an unresolvable remote is an error, never a guess —
  compute the rows with `bankai:backlog-state`'s own rules (its fetch, gate decision tree,
  readiness-gate verdict, colour precedence and ordering; there is no second method), and
  fetch fresh at every stop. Session memory is at most a `Session · Lane` value on a row the backlog
  already produced — never the reason a row exists, and never the reason one is missing.
- **An ask states the DECISION, not its destination.** It leads with its kind — **`DECIDE`**,
  **`DO`** or **`MERGE`**, uppercase, as the first word — and a `DECIDE` carries the question, the
  lettered options, a ⭐ recommendation (or a plain statement that there is none), and what would
  tip it. *"Rule on RR-IS-#680"* names a tab to open, not a choice to make.
- **In-progress work goes to `G0`, which sorts last.** A running job or a background operation is
  worth showing and is **not** the human's. Ranking it above a real gate inflates their queue with
  things nobody is waiting on them for
  (RR-IS-#631).
- **Regenerate at every stop; never re-link the last board.** Counts, verdicts and the timestamp
  go stale within minutes, and a stale board carries a fresh one's authority.
- **The board briefs a decision; it never captures one**
  (RR-IS-#696). Options render as a readable
  enumeration, and the question is asked through the question interface the harness already
  provides — synchronous, no capability, and the answer lands in the conversation rather than in
  a republished copy of the page. A decision control on the page is answered only when a session
  happens to be watching, and only by the owner.

Where the generator cannot run, the banner plus the padded table is the whole stop — the table is
the degradation, not a parallel emission, and the degradation is **lossy**: the asks survive
(they are what the gate is), the backlog register does not, and that loss is stated in one line
rather than left to be discovered
(RR-IS-#700). A board the maintainer **asked
for** — `bankai:backlog-board` — is the one thing that is not a gate event: no banner, no
gate-stop helper, no push notification. The G5 clause itself lives in `CONSTITUTION.md`
(RR-IS-#555).

## Delivery summary — lead every human-merged PR with what it changes for them

Any PR a human must approve — **G2** product code and **G4** spec alike — opens with a
**`# What this changes for you`** section, **before** any technical detail. The reviewer is
deciding whether to merge; they need the *intent* and the *effect* first, and the mechanism second.

Write it for someone who has not been following the work:

- **Lead with the effect, not the diff.** "A stalled chore can now advance without waiting on you"
  beats "adds `CON-46(c-i)`".
- **Say what they keep and what they give up.** A change that removes a safeguard, narrows a gate,
  or shifts a decision must say so **in plain words**, in this section — not buried in a clause.
  Understating a cost here is worse than not summarizing at all.
- **Use a table** when there is a before/after, a set of conditions, or several affected surfaces —
  tables-first applies here as everywhere (§ *Readable output*).
- **Use a `mermaid` diagram** when the change alters a *flow* — who acts, in what order, where the
  human's gate sits. One diagram that shows the gate surviving is worth a paragraph claiming it does.
- **Keep it short.** A screen at most. Everything else goes below, under its own headings.

The technical detail — clause text, affected agents/repos, `CON-22` fan-out determination,
version-tag proposal, cross-lane declaration, review history — follows **beneath** this section,
unchanged in rigour. This convention changes the *order and the audience of the opening*, not what a
PR must contain.

A PR whose body opens with implementation detail, or whose summary omits a cost the change actually
imposes, is **not merge-ready** — the same bar as a missing `## How to verify`.

## Human verification plan (every PR gated on a human merge)

Any PR a human must approve — product code at **G2** (Roy, Edward, Alphonse, and any
builder-tier agent, plus Ichigo locally) and canon spec at **G4** (Naruto, Yamamoto, or
Ichigo locally) — MUST carry a `## How to verify`
section in its body **beneath the delivery summary above**, written for a human operating the
running app/system, NOT for CI. It is
the human's manual test plan: how they confirm the PR actually does what it claims before
merging. A PR without a usable one is not merge-ready (`CON-17`).

For EACH behavior / acceptance criterion the PR delivers, give a scenario block:

```
### <scenario — tie it to the issue's acceptance criterion>
**Setup:** <preconditions: build target, branch, seed data, feature flag, account>
**Steps:**
1. <concrete action — name the exact screen / route / command / input>
2. …
**Expected:** <the exact observable result that confirms success>
```

Rules:
- Be specific to THIS change — never generic boilerplate. Name the real screens, routes,
  commands, and values the human can act on.
- For behavior not exercisable from the UI (pure logic, effects, background work), give the
  **observable proxy**: the unit test to run (`<cmd>`), the log line, the state/store/DB
  change, or the API response to inspect.
- If a change has no runtime-observable behavior (pure refactor, infra, docs), say so
  explicitly and give the **regression check** instead (which existing tests cover it / what
  to re-read), so the human still knows how to gain confidence.
- Every acceptance criterion the PR closes has a matching scenario. Nothing is presented as
  done that the human cannot actually check.

**Aggregation at the final PR.** When a coordinator opens the single `integration/<epic> →
main` PR (bankai mode), its `## How to verify` CONSOLIDATES the child PRs' scenarios into one
end-to-end plan for the whole epic — the human tests the assembled feature once, at the one
G2, without hunting through the merged child PRs. See the PR template.

## Screenshot evidence layout (every PR carrying a `## Screenshots` section)

The layout is `UZF-26`'s (`handbooks/uzf-core.md`), not any one builder's private template: one
table per top-level user-facing screen, titled with the issue(s) that composed it, changed
states across the columns. Every lane that opens a UI PR — Edward, Alphonse where its change
touches a rendered surface, Ichigo-as-Shinigami, and Roy's epic-delivery compose — follows that
layout; this file does not restate it.

## Discipline

1. **Idempotency** — before acting, search for a prior stamp and act on it rather than
   duplicate. On an existing artifact (a PR, a review), find *your own* prior stamp and
   update it. Before **filing a new issue** — above all a `bankai:handbook-question` —
   first search the repo's OPEN issues of that kind by subject (`gh issue list --state
   open --label bankai:handbook-question --search '<subject>'`); if the same gap is
   already open — yours or another agent's, **even from the same run** — comment on that
   one instead of opening a second. One open issue per distinct question; a single run
   must never file it twice.
2. **Iteration caps** — max 5 build↔review rounds per PR, then escalate to the human.
   Never trigger on your own bot events.
3. **Citations** — reviewer findings must cite a numbered handbook rule; no un-cited opinions.
4. **Cost footer** — report model + token usage in the machine stamp when available.
5. **Human gates** — G1 epic approval, G2 merge, G3 release, G4 policy. Never work
   around a gate; when blocked on one >24h, that is Killua's problem, not yours.
6. **Findings for a PR's author go as a `request_changes` review, never a bare comment
   (`CON-26`).** A builder wakes to iterate on its own PR from a formal
   `pull_request_review` (`changes_requested`, or a Copilot review) — an `issue_comment` on
   the PR is silently skipped by its wake guard (OBSERVE reads comments on the in-review
   *issue*, not the PR). So if you need the authoring agent to fix something, submit a
   `request_changes` review; a comment strands the finding. Comments are for notes the human
   reads, not work the builder must action.
   **Ichigo carve-out (`CON-38`).** Ichigo never casts `request_changes` on the maintainer's
   identity — doing so would manufacture their vote. Its always-available alternative is the
   non-vote `bankai:wake/iterate` label, which re-fires a stalled loop directly; this covers
   re-processing a finding an automated reviewer already delivered (even one riding an
   `APPROVE`/`COMMENT` verdict) too, because re-firing the loop to pick that finding up is
   itself a wake, not a new finding (`CON-26` clarification, `<reference-repo>#531`).
   **The carve-out is not a hole — a finding of Ichigo's *own* is filed, never voted and never
   left in a comment.** The label carries **no finding**, and a plain comment strands one (above),
   so the two do not add up to a delivery channel. When Ichigo holds a substantive finding a CI
   author must act on and **no reviewer has already delivered it**, the route canon already names
   is to **file it** — scope-routed per `CON-37`, linked from the PR in object notation — and
   **report the stall**: *"file the machinery defect — never substitute a vote"*, and *"a defect to
   file and a stall to report, not a process to follow"* (Ichigo's local agent definition), which is the
   same move `CON-26`'s `<reference-repo>#531` clarification requires of any agent that finds Ready blocked (it
   *"files the gap"* rather than closing it itself). A comment posted beside that issue is a note
   for the human to read, never the delivery. **Whether that cost is the right one for a one-line
   finding is an open `CON-{n}` question** —
   RR-IS-#761, Naruto's lane; until it is
   answered, the route above binds, and inventing a second channel to avoid it is `BC-6`
   (machinery resolving a spec question — RR-PR-#744
   was closed unmerged for exactly that).
7. **Close every inline review thread you act on — reply *and* resolve (`CON-16`).** When you
   address a reviewer's inline comment (Copilot, Bugbot, Sasuke, Tenma, Bisky), reply on its thread with
   the disposition — the fix-commit SHA, or a cited reason you're pushing back — **and mark the
   thread resolved**. A fix commit alone only makes it *outdated*, not *resolved*: an unanswered,
   still-open thread reads as ignored.
   **When the author resolves, and the one case it does not.** Resolve on a **fix**, and on a
   **pushback you are confident in** — that is the default and covers nearly every thread. Leave a
   thread open **only** when you want the reviewer's explicit confirmation before it counts as
   addressed, and then **say so in the reply, naming what you are asking it to confirm**: an
   open thread with no such request is not a hand-off, it is a dangling thread. That single case is
   the one the reviewer closes (below); everything else you close yourself. **Never leave a thread
   open silently**, and never leave one open because you are unsure who owns it — if no request is
   stated, it is yours.
   The party that acts resolves it (`CON-16` states that principle; what follows are its
   instances) — the authoring agent on fix/pushback (part of its ITERATE run); **the reviewer that
   raised the finding, on a thread of its own left open for its agreement**; the human/Ichigo when
   they verify a finding is a false positive. Never leave an inline thread dangling.
   **The reviewer's resolve — added because "the party that acts" was being read as author-or-human
   only. It ADDS a party; it removes none.** The author's path is **unchanged**: a fix, or a cited
   pushback, replied on-thread and resolved, is a complete disposition (`CON-16`) — and where the
   author has already closed the thread, there is nothing left for a reviewer to close. What had no
   owner is the thread the author deliberately leaves **open for the reviewer's agreement** — the
   narrow case named above: it pushed back and asked the reviewer to confirm. Nobody was named for
   that close, so it waited for the human. So: on its **next round** against the new head, the
   reviewer reads the author's replies, and each still-open thread **of its own** it now agrees
   with, it **closes there** — it replies with one line naming what it accepts, **and resolves the
   thread**. Bounded, so this never becomes a round satisfying itself: a reviewer resolves **only a thread it raised
   itself**, **only after** the author has replied, and **never** a finding it still holds — a
   reviewer that still disagrees says so and leaves the thread open. Resolving changes nothing
   about `CON-16`/`CON-32` — a round is addressed by the author's disposition, not by who clicked
   *resolve*. **Whoever acts first closes it; what must never happen is both waiting**, which is
   how this case reached the human — exactly the step their gate is not (`CON-42`(1): short of
   Ready, every gap is an agent's to self-heal).
   **Machinery flag (`CON-3`):** where a reviewer's token cannot call `resolveReviewThread`,
   wiring that is Kisuke's lane — never a reason for the thread to sit open.
8. **Drive your own PR fully green before calling it ready (`CON-32`).** Your PR is *ready* — for
   the human's review or Roy's merge — only when **every required check passes, every configured
   automated reviewer (Sasuke, Tenma, Bisky, Copilot, Bugbot where enabled) has posted a round against the
   _current head SHA_, every round is addressed (reply + resolve), and no thread is unresolved**.
   Green required checks alone is **not** ready. Verify each reviewer reviewed the *head*, not a
   superseded commit — a zero-unresolved count on a stale round is a false green. CI builders reach
   this via the `copilot-sweeper` / ITERATE backstop; **the local plane (Ichigo) has no sweeper —
   poll your own PR to green directly.** Never report, label, or hand off a PR as
   ready-to-merge / ready-for-review before it holds.
   **A readiness claim is the deterministic readiness gate's verdict, quoted, or it is not made
   (RR-IS-#681).** The paragraph above says what
   *ready* means; this says how you are permitted to find out. No agent — CI or local — and no
   session may describe a PR as ready, G2-ready, G4-ready or mergeable on any other basis: not a
   checks-page reading, not "I just fixed it", not the absence of a red mark, not "the reviewers
   approved", and above all not checks that have **not yet reported** — pending read as green is the
   specific error RR-IS-#681 records. Run
   the readiness gate (`pr_ready_gate.sh --verdict <PR>` in the reference implementation;
   `nen pr ready` on the successor planes — or the `pr-state <CODE>#<N>` skill, which is that call
   plus the conjunct-by-conjunct breakdown) and quote what it printed. **Where the gate cannot evaluate a PR,
   the report is `unevaluated` with the reason — never `ready`** (`RR-IS-#680`: absence is never a
   pass). The tool already existed and was skipped anyway, and three of four claims made that way
   were wrong; a deterministic authority an agent may skip is a suggestion, so this is the clause
   that makes skipping it indefensible rather than merely discouraged.
   **Count findings, not threads — see `CON-16` (canonical) / `CON-32`(e).** A reviewer finding can
   arrive with no thread object (Copilot's `<details>Suppressed comments (N)</details>` block, in the
   review **body** with nothing to resolve), invisible to every thread-count limb. Read the review
   **body** as well as its threads and disposition every finding in one stamped PR comment (fixed at
   `<sha>`, or refuted with the reason); a zero-unresolved count is **not** proof a round carried no
   findings. The full rule — the unit is the finding, not the thread — is `CON-16`.
