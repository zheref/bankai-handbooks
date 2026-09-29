# bankai-handbooks — agent instructions

You are working in **`zheref/bankai-handbooks`**, the **single canonical source** of the Bankai
handbooks: the governance constitution (`CON-{n}`), the always-load handbooks (`UZF-`, `SEC-`,
`UX-`, `REL-`, `QA-`) and the four stack handbooks (`SW-`, `KT-`, `RC-`, `BC-`). Nothing here is
product code. Everything here is **canon** that other repositories mirror (`CON-13`).

Depth lives in [`.claude/rules/`](.claude/rules/); this file is the contract.

## 1. What this repository is — and is not

| Is | Is not |
|---|---|
| The one place a rule is authored, numbered and versioned | A product repo — it has no `canon-values`, no mirror of its own |
| The source every consumer's per-surface mirror is rendered from, at a **tag** | The sync machinery — that is Hatsu/Nen (`nen canon …`); do not build it here |
| Stack canon, tokenised with `{{TOKEN}}` | Repo canon — a handbook that names a specific product repo, target, scheme or path is a bug |
| Public by design (redacted) | A place where a private repository may be named — ever |

Layout: [`handbooks/INDEX.md`](handbooks/INDEX.md) (the manifest), [`handbooks/README.md`](handbooks/README.md)
(the set, versioning, how canon reaches a consumer), [`handbooks/stack-matrix.md`](handbooks/stack-matrix.md)
(scenario registry), `handbooks/<general>.md`, `handbooks/stacks/<scenario>/{README,architecture}.md`
+ `rules/`, [`CONSTITUTION.md`](CONSTITUTION.md), [`CONVENTIONS.md`](CONVENTIONS.md) (the shared
agent conventions — output header, stamp, verdict line, object notation, gates, discipline),
[`MIGRATION.md`](MIGRATION.md), [`LICENSE`](LICENSE) (MIT),
[`docs/PUBLIC-REDACTION.md`](docs/PUBLIC-REDACTION.md).

## 2. Rules of engagement

1. **Every change is a PR the human merges (G4, `CON-7`).** Never push to `main`. Never merge.
2. **Rule ids are append-only and stable.** Never renumber, re-purpose or delete a number; a
   retired rule is marked `RETIRED` in place. A new rule takes the next number in its family.
3. **A rule's meaning changes → MAJOR; a new rule or a wording clarification → MINOR.** Bump
   [`handbooks/VERSION`](handbooks/VERSION) in the same PR (pre-1.0 carve-out in `handbooks/README.md`).
4. **Register what you add.** A new handbook or scenario is a row in `INDEX.md` and
   `stack-matrix.md` and, for a stack, a `stacks/<id>/` folder with `README.md`, `architecture.md`,
   `rules/` and `rules/placeholders.md`. Note the migration for consumers in the PR.
5. **Stack rule files are product-agnostic.** Anything repo-specific is a `{{TOKEN}}` declared in
   that stack's `rules/placeholders.md`. Example values are fictional (`Acme`, `octocat`, `UTC`).
   A token used in a rule file and missing from `placeholders.md` is a bug.
6. **A stack rule refines its `UZF-{n}` parent and names it; it never contradicts it.** A genuine
   conflict is a `bankai:handbook-question`, not an edit that picks a side silently.
7. **The mirror doctrine is `CON-13` — keep it, do not weaken it.** Consumers carry generated,
   pinned mirrors in **every** agent surface's rules location (Claude Code, Codex, Cursor,
   Antigravity, …). Write doctrine that accommodates any surface; never assume one.
8. **The `BC-` prefix stays** even though its scenario is `bankai-machinery`. Say so wherever the
   rename could confuse a reader.
9. **Redaction is a hard gate ([`docs/PUBLIC-REDACTION.md`](docs/PUBLIC-REDACTION.md)).** No private
   repository is named; placeholders are never re-expanded; object ids keep their number and lose
   their link. Run the audit grep before every push. Report what you are unsure about.
10. **Generated-mirror headers.** Every `stacks/*/rules/*.md` starts with the
    `<!-- Canonical source: zheref/bankai-handbooks … -->` marker line. Keep it; consumers' checks
    key on it.
11. **Docs describe behaviour, not implementation** (`UZF-21` applies to feature specs; this repo's
    own prose names files only when the file is the subject).
12. **Never edit a persona's plane or gate semantics** (`CON-1`…`CON-50`) as a side effect. The
    governance rewrite for the successor planes is decided elsewhere and lands here by G4 PR.

## 3. Commits and pull requests

- **Conventional Commits.** `feat(handbooks): …`, `fix(swiftui): …`, `docs(constitution): …`,
  `chore(migration): …`. Subject ≤ 72 chars; body says *why*.
- **Trailer:** every agent-authored commit ends with `Hatsu-Agent: <persona>` (this repository's
  local plane is Kurapika). On the CI plane the trailer is `Akatsuki-Agent: <persona>`.
- **No AI attribution of any kind** — no `Co-Authored-By:` naming an assistant, no model, surface,
  runtime, session or "generated with" line, in commits or PR bodies (`CON-51(c)`, `BC-7`).
- **PR body:** what changed and why, the rule ids touched, the `VERSION` bump and its class
  (MAJOR/MINOR), the consumer migration note, `Closes #<n>` for its issue, and a `## How to verify`
  section (`CON-17`) — for canon that is the file-level review: the diff, the INDEX/matrix rows,
  the redaction grep output.
- Never `--no-verify`. Never force-push a shared branch.

## 4. Checklist before you say "done"

- [ ] Rule ids untouched or appended; `RETIRED` used instead of deletion.
- [ ] `handbooks/VERSION` bumped with the right class; the bump is explained in the PR.
- [ ] `INDEX.md` / `stack-matrix.md` / stack `README.md` rows agree with the files on disk.
- [ ] Every `{{TOKEN}}` used is declared; every example value is fictional.
- [ ] Redaction grep is clean; nothing private is named; nothing placeheld was re-expanded.
- [ ] No dangling relative link (`python3 - <<'PY'` link check in `.claude/rules/01-canon-authoring.md`).
- [ ] `MIGRATION.md` updated only if provenance changed (it is a record, not a changelog).

## 5. Where the depth lives

| Concern | File |
|---|---|
| Adding or changing a rule, versioning, INDEX wiring, link check | [`.claude/rules/01-canon-authoring.md`](.claude/rules/01-canon-authoring.md) |
| Redaction legend and audit | [`.claude/rules/02-redaction.md`](.claude/rules/02-redaction.md) |
| `{{TOKEN}}` convention, `placeholders.md` schema, the Acme convention | [`.claude/rules/03-tokens.md`](.claude/rules/03-tokens.md) |
| Commit and PR conventions | [`.claude/rules/04-commits-and-prs.md`](.claude/rules/04-commits-and-prs.md) |
| How canon reaches a consumer (the `CON-13` mechanics) | [`handbooks/README.md`](handbooks/README.md#how-canon-reaches-a-consumer-con-13) |
| Provenance of everything here | [`MIGRATION.md`](MIGRATION.md) |
