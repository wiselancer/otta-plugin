#!/usr/bin/env bash
# pre-push-guard.sh — PreToolUse(Bash) hook. Reads the tool-call JSON on stdin;
# if the command is a `git push`, runs the Otta gate and blocks (exit 2) when it
# fails, so an agent can't push past the gate. Silent pass for everything else.
#
# Bypass: set OTTA_SKIP_GATE=1 in the environment.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input="$(cat)"

# Extract the command (jq if available, else grep fallback).
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  cmd="$input"
fi

# Only care about real pushes.
printf '%s' "$cmd" | grep -qE '(^|[^a-zA-Z])git[[:space:]]+push' || exit 0
[ -n "${OTTA_SKIP_GATE:-}" ] && exit 0
# Only gate inside a repo that uses the loop (has a seeded body).
[ -f ".pr-body.md" ] || exit 0

if ! out="$(bash "$HERE/../scripts/otta-gate.sh" 2>&1)"; then
  echo "otta gate blocked this push:" >&2
  echo "$out" >&2
  exit 2
fi
exit 0
