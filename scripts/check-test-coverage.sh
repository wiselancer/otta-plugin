#!/usr/bin/env bash
# check-test-coverage.sh [base-ref] [body-path]
#
# Accurate local mirror of the test-coverage gate: the change must either ADD a
# test file in the diff, OR carry an explicit [test-impractical: <reason>] in
# the PR body. Mirrors CI exactly by reading the real diff, not a body line.
# base-ref defaults to the merge-base with origin's default branch.
set -euo pipefail

BASE="${1:-}"
BODY="${2:-.pr-body.md}"

if [ -z "$BASE" ]; then
  DEFAULT="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
  DEFAULT="${DEFAULT:-main}"
  BASE="$(git merge-base "origin/$DEFAULT" HEAD 2>/dev/null || echo "origin/$DEFAULT")"
fi

# Added/modified test files in the diff (broad: *.test.* / *.spec.* / tests/ dir).
TEST_FILES="$(git diff --name-only "$BASE"...HEAD 2>/dev/null \
  | grep -iE '(\.(test|spec)\.[a-z]+$|(^|/)tests?/)' || true)"

if [ -n "$TEST_FILES" ]; then
  echo "✓ test-coverage: diff adds/edits test file(s):"
  echo "$TEST_FILES" | sed 's/^/    /'
  exit 0
fi

if [ -f "$BODY" ] && grep -qiE '\[test-impractical:' "$BODY"; then
  echo "✓ test-coverage: no test in diff, but [test-impractical: …] declared in $BODY"
  exit 0
fi

echo "⛔ test-coverage gate: diff adds no test file and $BODY has no [test-impractical: <reason>]." >&2
echo "   Add a focused test, or justify with [test-impractical: <reason>] in the PR body." >&2
exit 1
