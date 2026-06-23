#!/usr/bin/env bash
# Regression test for otta-worktree.sh (#47 worktree isolation).
# Verifies a pipeline run gets an isolated worktree off the base, on its own
# branch, without disturbing the session's current branch — and tears down.
# Run: bash tests/otta-worktree.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../scripts/otta-worktree.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "✗ $1" >&2; exit 1; }

# Build a throwaway repo with a base branch `main` and a dirty feature branch.
REPO="$TMP/repo"
git init -q -b main "$REPO"
cd "$REPO"
git config user.email t@t.t; git config user.name t
echo base > f.txt; git add f.txt; git commit -qm base
git switch -qc feature
echo work >> f.txt; git commit -qam work     # session is on `feature`, ahead of main
SESSION_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

export OTTA_WORKTREE_DIR="$TMP/wt"

# 1. create → prints a path that exists
WT="$(bash "$SCRIPT" 42 main)"
[ -d "$WT" ] || fail "worktree dir not created: $WT"
[ "$WT" = "$TMP/wt/repo-42" ] || fail "unexpected worktree path: $WT"

# 2. worktree is on its own otta/42 branch off main (NOT the feature commit)
WT_BRANCH="$(git -C "$WT" rev-parse --abbrev-ref HEAD)"
[ "$WT_BRANCH" = "otta/42" ] || fail "worktree on wrong branch: $WT_BRANCH"
[ "$(git -C "$WT" rev-parse HEAD)" = "$(git rev-parse main)" ] || fail "worktree not based on main"
grep -q work "$WT/f.txt" && fail "worktree leaked the feature-branch change"

# 3. the session's own branch is untouched
[ "$(git rev-parse --abbrev-ref HEAD)" = "$SESSION_BRANCH" ] || fail "session branch changed to $(git rev-parse --abbrev-ref HEAD)"

# 4. idempotent: second call reuses the same path, no error
WT2="$(bash "$SCRIPT" 42 main)"
[ "$WT2" = "$WT" ] || fail "second call returned different path: $WT2"

# 5. --remove tears the worktree down
bash "$SCRIPT" --remove 42 >/dev/null 2>&1
[ -d "$WT" ] && fail "worktree not removed"

echo "✓ otta-worktree: all 5 checks passed"
