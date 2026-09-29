<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 14 — GitHub Version Control

How issues and pull requests are wired on GitHub. These rules apply **every time an
issue or PR is created or updated** — by a human or by Claude Code. The goal:
relationships, project membership, ownership, and PR↔issue links are expressed
through GitHub's **native mechanisms**, not just prose, so the graph (Projects,
Development links, sub-issues) is always accurate and automation (auto-close, roadmap
views) works.

Much of this is already canon — the constitution and the shared agent conventions
(`_conventions.md`) own the general form. This file keeps only the **SwiftUI-repo-specific operational
bits** and cites the canon for the rest; it never restates constitution text.

## Repo-specific placeholders

| Token | Illustrative example |
| --- | --- |
| `{{MAINTAINER}}` | `octocat` |
| `{{GH_PROJECT}}` | the repo's active GitHub Project |
| `{{ASSETS_REPO}}` | `acme/acme-assets` |
| `{{SCREENSHOTS_SCRIPT}}` | `ci_scripts/pr_screenshots.sh` |
| `{{BANKAI_WORKFLOW}}` | `.github/workflows/bankai.yml` |
| `{{DBMIGRATE_WORKFLOW}}` | `.github/workflows/db-migrate.yml` |
| `{{COPILOT_REVIEWER}}` | `copilot-pull-request-reviewer[bot]` |

## The rules

On **every** issue/PR create or update, ensure all of the following:

1. **Assignee — never leave either unassigned.** `_conventions.md` (human-glance
   fields) makes every agent-opened issue/PR assigned to the human maintainer. This
   repo refines *which* identity for human/Claude-Code-authored work:
   - **Pull requests → always the maintainer, fixed: `--assignee {{MAINTAINER}}`.**
     A PR is owned by the maintainer regardless of who authored it (only the
     maintainer merges). Do **not** use `@me` for PRs — it would credit whatever
     account opened the PR.
   - **Issues → ensure `@me` (the *authenticated* user) is among the assignees.**
     Whoever picks up or contributes to an issue is credited on it. This is
     **additive**: use `--add-assignee @me` so an already-assigned contributor is
     **not** removed — multiple assignees (co-contributors) are fine. The rule is
     "@me is assigned," not "@me is the *only* assignee." (Bankai agent-tier work
     follows `_conventions.md` — assign the human maintainer, not `@me`.)
2. **Relationships between issues — native.** Connect related issues with GitHub's
   built-in relationships, not only a "depends on #N" line:
   - Epic ↔ children: add children as **sub-issues** of the epic.
   - Ordering/dependencies: use **"blocked by" / "blocks"** relationships.
   The prose may stay for readability, but it is *in addition to* the native link,
   never a substitute.
3. **Always link PRs to their issue(s) natively — never via comments alone.** Every
   PR that addresses an issue carries a **closing keyword in the PR body**
   (`Closes #N` / `Fixes #N` / `Resolves #N`), one per issue, so GitHub creates the
   **Development** link and auto-closes on merge. A comment or bare `#N` mention does
   **not** create that link — the keyword does. (For a PR that relates to but should
   not auto-close an issue, still link it natively via the Development sidebar.)
4. **Associate the corresponding Project.** Add the issue/PR to `{{GH_PROJECT}}` so
   it shows on the board/roadmap.
5. **Labels as needed.** Apply the right labels (type + area, plus the `bankai:*` set
   per `_conventions.md`). Create a missing label first; don't error if it already
   exists.
6. **Keep the PR checklist current — on post AND on every update.** Whenever a PR is
   opened **or** updated (new commits, scope change), walk the session-completion
   checklist in the PR body ([Rule 12](12-session-completion-checklist.md) / UZF-23)
   and **check or uncheck** each box to reflect current reality. A pushed change that
   invalidates a ticked item un-ticks it; a newly-satisfied item gets ticked. Never
   left stale. (Opening a PR with `gh pr create --body` bypasses the template, so
   include the checklist in the body yourself.)
7. **After posting or pushing to a PR, monitor its Copilot review and CI to
   resolution — don't post-and-forget.** This is the repo-level expression of
   **CON-18** (self-healing below the gates). Every `gh pr create` and every push
   kicks off (a) the automatic Copilot PR review and (b) the CI workflows
   (Architecture guardrails + tests, per [Rule 13](13-build-execution.md) /
   [Rule 10](10-migration.md); the real build gate is **CON-19**). Wait for both and
   act on the results in the same session:
   - **CI:** poll until every check is conclusive. If any **fails**, read its log,
     fix the cause (or push back if it's a flake/infra), and push — which restarts
     this loop.
   - **Copilot review:** once it posts, read every inline comment and **either
     address it** (fix + reply pointing at the commit) **or push back** with a
     concrete reason. Never leave a Copilot comment silently unresolved.
   - A PR is only "done" for the session when CI is green **and** every Copilot
     comment is addressed or rebutted. Re-tick the Rule 6 checklist afterward.
8. **UI PRs carry snapshot screenshots in the description (UZF-26 / SW-18).** Any PR
   that adds or changes a TCA-free `<Name>View` renderer (structurally: no
   `ComposableArchitecture` import, wherever it lives — SW-2) or a reusable component
   includes a `## Screenshots` section embedding the recorded snapshot PNGs
   themselves, one per user-visible state, mirroring the `#Preview`/snapshot set 1:1
   ([Rule 16](16-ui-screenshots.md)). This repo is **private**, so its own `raw` URLs
   404 in GitHub's image proxy; the PNGs are mirrored to the public `{{ASSETS_REPO}}`
   host and referenced via SHA-pinned `raw` URLs. `{{SCREENSHOTS_SCRIPT}}` mirrors
   them and prints the ready-to-paste block. Logic-only PRs are exempt — state it in
   the body.

## How (gh snippets)

**Create an issue** (assignee + labels + project in one go):

```bash
gh issue create \
  --title "…" --body "…" \
  --assignee @me \
  --label "area-label,type-label" \
  --project "{{GH_PROJECT}}"
```

**Update an existing issue** (`--add-assignee` is additive — won't drop
co-contributors):

```bash
gh issue edit <ISSUE_NUMBER> --add-assignee @me --add-label "…" --add-project "{{GH_PROJECT}}"
```

**Sub-issue relationship (epic → child)** — gh has no first-class flag yet, so use
the REST API. The `sub_issue_id` is the child issue's **integer database `id`** (what
`--jq .id` returns) — **not** the issue *number* and not the GraphQL `node_id`
string. `gh api` substitutes `{owner}`/`{repo}` from the current repo. (Placeholders
are plain numbers — `42`, not `#42`; the `#` is *not* part of the API path.)

```bash
child_id=$(gh api repos/{owner}/{repo}/issues/<CHILD_NUMBER> --jq .id)
gh api --method POST repos/{owner}/{repo}/issues/<EPIC_NUMBER>/sub_issues -F sub_issue_id="$child_id"
```

**"Blocked by" / "blocks"** relationships are set in the issue UI (Relationships
panel) when the CLI/API can't; record them there, not only as prose.

**Open a PR** that closes its issue — assigned to the maintainer (**fixed
`{{MAINTAINER}}`, not `@me`**) and on the project:

```bash
gh pr create --title "…" \
  --body "$(printf 'Closes #<ISSUE_NUMBER>\n\n…summary…')" \
  --assignee {{MAINTAINER}} \
  --project "{{GH_PROJECT}}"
```

The body **must** contain the `Closes #<ISSUE_NUMBER>` keyword — that is the native
link. (Here the `#` **is** literal — closing keywords are written `Closes #42`,
unlike the API paths above.) After opening, and again after **every** push, reconcile
the checklist boxes (rule 6) — `gh pr edit <N> --body "…"` to rewrite.

**Monitor CI + Copilot after posting/pushing** (rule 7):

```bash
# 1. Watch CI until every check is conclusive (exits non-zero on failure).
gh pr checks <N> --watch

# 2. Read the Copilot review summary + the per-line review comments.
gh pr view <N> --json reviews \
  --jq '.reviews[] | select(.author.login=="{{COPILOT_REVIEWER}}") | .body'
gh api repos/{owner}/{repo}/pulls/<N>/comments \
  --jq '.[] | "\(.id)\t\(.path):\(.line // .original_line)\n\(.body)\n---"'

# 3. Reply to each inline comment (address with a commit ref, or push back).
gh api repos/{owner}/{repo}/pulls/<N>/comments/<COMMENT_ID>/replies -f body="…"
```

If a check fails, open its job log (`gh run view <run-id> --log-failed`), fix or
rebut, and push — which restarts the loop.

## Scope / auth note

Adding items to a Project (and listing projects) requires the `project` (and
`read:project`) token scopes. If `gh project …` or `--project` fails with a
missing-scope error, run `gh auth refresh -s project,read:project` (maintainer
action), or add the item from the issue/PR's **Projects** sidebar. When Claude Code
can't complete the Project association due to missing scope, it **says so explicitly**
and asks the maintainer to finish that one step — it does not silently skip it.

## Branching model & infra/process-dependency propagation

This repo runs an **epic integration-branch gitflow** (bankai delivery mode), so a
change lands through three branch levels, not one:

```
feature branch  ->  integration/epic-<n>  ->  main (trunk)
(alphonse/… ,        (per-epic staging;         (default branch)
 edward/… ,           Roy merges children       human merges the single
 naruto/… ,           here at G2-internal)       integration -> main PR at G2)
 roy/… …)
```

- A **feature PR** targets its epic's `integration/epic-<n>` branch (base read from
  the parent epic's delivery-mode label), **never `main` directly**. Example: a feature PR
  with head `<builder>/<issue>-<slug>` and base `integration/epic-<n>`.
- `integration/epic-<n>` targets **`main`**; the human merges that one final PR.
- Live integration branches today: `git ls-remote --heads origin 'integration/*'`.

### Propagating an infra/process-dependency bump — trunk-first, then cascade down

This is the concrete, repo-specific implementation of **`CON-21`**
(trunk-first → cascade-down-integration → inherit-by-rebase). The canon states the
principle; this section states how it plays out here — **do not restate it, cite it.**

An **infra/process dependency** here means anything CI resolves **per-branch**: the
pinned CI-plane reusable-workflow tag on every `uses:` line in [`{{BANKAI_WORKFLOW}}`]({{BANKAI_WORKFLOW}})
and [`{{DBMIGRATE_WORKFLOW}}`]({{DBMIGRATE_WORKFLOW}}), a tool/CLI/SDK/runner version,
or a shared config/secret contract. Because GitHub reads a PR's workflows and pins
from its **base branch**, **repinning `main` alone does not reach an in-flight epic**
— a PR based on `integration/epic-<n>` keeps running whatever that branch pins until
the bump physically arrives there. A `main`-only repin **silently strands every open
epic** on the old (often broken) pin.

The required cascade for ANY such bump:

1. **Trunk first.** Land the bump on **`main`** — one PR, human-merged (G2). (Worked
   example: a `{{DBMIGRATE_WORKFLOW}}` repin that fixed a preview-branch database auth
   failure landed on `main` as its own PR.)
2. **Cascade into every live integration branch.** Sync **`main` into each live
   `integration/epic-<n>`** so each epic inherits the new pin — fetch first so both
   sides are current:

   ```bash
   git fetch origin
   git checkout integration/epic-<n>
   git merge origin/main          # bring main's new pin down into the epic branch
   git push
   ```

   In bankai mode this is exactly the `main → integration/*` sync Roy already performs
   at epic-open and after each child merge (`CON-19`); a conflict is
   resolved/escalated, never force-pushed.
3. **Feature branches inherit by rebase — never hand-pinned.** In-flight feature PRs
   pick the bump up by merging/rebasing their **now-synced `integration/epic-<n>`
   base** (each builder's DIRTY-resolve duty). **Do not edit the pin on an individual
   feature branch;** the base carries it so the whole epic stays on one coherent pin.

A pin/infra bump is **not "done"** ([Rule 12](12-session-completion-checklist.md) /
`UZF-23`) until **no live branch still resolves the pre-bump version** — i.e. every
live `integration/epic-<n>` has been synced — or the session notes an explicit,
reasoned deferral (e.g. "no integration branch is live"). Verify with:

```bash
for b in $(git ls-remote --heads origin 'integration/*' | sed 's#.*refs/heads/##'); do
  echo "== $b =="; git show origin/$b:{{BANKAI_WORKFLOW}} | grep -m1 'roy-build.yml@'
  git show origin/$b:{{DBMIGRATE_WORKFLOW}} | grep -m1 'db-migrate.yml@'
done
```

Every live branch should report the **same** (latest) tag as `main`. A branch still
on an older tag is an incomplete cascade — finish it (step 2) before calling the bump
done.

> **Worked example — completed.** When a `{{DBMIGRATE_WORKFLOW}}` fix shipped as a new
> CI-plane tag, the cascade ran end to end: `main` was repinned to the new tag in its own
> PR, then `main` was synced down into **both** live integration branches, so neither
> stayed on the broken tag. All three branch levels ended on the same tag: a completed
> cascade, not work still owed. (The cross-consumer axis — which repos get
> the repin PR at all — is `CON-22`; the intra-repo cascade here is `CON-21`.)

## Relationship to other rules

- The connecting **comments** Claude posts remain useful human-readable context, but
  they are *additive* — the native links above are the source of truth for the graph.
- Change provenance: new file content must arrive as a **real pushed git commit**,
  never fabricated via the REST Contents/Git-Data API (**CON-20**) — a detached head
  is how a PR silently ships the wrong commit. Merges, labels, review requests, and PR
  open/close/comment via the API are fine (they don't author new bytes).
- PR content/quality rules live in [12-session-completion-checklist.md](12-session-completion-checklist.md)
  (`UZF-23`); UI **screenshots** in [16-ui-screenshots.md](16-ui-screenshots.md)
  (`UZF-26` / `SW-18`); the human `## How to verify` plan is required on every
  human-gated PR (**CON-17** / `_conventions.md`); commit-message conventions live in
  `.claude/CLAUDE.md` / `_conventions.md`.
- The **branching model & propagation** section is this repo's concrete
  implementation of **`CON-21`**, completion-gated by `UZF-23`. Database-migration
  pins specifically also interact with `UZF-25` (DB migrations are repo-canon,
  idempotent, applied by the `db-migrate` CI pipeline — never by an agent in-session).
