#!/usr/bin/env bash
# canon_check.sh — the mechanical verification of a public canon repository.
#
# There is no build here: the product is prose. What can go silently wrong is
# (1) a private name reaching the public tree, (2) a relative link that does not
# resolve, and (3) a nen/ declaration that does not parse. This script is the
# `lint` verb of the `canon` lane (nen/contract.json), the one iteration check
# nen/workflow.json declares, and the body of every job in
# .github/workflows/canon.yml -- one implementation, run locally by nen shu lint
# and in CI per job, so the two can never disagree.
#
# USAGE
#   scripts/canon_check.sh [all | redaction | links | taxonomy]   (default: all)
#
# EXIT  0 every selected check clean · 1 a finding, printed · 2 usage or a
# missing tool (nen for taxonomy). A finding is printed as a GitHub Actions
# annotation when GITHUB_ACTIONS is set and as a plain line otherwise.
#
# The redaction patterns are SHAPE-based on purpose: this repository must never
# spell a private name in order to find one (docs/PUBLIC-REDACTION.md).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here" || exit 2
what="${1:-all}"
fail=0

say() { # level, message
  if [ -n "${GITHUB_ACTIONS:-}" ]; then printf '::%s::%s\n' "$1" "$2"; else printf '%s: %s\n' "$1" "$2"; fi
}

check() { # title, command
  local out
  out=$(eval "$2" || true)
  if [ -n "$out" ]; then
    say error "$1"
    printf '%s\n' "$out" | head -40
    fail=1
  fi
}

redaction() {
  check "a bankai-<x> slug that is not this repo or a stack id" \
    "grep -rnoE '\\bbankai-[a-z]+' --exclude=.git --exclude-dir=.git --exclude-dir=.nen --exclude-dir=Reports . | grep -vE 'bankai-(handbooks|machinery|quality|mode|session)'"
  check "a zheref/<repo> slug outside the three public ones" \
    "grep -rnoE 'zheref/[A-Za-z0-9_.-]+' --exclude=.git --exclude-dir=.git --exclude-dir=.nen --exclude-dir=Reports . | grep -vE 'zheref/(hatsu|nen|bankai-handbooks)\\b'"
  # The detector requires an ASCII alphanumeric after the slash, so an ELIDED url
  # (github.com/<ellipsis>) used in prose examples is never a match to begin with.
  # `acme/...` is the legend's FICTIONAL owner (docs/PUBLIC-REDACTION.md, the
  # legend's last row): an illustrative value, never a repository a reader could open.
  check "a github.com link outside the three public repos (acme/ is the fictional owner)" \
    "grep -rnoE 'github\\.com/[A-Za-z0-9][^ )>]*' --exclude=.git --exclude-dir=.git --exclude-dir=.nen --exclude-dir=Reports . | grep -vE 'github\\.com/(zheref/(hatsu|nen|bankai-handbooks)|acme/)\\b'"
  check "a LINKED placeholder object id (they stay unlinked)" \
    "grep -rnoE '\\[(RR|RS|RA|RB|RC|RD)-(IS|PR)-#[0-9]+\\]\\(' --exclude=.git --exclude-dir=.git --exclude-dir=.nen --exclude-dir=Reports ."
}

links() {
  while IFS= read -r hit; do
    src="${hit%%:*}"; target="${hit#*:}"
    case "$src" in */*) base="${src%/*}";; *) base=".";; esac
    path="${target%%#*}"
    [ -z "$path" ] && continue
    # A target carrying a placeholder is documentation, not a path.
    case "$path" in
      http*|mailto:*) continue;;
      *'{'*|*'}'*|*'<'*|*'>'*) continue;;
    esac
    if [ ! -e "$base/$path" ]; then
      say "error file=$src" "dangling relative link -> $path"
      fail=1
    fi
  done < <(grep -rnoE '\]\([^)#][^)]*\)' --include='*.md' --exclude=.git --exclude-dir=.git --exclude-dir=.nen --exclude-dir=Reports . \
            | sed -E 's/^([^:]+):[0-9]+:\]\((.*)\)$/\1:\2/' \
            | grep -vE ':https?://' || true)
}

taxonomy() {
  if ! command -v nen >/dev/null 2>&1; then
    say error "taxonomy: nen is not on PATH; bootstrap it at nen/contract.json's dependency.pinned_ref first"
    return 2
  fi
  nen schema check --repo "$here" || fail=1
}

case "$what" in
  all) redaction; links; taxonomy; rc=$?; [ "$rc" -eq 2 ] && exit 2 ;;
  redaction) redaction ;;
  links) links ;;
  taxonomy) taxonomy; rc=$?; [ "$rc" -eq 2 ] && exit 2 ;;
  *) echo "usage: scripts/canon_check.sh [all | redaction | links | taxonomy]" >&2; exit 2 ;;
esac

if [ "$fail" -eq 0 ]; then
  echo "canon_check: $what clean"
fi
exit "$fail"
