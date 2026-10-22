#!/usr/bin/env bash
# canon_check.sh — the mechanical verification of a public canon repository.
#
# There is no build here: the product is prose. What can go silently wrong is
# (1) a private name reaching the public tree, (2) a relative link that does not
# resolve, and (3) a nen/ declaration that does not parse. This script is the
# `lint` verb of the `canon` lane (nen/contract.json), the one iteration check
# nen/workflow.json declares, and the body of every job in
# .github/workflows/canon.yml -- one implementation, run locally by nen shu lint
# and in CI per job.
#
# USAGE
#   scripts/canon_check.sh [all | redaction | links | taxonomy]   (default: all)
#   scripts/canon_check.sh --self-test
#
# WHAT IS SCANNED: the COMMITTABLE set, `git ls-files --cached --others
# --exclude-standard` -- every tracked file plus every untracked file .gitignore
# does not exclude. So a draft not yet added is scanned, a generated tree
# (.nen/, Reports/, .claude/worktrees/) is not, and a file forced past
# .gitignore with `git add -f` is scanned wherever it sits: there is no
# directory-name exclusion to hide in. The local run (drafts included) scans a
# superset of CI's tracked set, so a local pass implies the CI pass. A relative
# link resolves only against that set: a target that exists on this machine
# but is ignored or untracked is dangling for every other checkout.
#
# HOW A MATCH IS JUDGED. Every detector prints `path:line:match` (grep -o); the
# allow-list is applied to the MATCH FIELD ALONE and anchored to the whole slug,
# so an admitted slug followed by more slug characters is not admitted, and a
# path or URL fragment that merely contains an admitted token hides nothing.
# grep runs with -a: a binary file is scanned as text rather than reported on
# stderr and skipped. A grep exit of 2 (a file it could not read) is itself a
# finding: an unread file is not a clean one.
#
# EXIT  0 every selected check clean · 1 a finding, printed · 2 usage, or nen
# absent for `taxonomy` with no finding (a finding always outranks the missing
# tool). A finding is printed as a GitHub Actions annotation when GITHUB_ACTIONS
# is set and as a plain line otherwise.
#
# The redaction patterns are SHAPE-based on purpose: this repository must never
# spell a private name in order to find one (docs/PUBLIC-REDACTION.md). The one
# github.com URL admitted outside the three public repositories is the fictional
# fixture the rendered scripts/release-publish.sh carries in a comment (the
# legend's Acme family, owner `acme`, repository `widget`) -- that exact URL and
# nothing wider.
set -uo pipefail

usage() { echo "usage: scripts/canon_check.sh [all | redaction | links | taxonomy] | --self-test" >&2; exit 2; }
[ "$#" -le 1 ] || usage
what="${1:-all}"

if [ "$what" = "--self-test" ]; then
  SELF_TEST=1
else
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  cd "$here" || exit 2
fi
fail=0
tool_missing=0

say() { # level, message
  if [ -n "${GITHUB_ACTIONS:-}" ]; then printf '::%s::%s\n' "$1" "$2"; else printf '%s: %s\n' "$1" "$2"; fi
}

load_files() {
  # The committable set. A tracked file deleted without `git rm` is still listed
  # and would read as unreadable; it is skipped here and named once, since a
  # missing file carries nothing to leak.
  FILES=()
  while IFS= read -r -d '' f; do
    if [ -e "$f" ]; then FILES+=("$f"); else say notice "skipped: $f is tracked but absent from the working copy (git rm it)"; fi
  done < <(git ls-files -z --cached --others --exclude-standard)
}

scan() { # pattern, grep flags (-i or empty) -> "path<TAB>line:match" lines; grep's own exit code (1 = no match)
  # --null ends the path with NUL (the long spelling: BSD grep's -Z means
  # decompress), so a path that itself carries ':' cannot forge the line-number
  # or match field; the NUL becomes a TAB for the text tools after it.
  # -i where the caller says so: a host or an owner is case-insensitive on GitHub.
  [ "${#FILES[@]}" -gt 0 ] || return 1
  grep -naoHE --null ${2:-} "$1" -- "${FILES[@]}" | tr '\0' '\t'
  return "${PIPESTATUS[0]}"
}

check() { # title, detector (ERE), allow-list (ERE over the lower-cased match field, whole-slug anchored; empty = admit nothing), grep flags
  local out rc
  out=$(scan "$2" "${4:-}"); rc=$?
  if [ "$rc" -ge 2 ]; then
    say error "a file could not be read (grep exited $rc while scanning for: $1) -- an unread file is not a clean one; the matches in the readable files follow"
    fail=1
  fi
  if [ -n "$3" ]; then
    out=$(printf '%s\n' "$out" | awk -F'\t' -v re="$3" 'NF == 0 { next } { m = $2; sub(/^[0-9]+:/, "", m); if (tolower(m) !~ re) print }'); rc=$?
    if [ "$rc" -ne 0 ]; then say error "$1: the allow-list filter failed (awk exited $rc); nothing was admitted"; fail=1; return; fi
  fi
  if [ -n "$out" ]; then
    say error "$1"
    printf '%s\n' "$out" | tr '\t' ':' | head -40
    fail=1
  fi
}

redaction() {
  # Every detector takes the WHOLE slug (every slug character after the prefix), so
  # the anchored allow-list sees an admitted slug with a longer tail whole and
  # refuses it; a URL is taken as host/owner/repo only, so two URLs side by side in
  # a JSON array or a table cell are two matches, never one.
  # Lower-case only, on purpose: a repository slug is lower-case, while `Bankai-Agent:`,
  # `Bankai-Run:` (trailer keys), `Bankai-owned` (prose) and `BANKAI-AGENTS-ROSTER` (a
  # document title) are system names the policy keeps (docs/PUBLIC-REDACTION.md,
  # "What is deliberately not redacted").
  check "a bankai-<x> slug that is not this repo, a stack id or a skill name" \
    '\bbankai-[a-z0-9_-]+' \
    '^bankai-(handbooks|machinery|quality|mode|rule|session)$'
  check "an owner slug outside the three public repositories" \
    'zheref/[A-Za-z0-9_.-]+' \
    '^zheref/(hatsu|nen|bankai-handbooks)(\\.git)?\\.?$' \
    -i
  # The detector requires an ASCII alphanumeric after the slash, so an ELIDED url
  # (github.com/<ellipsis>) used in prose examples is never a match to begin with.
  check "a github.com link outside the three public repos (the one admitted fixture is the publisher's fictional acme widget)" \
    'github\.com/[A-Za-z0-9][A-Za-z0-9_.-]*(/[A-Za-z0-9_.-]+)?' \
    '^github\\.com/(zheref/(hatsu|nen|bankai-handbooks)(\\.git)?\\.?|acme/widget\\.git)$' \
    -i
  # A URL is admitted on its owner/repo alone, so a path that walks back out of an
  # admitted repository (`/..`) is refused outright: it resolves somewhere else.
  check "a github.com URL walking back out of its repository with /.." \
    'github\.com/[^ )>"'"'"'|]*/\.\.' \
    '' \
    -i
  check "a LINKED placeholder object id (they stay unlinked)" \
    '\[(RR|RS|RA|RB|RC|RD)-(IS|PR)-#[0-9]+\]\(' \
    ''
}

links() {
  local hits rc
  hits=$(scan '\]\([^)#][^)]*\)'); rc=$?
  if [ "$rc" -ge 2 ]; then say error "links: grep exited $rc -- a file could not be read"; fail=1; return; fi
  hits=$(printf '%s\n' "$hits" | awk -F'\t' 'NF == 2 && $1 ~ /\.md$/ { m = $2; sub(/^[0-9]+:\]\(/, "", m); sub(/\)$/, "", m); if (m !~ /^https?:\/\//) print $1 "\t" m }')
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    src="${hit%%	*}"; target="${hit#*	}"
    case "$src" in */*) base="${src%/*}";; *) base=".";; esac
    path="${target%%#*}"
    [ -z "$path" ] && continue
    # A target carrying a placeholder is documentation, not a path.
    case "$path" in
      http*|mailto:*) continue;;
      *'{'*|*'}'*|*'<'*|*'>'*) continue;;
    esac
    if ! committable "$(normalize "$base/$path")"; then
      say "error file=$src" "dangling relative link -> $path"
      fail=1
    fi
  done <<< "$hits"
}

normalize() { # a/./b/../c -> a/c, never leaving the repository root
  local in="$1" out="" seg
  local IFS='/'
  for seg in $in; do
    case "$seg" in
      ''|.) ;;
      ..) if [ "$out" = "${out%/*}" ]; then out=""; else out="${out%/*}"; fi ;;
      *) out="${out:+$out/}$seg" ;;
    esac
  done
  printf '%s' "$out"
}

committable() { # path -> 0 when it is a committable file, or a directory holding one
  # A link that resolves only on this machine (an ignored file, a stray draft the
  # reader will not have) is dangling for every other checkout: the target has to
  # be in the committable set, as a file or as the directory of one.
  local p="$1"
  [ -n "$p" ] || return 0
  printf '%s\n' "${FILES[@]}" | grep -qxF -- "$p" && return 0
  printf '%s\n' "${FILES[@]}" | grep -q -- "^$(printf '%s' "$p" | sed 's/[][\\.*^$]/\\&/g')/" && return 0
  return 1
}

taxonomy() {
  if ! command -v nen >/dev/null 2>&1; then
    say error "taxonomy: nen is not on PATH; bootstrap it at nen/contract.json's dependency.pinned_ref first"
    tool_missing=1
    return
  fi
  nen schema check --repo "$PWD" || fail=1
}

run() { # the selected checks over the committable set; returns the exit code
  load_files
  case "$what" in
    all) redaction; links; taxonomy ;;
    redaction) redaction ;;
    links) links ;;
    taxonomy) taxonomy ;;
    *) usage ;;
  esac
  if [ "$fail" -ne 0 ]; then return 1; fi
  if [ "$tool_missing" -ne 0 ]; then return 2; fi
  echo "canon_check: $what clean (${#FILES[@]} committable files)"
  return 0
}

# ---- self-test: every guard has a negative test (QA-18, QA-16) ----------------
self_test() {
  local me pass=0 total=0
  me="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  tmp="$(mktemp -d)" && [ -d "$tmp" ] || { echo "canon_check --self-test: mktemp failed" >&2; exit 2; }
  trap 'rm -rf "$tmp"' EXIT

  mk() { # name -> a fresh git repository carrying a copy of this script, cwd there
    local d="$tmp/$1"
    mkdir -p "$d/scripts" "$d/docs"
    cp "$me" "$d/scripts/canon_check.sh"
    printf '.nen/\nReports/\n' > "$d/.gitignore"
    printf '# policy\n' > "$d/docs/PUBLIC-REDACTION.md"
    printf '# ok\n[policy](docs/PUBLIC-REDACTION.md)\n' > "$d/README.md"
    git -C "$d" init -q
    git -C "$d" add -A >/dev/null
    printf '%s' "$d"
  }
  expect() { # label, want-exit, repo, args...
    local label="$1" want="$2" d="$3"; shift 3
    local got
    ( cd "$d" && bash scripts/canon_check.sh "$@" >/dev/null 2>&1 ); got=$?
    total=$((total + 1))
    if [ "$got" = "$want" ]; then pass=$((pass + 1)); printf '  ok    %s (exit %s)\n' "$label" "$got"
    else printf '  FAIL  %s: wanted exit %s, got %s\n' "$label" "$want" "$got"; fi
  }
  # The private shapes below are placeholders, never a real name
  # (docs/PUBLIC-REDACTION.md), and every probe is spelled as two adjacent
  # string literals so this script's own text never carries the shape it hunts.
  local priv="zheref""/PLACEHOLDER-private"
  local d

  d=$(mk clean);                                                      expect "clean tree is clean" 0 "$d" redaction
  expect "clean tree's links resolve" 0 "$d" links
  d=$(mk priv);   printf 'see %s\n' "$priv" > "$d/a.md";             expect "a private owner slug is refused" 1 "$d" redaction
  d=$(mk pfx);    printf '%s\n' "zheref""/hatsu-extra" > "$d/a.md";          expect "an admitted slug with more characters is refused" 1 "$d" redaction
  d=$(mk dot);    printf '%s\n' "zheref""/nen." > "$d/a.md";                  expect "an admitted slug before a full stop is admitted" 0 "$d" redaction
  d=$(mk bank);   printf '%s\n' "bankai-""sessionx" > "$d/a.md";             expect "a bankai-<x> slug outside the admitted set is refused" 1 "$d" redaction
  d=$(mk bankok); printf '%s %s\n' "bankai-""handbooks" "bankai-""session" > "$d/a.md"; expect "the admitted bankai slugs pass" 0 "$d" redaction
  d=$(mk gh);     printf '%s\n' "https://github.com""/acme/other" > "$d/a.md"; expect "a github.com link outside the three repos is refused" 1 "$d" redaction
  d=$(mk ghfx);   printf '%s and %s\n' "https://github.com""/acme/widget.git" "https://github.com""/zheref/hatsu#1" > "$d/a.md"; expect "the publisher fixture and a public issue link pass" 0 "$d" redaction
  d=$(mk ghpfx);  printf '%s\n' "https://github.com""/zheref""/hatsu-private" > "$d/a.md"; expect "a public prefix with more slug characters is refused" 1 "$d" redaction
  d=$(mk linked); printf '%s%s\n' "[RA-IS-#12]" "(https://x)" > "$d/a.md";      expect "a linked placeholder id is refused" 1 "$d" redaction
  d=$(mk adj);    printf '[\"%s\",\"%s\"]\n' "https://github.com""/zheref/hatsu" "https://github.com""/acme/other" > "$d/a.json"; expect "two URLs side by side in compact JSON are two matches" 1 "$d" redaction
  d=$(mk pipe);   printf '%s|%s\n' "https://github.com""/zheref/nen" "https://github.com""/acme/other" > "$d/a.md"; expect "a pipe-adjacent URL hides nothing" 1 "$d" redaction
  d=$(mk dots);   printf '%s/../../acme/other\n' "https://github.com""/zheref/hatsu" > "$d/a.md"; expect "a URL walking past an admitted repo is refused" 1 "$d" redaction
  d=$(mk caps);   printf '%s\n' "https://GitHub.com""/Acme/other" > "$d/a.md"; expect "a capitalised host or owner is still detected" 1 "$d" redaction
  d=$(mk capok);  printf '%s and %s\n' "https://GitHub.com""/zheref/Hatsu.git" "Zheref""/nen" > "$d/a.md"; expect "capitalised admitted slugs pass" 0 "$d" redaction
  d=$(mk brule);  printf '%s\n' "hatsu:bankai-""rule" > "$d/a.md";          expect "the bankai-rule skill name passes" 0 "$d" redaction
  d=$(mk brtail); printf '%s\n' "bankai-""rules" > "$d/a.md";               expect "the bankai-rule name with a longer tail is refused" 1 "$d" redaction
  d=$(mk btail);  printf '%s %s\n' "bankai-""handbooks-placeholder" "bankai-""session2" > "$d/a.md"; expect "an admitted bankai prefix with a longer tail is refused" 1 "$d" redaction
  d=$(mk bcap);   printf '%s %s\n' "Bankai-""Agent:" "Bankai-""owned" > "$d/a.md"; expect "a capitalised Bankai- term is a system name, not a slug" 0 "$d" redaction
  d=$(mk colon);  printf '%s\n' "https://github.com""/acme/other" > "$d/a:1:github.com:x.md"; git -C "$d" add -A >/dev/null; expect "a path carrying colons cannot forge the match field" 1 "$d" redaction
  d=$(mk untr);   printf '%s\n' "$priv" > "$d/draft.md";             expect "an untracked draft is scanned" 1 "$d" redaction
  d=$(mk ign);    mkdir -p "$d/Reports"; printf '%s\n' "$priv" > "$d/Reports/r.md"; expect "an ignored generated file is not scanned" 0 "$d" redaction
  d=$(mk forced); mkdir -p "$d/handbooks/Reports"; printf '%s\n' "$priv" > "$d/handbooks/Reports/r.md"; git -C "$d" add -f handbooks/Reports/r.md >/dev/null; expect "a file forced past .gitignore is scanned wherever it sits" 1 "$d" redaction
  d=$(mk bin);    printf '%s\0\n' "$priv" > "$d/b.bin";                expect "a binary file carrying a slug is refused" 1 "$d" redaction
  d=$(mk dangle); printf '[x](nope.md)\n' > "$d/a.md";                 expect "a dangling relative link is refused" 1 "$d" links
  d=$(mk coldl);  printf '[x](nope.md)\n' > "$d/c:d.md"; git -C "$d" add -A >/dev/null; expect "a dangling link in a file whose name carries a colon is refused" 1 "$d" links
  d=$(mk ignl);   mkdir -p "$d/.nen"; printf 'x\n' > "$d/.nen/ignored.md"; printf '[x](.nen/ignored.md) [y](../%s/README.md)\n' "$(basename "$d")" > "$d/a.md"; expect "a link to an ignored file, or out of the root, is dangling" 1 "$d" links
  d=$(mk dirl);   printf '[x](docs) [y](docs/) [z](./docs/../README.md)\n' > "$d/a.md"; expect "a link to a directory holding committable files, or through ./ and ../, resolves" 0 "$d" links
  d=$(mk gone);   rm "$d/README.md";                                    expect "a tracked file deleted without git rm is skipped, not refused" 0 "$d" redaction
  d=$(mk anchor); printf '[x](README.md#ok) [y](<owner/name>) [z](%s)\n' "https://github.com""/zheref/nen" > "$d/a.md"; expect "anchors, placeholders and absolute links are not dangling" 0 "$d" links
  if [ "$(id -u)" != 0 ]; then
    d=$(mk unread); printf '%s\n' "$priv" > "$d/u.md"; chmod 000 "$d/u.md"; expect "an unreadable file is a finding, never clean" 1 "$d" redaction; chmod 644 "$d/u.md"
  fi
  d=$(mk nonen);  ( cd "$d" && PATH=/usr/bin:/bin bash scripts/canon_check.sh taxonomy >/dev/null 2>&1 ); got=$?; total=$((total+1)); if [ "$got" = 2 ]; then pass=$((pass+1)); echo "  ok    taxonomy with nen absent exits 2 (exit 2)"; else echo "  FAIL  taxonomy with nen absent: wanted 2, got $got"; fi
  d=$(mk nonen2); printf '%s\n' "$priv" > "$d/a.md"; ( cd "$d" && PATH=/usr/bin:/bin bash scripts/canon_check.sh all >/dev/null 2>&1 ); got=$?; total=$((total+1)); if [ "$got" = 1 ]; then pass=$((pass+1)); echo "  ok    all with a finding and nen absent exits 1, the finding outranking the tool (exit 1)"; else echo "  FAIL  all with a finding and nen absent: wanted 1, got $got"; fi
  d=$(mk usage);  expect "an unknown argument is usage" 2 "$d" bogus
  ( cd "$d" && bash scripts/canon_check.sh redaction extra >/dev/null 2>&1 ); got=$?; total=$((total+1)); if [ "$got" = 2 ]; then pass=$((pass+1)); echo "  ok    a second argument is usage (exit 2)"; else echo "  FAIL  a second argument: wanted 2, got $got"; fi

  echo "canon_check --self-test: $pass/$total"
  [ "$pass" = "$total" ]
}

if [ "${SELF_TEST:-0}" = 1 ]; then
  self_test
  exit $?
fi
# `taxonomy` with nen absent on PATH: PATH is the caller's; the self-test strips it.
run
exit $?
