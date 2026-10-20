@AGENTS.md

## Claude Code specifics

- Claude Code auto-loads this file and every file under `.claude/rules/`; `AGENTS.md` above is
  the authored contract for every surface, imported here so it is read once and never twice.
- Prefer `Read`/`Grep` over shell for inspecting canon; prefer exact-match `Edit` for rule text so
  a diff stays reviewable. Never rewrite a whole handbook file when one clause changed.
- When the task is canon or governance authoring, the working mode is Kurapika's **Conjurer**
  (`hatsu:kurapika`); the `Hatsu-Agent: kurapika` trailer follows from that.
- Before any push: `nen shu lint --repo .` (`scripts/canon_check.sh all`: the redaction audit of
  `.claude/rules/02-redaction.md`, the link check of `.claude/rules/01-canon-authoring.md` and
  `nen schema check`, in one script) plus the manual private-family grep. Paste the output into the
  PR's `## How to verify`.
- This repository has no build, no tests and no generated mirror of its own. "Green" here means:
  `nen shu lint --repo .` is clean — `scripts/canon_check.sh all`: the redaction audit empty, no link
  dangling, `nen schema check` all `ok` — and `VERSION` matches the change class. That one check is
  what `nen/workflow.json` → `iteration.checks` declares, so every Hatsu turn (`breath`, `rasengan`,
  `kokusen`) runs it and CI (`canon.yml`) runs the same script per job.
