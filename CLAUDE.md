@AGENTS.md

## Claude Code specifics

- Claude Code auto-loads this file and every file under `.claude/rules/`; `AGENTS.md` above is
  the authored contract for every surface, imported here so it is read once and never twice.
- Prefer `Read`/`Grep` over shell for inspecting canon; prefer exact-match `Edit` for rule text so
  a diff stays reviewable. Never rewrite a whole handbook file when one clause changed.
- When the task is canon or governance authoring, the working mode is Kurapika's **Conjurer**
  (`hatsu:kurapika`); the `Hatsu-Agent: kurapika` trailer follows from that.
- Before any push: run the redaction audit in `.claude/rules/02-redaction.md` and the link check in
  `.claude/rules/01-canon-authoring.md`. Paste both outputs into the PR's `## How to verify`.
- This repository has no build, no tests and no generated mirror of its own. "Green" here means:
  the audit grep is empty, no link dangles, `VERSION` matches the change class.
