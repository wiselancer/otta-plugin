#!/usr/bin/env bash
# otta-worktree.sh — isolate a pipeline run in its own git worktree (#47).
#
# The session may be on an unrelated, dirty feature branch. Branching in place
# (git switch -c) still mutates the session's working tree. A linked worktree is
# a physically separate checkout sharing the same .git, so the pipeline cannot
# touch the session's branch or files at all.
#
# Usage:
#   path="$(otta-worktree.sh <issue> [base])"   # create/reuse → prints the worktree path on stdout
#   cd "$path"                                    # every pipeline stage runs here
#   otta-worktree.sh --remove <issue>             # tear it down after the PR is opened
#
# Deterministic path: ${OTTA_WORKTREE_DIR:-~/.otta/worktrees}/<repo-slug>-<issue>
# so each stage (builder/reviewer/qa/devops) resolves the SAME directory.
# Only the path goes to stdout; all logs go to stderr (so `cd "$(...)"` is safe).
set -euo pipefail

WT_ROOT="${OTTA_WORKTREE_DIR:-$HOME/.otta/worktrees}"

repo_slug() {
  local r cg main
  r="$(git config --get remote.origin.url 2>/dev/null || true)"
  r="${r%.git}"; r="${r##*[:/]}"          # last path segment of the remote url
  if [ -z "$r" ]; then
    # No remote: fall back to the MAIN worktree's name. Must be cwd-stable —
    # `git rev-parse --show-toplevel` returns the *linked* worktree's path when
    # run from inside one (giving a different slug at create vs remove time), so
    # resolve the common git dir's parent instead.
    cg="$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P || true)"
    main="$(dirname "${cg:-$(git rev-parse --show-toplevel)/.git}")"
    r="$(basename "$main")"
  fi
  printf '%s' "$r" | tr -cd 'A-Za-z0-9._-'
}

if [ "${1:-}" = "--remove" ]; then
  ISSUE="${2:?usage: otta-worktree.sh --remove <issue>}"
  SLUG="$(repo_slug)"
  WT="$WT_ROOT/$SLUG-$ISSUE"
  if [ -e "$WT/.git" ]; then
    # Resolve to the real path git registered (macOS symlinks e.g. /var →
    # /private/var, and `git worktree remove` matches on the registered path).
    RWT="$(cd "$WT" && pwd -P)"
    # DevOps calls this from *inside* the worktree (it cd'd in to ship). Git
    # refuses to remove the worktree you're standing in, so step out to the
    # main worktree (first entry of `git worktree list`) first.
    MAIN_WT="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
    [ -n "$MAIN_WT" ] && cd "$MAIN_WT"
    git worktree remove --force "$RWT"
    echo "✓ removed worktree $RWT" >&2
  else
    echo "no worktree at $WT (nothing to remove)" >&2
  fi
  exit 0
fi

# --prune [hours] — GC orphaned worktrees (a run that died before DevOps tore
# its worktree down). Age is the safe signal: a pipeline takes minutes, so any
# worktree older than the threshold is an orphan. Age survives squash-merge
# branch deletion (which breaks "is the branch merged" checks). An in-flight run
# (minutes old) is never touched. Default threshold 24h; pass 0 to remove all.
if [ "${1:-}" = "--prune" ]; then
  HOURS="${2:-24}"
  SLUG="$(repo_slug)"
  NOW="$(date +%s)"
  MAIN_WT="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
  [ -n "$MAIN_WT" ] && cd "$MAIN_WT"
  removed=0
  for d in "$WT_ROOT/$SLUG-"*; do
    [ -e "$d/.git" ] || continue
    m="$(stat -f %m "$d" 2>/dev/null || stat -c %Y "$d" 2>/dev/null || echo "$NOW")"
    age_h=$(( (NOW - m) / 3600 ))
    if [ "$age_h" -ge "$HOURS" ]; then
      git worktree remove --force "$(cd "$d" && pwd -P)" \
        && { echo "✓ pruned $d (${age_h}h old)" >&2; removed=$((removed + 1)); }
    else
      echo "↻ keeping $d (${age_h}h old < ${HOURS}h)" >&2
    fi
  done
  git worktree prune
  echo "pruned $removed orphaned worktree(s)" >&2
  exit 0
fi

ISSUE="${1:?usage: otta-worktree.sh <issue> [base]}"
BASE="${2:-}"

# Resolve the base branch: explicit arg, else origin's default HEAD branch.
if [ -z "$BASE" ]; then
  BASE="$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')"
  [ -n "$BASE" ] || BASE="main"
fi

git fetch origin "$BASE" >/dev/null 2>&1 || git fetch origin >/dev/null 2>&1 || true

# Prefer the remote-tracking ref so we branch off the true base, not local drift.
START="$BASE"
git rev-parse --verify --quiet "origin/$BASE" >/dev/null 2>&1 && START="origin/$BASE"

SLUG="$(repo_slug)"
WT="$WT_ROOT/$SLUG-$ISSUE"
BRANCH="otta/$ISSUE"

mkdir -p "$WT_ROOT"

# Reuse an existing worktree (idempotent across stages); else create it.
# Detect via the linked-worktree .git pointer — symlink-safe (macOS resolves
# /var → /private/var, so matching `git worktree list` paths is unreliable).
if [ -e "$WT/.git" ]; then
  echo "↻ reusing worktree $WT" >&2
else
  git worktree add -B "$BRANCH" "$WT" "$START" >/dev/null 2>&1 \
    || git worktree add "$WT" "$START" >/dev/null 2>&1
  echo "✓ worktree $WT on $BRANCH off $START" >&2
fi

printf '%s\n' "$WT"
