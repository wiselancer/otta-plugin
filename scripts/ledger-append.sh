#!/usr/bin/env bash
# ledger-append.sh — append one GEPA-shaped record to the local Otta ledger.
#
# This is the LEARN-layer data capture (#36). It's a file write — 0 LM tokens —
# so capturing every gate run / pipeline verdict is essentially free. Records
# accrue across every project you push from into one user-level ledger, ready to
# become a GEPA trainset later (ADR-0004).
#
# Usage:
#   ledger-append.sh --source <s> --event <e> --score <0..1> --feedback <text> \
#                    [--project <owner/repo>] [--input <json>] [--output <json>]
#
# Store: ${OTTA_LEDGER_DIR:-~/.otta/ledger}/<project-slug>.jsonl  (one file per repo)
set -euo pipefail

SOURCE="" EVENT="" SCORE="" FEEDBACK="" PROJECT="" INPUT="{}" OUTPUT="{}"
while [ $# -gt 0 ]; do
  case "$1" in
    --source)   SOURCE="$2"; shift 2;;
    --event)    EVENT="$2"; shift 2;;
    --score)    SCORE="$2"; shift 2;;
    --feedback) FEEDBACK="$2"; shift 2;;
    --project)  PROJECT="$2"; shift 2;;
    --input)    INPUT="$2"; shift 2;;
    --output)   OUTPUT="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[ -z "$SOURCE" ] || [ -z "$EVENT" ] || [ -z "$SCORE" ] && {
  echo "usage: ledger-append.sh --source <s> --event <e> --score <n> --feedback <t> [--project p]" >&2; exit 2; }

# Project: explicit, else the current repo, else 'unknown'.
[ -z "$PROJECT" ] && PROJECT="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo unknown)"
SLUG="$(printf '%s' "$PROJECT" | tr '/' '-' | tr -cd 'A-Za-z0-9._-')"
[ -z "$SLUG" ] && SLUG="unknown"

DIR="${OTTA_LEDGER_DIR:-$HOME/.otta/ledger}"
mkdir -p "$DIR"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Build the record with jq if available (safe escaping), else a minimal fallback.
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg ts "$TS" --arg project "$PROJECT" --arg source "$SOURCE" \
        --arg event "$EVENT" --argjson score "$SCORE" --arg feedback "$FEEDBACK" \
        --argjson input "$INPUT" --argjson output "$OUTPUT" \
    '{ts:$ts, project:$project, source:$source, event:$event, score:$score, feedback:$feedback, input:$input, output:$output}' \
    >> "$DIR/$SLUG.jsonl"
else
  esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
  printf '{"ts":"%s","project":"%s","source":"%s","event":"%s","score":%s,"feedback":"%s","input":%s,"output":%s}\n' \
    "$TS" "$(esc "$PROJECT")" "$(esc "$SOURCE")" "$(esc "$EVENT")" "$SCORE" "$(esc "$FEEDBACK")" "$INPUT" "$OUTPUT" \
    >> "$DIR/$SLUG.jsonl"
fi

echo "✓ ledger += $EVENT (score=$SCORE) → $DIR/$SLUG.jsonl" >&2
