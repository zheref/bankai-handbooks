# 04 — Commits and pull requests

## Commits

- **Conventional Commits.** Types in use: `feat`, `fix`, `docs`, `chore`, `refactor`. Scope is the
  family or area: `handbooks`, `constitution`, `swiftui`, `compose`, `react`, `machinery`,
  `redaction`, `migration`, `rules`. Subject ≤ 72 characters, imperative, no trailing period.
- **Body** explains *why* and names the rule ids and the `VERSION` class; not a restatement of the diff.
- **Trailer, always present on an agent-authored commit:** `Hatsu-Agent: <persona>` (locally —
  Kurapika for canon work) or `Akatsuki-Agent: <persona>` (CI plane). One trailer, the truthful one.
- **Forbidden trailers and lines:** `Co-Authored-By:` naming an AI assistant, `Generated-by`,
  `Generated-with`, `Claude-Session`, any model / surface / runtime / session attribution
  (`CON-51(c)`, `BC-7`). `Signed-off-by` is not used here either.
- Never `--no-verify`. Never force-push a branch someone else may have fetched. Never push `main`.

## Branches

`{model}/{persona}/{descriptor}` — the template `nen/workflow.json` → `branch.template` declares and
`nen/gates.json` → `delivery.head_ref_prefixes` admits (`fable/kurapika/ports-swiftui-compose`,
`opus/kurapika/12-ux-13-contrast`): `{model}` is the model alias the actor runs on, `{persona}` the
roster persona, `{descriptor}` a short kebab noun phrase, with the issue number first where there is
one. `main` is protected in intent even before a ruleset exists: only the human merges.

## Pull requests

- Assignee: the maintainer. Labels as the repository's taxonomy provides them.
- Body sections, in order: a one-paragraph delivery summary (what changes for a consumer), the rule
  ids touched, the `handbooks/VERSION` bump and its class, the consumer migration note (tokens
  added/renamed, mirrors that will regenerate), `Closes #<n>`, `## How to verify` (`CON-17`: the
  `scripts/canon_check.sh all` output — redaction, links and taxonomy in one — the manual
  private-family grep, the manifest rows to eyeball), and `## Agent
  attribution` (who acted, in which mode, with what evidence — no model or session lines).
- Open work as a PR whenever the repository already has content on `main`. Direct pushes to `main`
  are for the human only.
- A UI-screenshot section is never required here: this repository renders nothing.
