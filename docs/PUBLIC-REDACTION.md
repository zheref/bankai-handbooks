# Public redaction policy

This repository ends up **public**. Some of the canon it carries was authored against repositories
that are **not** public, and naming them here would leak their existence, their layout and their
issue numbers to readers who cannot open them.

**The rule: no private repository is named anywhere in this repository's content.** Every URL,
link, slug, path and object id that pointed into one is replaced with a stable placeholder, and
every link into one is unlinked. Facts stay — a rule that exists because of an incident still says
so — only the name the fact was recorded against is redacted. A placeholder is **never** re-expanded
into a real name: content that arrives redacted stays redacted.

The legend below is the one the local agent plane (Hatsu) publishes, extended with the two entries
this repository needed.

## The legend

| Placeholder | What it stands for |
|---|---|
| `<reference-repo>` | The frozen, private reference implementation the handbooks were migrated out of — the predecessor system whose CI plane Akatsuki and whose local plane Hatsu succeed. |
| `<scaffold-repo>` | The private scaffolding repository the estate generates consumers from, whose UZF architecture constitution was reconciled into `CONSTITUTION.md` § 6. |
| `<migration-tracker>`, "the migration tracker (private)" | The private repository where the Akatsuki migration and the governance rewrite are decided. Its issue numbers are dropped, not placeheld. |
| `<product-repo-A>` … `<product-repo-D>` | Consuming product repositories in the same estate, in no meaningful order. Private. `A` is an iOS/macOS product, `B` an Android product, `C` a web product, where the text needs to say which stack. |
| `RA`, `RB`, `RC`, `RD` | Placeholder **product codes** for `<product-repo-A>` … `<product-repo-D>`. |
| `RR-IS-#<n>` / `RR-PR-#<n>` | Issue / pull request `<n>` in `<reference-repo>`. The number is kept; the link is dropped. |
| `RS-IS-#<n>` / `RS-PR-#<n>` | Issue / pull request `<n>` in `<scaffold-repo>`. **Added by this repository** — the plane's legend had no object-id prefix for the scaffold repository. |
| `RA-IS-#<n>` / `RA-PR-#<n>`, `RB-…` | Issue / pull request `<n>` in `<product-repo-A>`, `<product-repo-B>`, … |
| `<reference-repo>#<n>` | A bare tracker number the reference implementation's own text cited as `#<n>`; the same object, without an issue/PR classification. |
| `Acme`, `acme/acme-ios`, `acme/acme-assets`, `AcmeCore`, `com.acme.app`, … | A **fictional** product used for every illustrative `{{TOKEN}}` value. The real values live in each consumer's private `canon-values` binding, never here. |

## The object-id rule, stated once

Object ids of **any** private repository take the placeholder-letter prefix, in both directions
(`-IS-` and `-PR-`). **The number is kept**: a bare number identifies nothing on its own, and the
canon's incident cross-references must stay checkable against themselves.

Bare `#<n>` inside `CONSTITUTION.md` are the reference implementation's internal cross-references
and stay as they are; its preamble says so. In the handbooks the same numbers are written
`<reference-repo>#<n>`.

## What is deliberately **not** redacted

- **`bankai:` label namespaces** and the invocation grammar (`<CODE>#<n>`, `<CODE>@<gate>`). They
  are taxonomy, not repository names.
- **Clause and rule ids** — `CON-{n}`, `UZF-{n}`, `SEC-{n}`, `UX-{n}`, `REL-{n}`, `QA-{n}`,
  `SW-{n}`, `KT-{n}`, `RC-{n}`, `BC-{n}`. They are this canon's own vocabulary.
- **Stack scenario ids** (`swiftui-tca-uzf-v2`, `compose-uzf-v2`, `react-uzf-v1`,
  `bankai-machinery`) and the **`BC-` prefix**, which is kept although the scenario it belongs to was
  renamed away from a repository's name.
- **System and plane names** — Bankai, Akatsuki (`Akatsuki-Agent:`), Hatsu (`Hatsu-Agent:`), Nen, UZF.
  They name systems, not repositories a reader could open.
- **Persona names** (Sasuke, Tenma, Naruto, Yamamoto, Kisuke, Ichigo, Kurapika, …). They are the
  roster vocabulary the constitution and handbooks are written in.
- **Public repositories** — `zheref/hatsu`, `zheref/nen`, and this repository.
- **Version tags, dates, counts, thresholds** and every recorded verdict. Facts stay; names go.
- **Ordinary example names** in code samples (`UserProfile`, `Now`, `Suggestions`, `Endeavor`,
  `ada@example.com`). They are illustrative vocabulary, not repository names, and some happen to be
  drawn from the reference products' domains.

## Audit procedure (run before any push)

1. The shape-based greps in `.claude/rules/02-redaction.md` must print nothing: any `bankai-<x>`
   other than `bankai-handbooks` / `bankai-machinery` / the two skill names, any owner slug or
   GitHub URL other than the three public repositories, and the product-family names
   kept in the maintainer's **private** redaction list (never spelled here).
2. Every `RR-`/`RS-`/`RA-`/`RB-` id is unlinked. Every `[…](https://github.com/…)` link points at a
   public repository.
3. Every `{{TOKEN}}` example value is fictional (`Acme`-family, `octocat`, `UTC`).
4. Anything you were unsure about is **reported**, never silently decided.

## Scope

Tree content and, once the repository is public, its issue and PR bodies. The history is fresh by
design (see [`../MIGRATION.md`](../MIGRATION.md)): nothing before the first commit exists here.
