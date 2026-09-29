# 03 — `{{TOKEN}}` placeholders

Stack rule files (`handbooks/stacks/<id>/rules/*.md`) are **stack canon**, not repo canon. Anything
that is true of one consumer and not of the stack — a target, a scheme, a module, a package root, a
path, a workflow file, an assets repo, a maintainer login, a device, a timezone — is a `{{TOKEN}}`.

## The schema is `rules/placeholders.md`

Each stack declares its tokens once, in a table: token, meaning, an **illustrative** example, and
(where two stacks share a token) the scope. A token used in any rule file of that stack **must**
appear there; the mirror generator fails closed on an undeclared or unbound token. Adding or
renaming a token is a G4 change here **and** a `canon-values` change in every consumer of that
stack before its next repin — say so in the PR's migration note.

## Binding happens in the consumer, never here

Each consumer binds values in its own `canon-values` file (Claude Code consumers keep it at
`.claude/canon-values.yml`; `nen scaffold init --canon-values-path` writes the template). Hatsu/Nen
substitute the bindings into the stack's `rules/` when rendering the per-surface mirror
(`nen canon mirror generate`) and verify them (`nen canon mirror check`). This repository holds
**no** bindings.

## The illustrative product is fictional: "Acme"

| Token | Illustrative value |
|---|---|
| `{{PRODUCT_REPO}}` | `acme/acme-ios` |
| `{{PROJECT_NAME}}` | `Acme` |
| `{{MAINTAINER}}` | `octocat` |
| `{{APP_TARGET_IOS}}`, `{{SCHEME}}` | `Acme` |
| `{{APP_TARGET_MACOS}}` | `Acme for Mac` |
| `{{CORE_FRAMEWORK}}`, `{{UI_MODULE}}`, `{{TEST_TARGET}}` | `AcmeCore`, `AcmeUI`, `AcmeTests` |
| `{{APP_SOURCE_ROOT}}`, `{{XCODEPROJ}}` | `Acme/Application`, `Acme.xcodeproj` |
| `{{APP_PACKAGE}}` (compose) | `com.acme.app` |
| `{{ASSETS_REPO}}`, `{{ASSETS_LAYOUT}}` | `acme/acme-assets`, `Acme/pr-<n>/<scene>.png` |
| `{{SNAPSHOT_TZ}}` | `UTC` |
| `{{BUILD_LOG}}` | `/tmp/acme-build.log` |

Never replace an `Acme` value with a real consumer's value "because it is more realistic" — that is
the bug this convention exists to prevent, independent of publication.

## What is deliberately **not** a token

Stack-standard libraries and framework API symbols (TCA, `@DependencyClient`, Hilt's annotations,
Redux Toolkit, Tamagui), the UZF artifact suffixes, and ordinary sample names in code
(`UserProfile`, `Endeavor`, `Now`). They are the stack, not the repo.
