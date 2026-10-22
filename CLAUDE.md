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
- This repository has no build, no general test suite (the one executable, `scripts/canon_check.sh`, has
  its `--self-test` on the focused `canon-check-guard` lane) and no generated mirror of its own. "Green" here means:
  `nen shu lint --repo .` is clean — `scripts/canon_check.sh all`: the redaction audit empty, no link
  dangling, `nen schema check` all `ok` — and `VERSION` matches the change class. That one check is
  what `nen/workflow.json` → `iteration.checks` declares, so every Hatsu turn (`breath`, `rasengan`,
  `kokusen`) runs it and CI (`canon.yml`) runs the same script per job.
- **The spec authoring handbook and the capture reader appendices** (`handbooks/VERSION` `v0.8`, MINOR). `handbooks/spec/authoring.md` is new and carries the `SP-{n}` family, `SP-1`–`SP-13`, for writing and reviewing a product family's spec folders (zheref/hatsu ROSTER HR-6; the capture skill is `dowsing-chain`, HR-12). The rules cover: every requirement line ends in a citation at a commit or one marker; three confidence tiers, with an inferred row never a MUST or a success criterion; source text only inside fenced `source-data` blocks (`SEC-15`); no framework vocabulary in `spec.md` or `data-model.md`; one parity handling per requirement and member (mirror, map, drop with note, target-only addition), with absent never read as not needed; the spec changes first, convergence appends, ids never renumber and a reversal is a supersedes line; five clarification questions a round and three rounds a run, answers kept verbatim under a dated session; checklists ticked by the reviewer, never the author. An informative table names the 14 capture row kinds. `QA-26` is new: completeness is `covered/total` per kind, and "complete" never appears without the numbers. The SwiftUI, Compose and React stack handbooks each gain an *Appendix — capture reader* mapping file suffix → UZF concept → row kind, with no new stack id. No rule id was renumbered and no token was added.
