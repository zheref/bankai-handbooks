# 01 — Authoring canon in this repository

## The lane

Every file here is canon. A change is a **canon-lane PR** (Kurapika's Conjurer mode locally,
`Akatsuki-Agent` on the CI plane) that **the human merges at G4** (`CON-7`, `CON-15`). No agent
merges, pushes `main`, or edits a rule "in passing" from another repository.

## Adding or changing a rule

1. **Find the family.** `CON-` (constitution), `UZF-` (`handbooks/uzf-core.md`), `SEC-`, `UX-`,
   `REL-`, `QA-` (the general handbooks), or one stack's `SW-` / `KT-` / `RC-` / `BC-`
   (`handbooks/stacks/<id>/architecture.md`, expanded operationally in `rules/`).
2. **Take the next number.** Numbers are append-only and stable. Never renumber or re-purpose;
   mark a superseded rule `RETIRED` in place. A stack rule names the `UZF-{n}` parent it refines
   and never contradicts it — a real conflict is a `bankai:handbook-question`.
3. **Write it in the house shape.** One normative statement, the concrete threshold or check
   (with its measurement method where one exists), the anti-pattern it forbids, the rationale, a
   public reference (CWE / OWASP / WCAG / HIG / Material) when one maps. Keep it citable.
4. **Wire the manifests.** A new handbook or scenario → a row in `handbooks/INDEX.md` and
   `handbooks/stack-matrix.md`; a new stack → `stacks/<id>/README.md`, `architecture.md`,
   `rules/`, `rules/placeholders.md`. `handbooks/README.md`'s family table when the enforcer or
   scope statement changes.
5. **Bump `handbooks/VERSION`.** New rule / clarified wording → **MINOR**. Changed meaning,
   removal, prefix restructure → **MAJOR** (pre-1.0 carve-out: a breaking restructure may ride a
   MINOR while the taxonomy stabilises — say so in the PR).
6. **Note the consumer migration** in the PR: which stacks are affected, whether a token was
   added or renamed (every consumer's `canon-values` must bind it before its next repin), and
   whether a mirror regeneration changes files a consumer has open.
7. **Never name a product repo.** A rule that needs a repo-specific value uses a `{{TOKEN}}`
   (see `03-tokens.md`); an example value is fictional.

## The constitution specifically

`CONSTITUTION.md` carries the reference implementation's governance as written (its preamble says
so). Change `CON-13` and § 6 (`CON-51`) here freely under G4; treat every other clause as text whose
rewrite is decided elsewhere first — append (`CON-52`…), do not rewrite, unless the PR is that
governance rewrite landing.

## Checks a canon PR runs (there is no build)

```bash
# 1. redaction — each line must print nothing (shape-based; see 02-redaction.md)
grep -rnoE '\bbankai-[a-z]+' --exclude-dir=.git . | grep -vE 'bankai-(handbooks|machinery|quality|mode)'
grep -rnoE 'zheref/[A-Za-z0-9_.-]+' --exclude-dir=.git . | grep -vE 'zheref/(hatsu|nen|bankai-handbooks)\b'
# 2. dangling relative links — must print "0 dangling"
python3 - <<'PY'
import re, pathlib
bad=set()
for p in pathlib.Path('.').rglob('*.md'):
    if '.git' in p.parts: continue
    for m in re.finditer(r'\]\(([^)#\s]+)(#[^)]*)?\)', p.read_text(encoding='utf-8')):
        h=m.group(1)
        if h.startswith(('http://','https://','mailto:')) or '{{' in h: continue
        if not (p.parent/h).resolve().exists(): bad.add((str(p),h))
print(*sorted(bad), sep='\n'); print(len(bad),'dangling')
PY
# 3. every {{TOKEN}} used in a stack's rules is declared in its placeholders.md
for s in handbooks/stacks/*/; do
  used=$(grep -rhoE '\{\{[A-Z_]+\}\}' "$s/rules" 2>/dev/null | sort -u | grep -v '{{TOKEN}}')
  for t in $used; do grep -q -- "$t" "$s/rules/placeholders.md" 2>/dev/null || echo "UNDECLARED $s $t"; done
done
# 4. generated-mirror marker on every stack rule file
grep -L 'Canonical source: zheref/bankai-handbooks' handbooks/stacks/*/rules/*.md
```

Paste the outputs into the PR's `## How to verify`.
