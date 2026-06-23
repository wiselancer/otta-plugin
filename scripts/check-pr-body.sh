#!/usr/bin/env bash
# check-pr-body.sh [path]
#
# Verifies .pr-body.md STRUCTURE (the part visible in the body itself):
#   1. a ```acceptance fenced block            (acceptance-block gate)
#   2. a Fixes #<issue> GitHub linkage          (so issue→PR exists in GitHub)
#   3. an idea_ref line                         (so Pulse can join idea→version)
# Test-coverage is a DIFF property, not a body property — see check-test-coverage.sh.
# Exit 0 = body OK. Exit 1 = fix the body first.
set -euo pipefail

BODY="${1:-.pr-body.md}"
if [ ! -f "$BODY" ]; then
  echo "⛔ $BODY missing. Run /otta-start <issue> (or otta seed) to create it." >&2
  exit 1
fi

fail=0
note() { echo "  ✗ $1" >&2; fail=1; }

grep -qE '```acceptance' "$BODY" || note "no \`\`\`acceptance fenced block (acceptance-block gate)"

grep -qE '(^|[^A-Za-z])Fixes #[0-9]+' "$BODY" \
  || note "no 'Fixes #<issue>' GitHub linkage — issue→PR link won't exist in GitHub"

# idea_ref must have a real value, not a <!-- comment --> placeholder.
grep -qiE '^idea_ref:\s*[^[:space:]<]' "$BODY" \
  || note "no real 'idea_ref:' value — Pulse can't join idea→version (use issue:#N if unsure)"

if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "⛔ otta gate: $BODY incomplete — fix the items above before pushing." >&2
  exit 1
fi
echo "✓ otta gate: $BODY has acceptance block, Fixes #N, idea_ref"
