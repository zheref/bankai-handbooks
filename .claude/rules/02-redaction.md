# 02 — Redaction (the public-repository gate)

The policy is [`docs/PUBLIC-REDACTION.md`](../../docs/PUBLIC-REDACTION.md). This file is the
working checklist.

## Never

- Name a private repository — the frozen reference implementation, the scaffolding repository,
  any consuming product repository, the migration tracker. Not in prose, not in a path, not in a
  URL, not in a code comment, not in a commit message or PR body.
- Re-expand a placeholder. `<reference-repo>` stays `<reference-repo>` even when you know the name.
- Link an object id into a private repository. `RR-IS-#34` is plain text, never wrapped in a Markdown link.
- Put a real consumer's `canon-values` (targets, schemes, package roots, asset repos, timezones,
  maintainer login) into an example. Examples are `Acme`-family, `octocat`, `UTC`.

## Placeholders in use

| Placeholder | Meaning |
|---|---|
| `<reference-repo>` | the frozen reference implementation (the handbooks' origin) |
| `<scaffold-repo>` | the scaffolding repository |
| `<product-repo-A>` / `-B` / `-C` / `-D` | consuming products (iOS/macOS, Android, web, …) |
| `RR-` / `RS-` / `RA-` / `RB-` + `IS`/`PR` + `-#<n>` | object ids in those repositories, number kept |
| `<reference-repo>#<n>` | a bare tracker number the reference implementation cited as `#<n>` |
| `Acme`, `acme/acme-ios`, `acme/acme-assets`, `AcmeCore`, `AcmeUI`, `AcmeTests`, `Acme.xcodeproj`, `Acme/Application`, `com.acme.app` | the fictional illustrative product |

## Where the line is

- **Provenance and history sections** (a stack `rules/README.md` "Reconciliation decisions", the
  constitution's incident notes, `MIGRATION.md`) may say `<product-repo-A>` — that is the redacted
  record. **Rule text and example values** may not: a rule that needs a repo-specific fact has a
  `{{TOKEN}}`; a rule that leans on an incident keeps the fact in words and drops the id.
- Persona names, `bankai:` labels, rule ids, scenario ids, system names (Bankai, Akatsuki, Hatsu,
  Nen, UZF), version tags, dates and counts are **not** redacted.
- Ordinary sample names in code (`UserProfile`, `Endeavor`, `Now`, `ada@example.com`) are
  illustrative vocabulary and stay.

## The grep (run before every push; must print nothing)

```bash
grep -rnoE '\bbankai-[a-z]+' --exclude-dir=.git . | grep -vE 'bankai-(handbooks|machinery|quality|mode|session)'   # any other bankai-<x> is a repo name
grep -rnoE 'zheref/[A-Za-z0-9_.-]+' --exclude-dir=.git . | grep -vE 'zheref/(hatsu|nen|bankai-handbooks)\b'     # only the three public slugs
grep -rnoE 'github\.com/[^ )>]+' --exclude-dir=.git . | grep -vE 'github\.com/zheref/(hatsu|nen|bankai-handbooks)\b'
grep -rniE '<the product-family names from your private redaction list>' --exclude-dir=.git .
grep -rnoE '\[(RR|RS|RA|RB|RC|RD)-(IS|PR)-#[0-9]+\]\(' --exclude-dir=.git .   # linked ids: none
```

The patterns are **shape-based on purpose** — this file must not spell a private name to find one.
The product-family names live in the maintainer's private redaction list, never in this repository.

If a match is legitimate (this file, the policy's own explanation), say so in the PR. If you are
unsure whether something is a leak, **report it** in the PR and stop — never decide silently.
