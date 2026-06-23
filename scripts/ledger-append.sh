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

# Optional bridge to a Pulse server: when OTTA_PULSE_URL + OTTA_PULSE_TOKEN are
# set, also push this verdict as a `loop_verdict` event so it lands in the
# server-side log next to CI/deploy/defect data (the ledger jsonl is local to
# THIS machine; the server can't read it). Best-effort: a failed/slow push must
# never break the gate, so it's time-boxed and its failure is swallowed. The
# external_id matches `pulse ingest-ledger`'s scheme so the two never double-count.
if [ -n "${OTTA_PULSE_URL:-}" ] && [ -n "${OTTA_PULSE_TOKEN:-}" ] && command -v jq >/dev/null 2>&1; then
  BRANCH="$(printf '%s' "$INPUT" | jq -r '.branch // ""' 2>/dev/null || echo "")"
  EXTID="ledger:${PROJECT}:${TS}:${SOURCE}:${EVENT}:${BRANCH}"
  BODY="$(jq -cn --arg s otta-ledger --arg t loop_verdict --arg e "$EXTID" \
        --arg repo "$PROJECT" --arg ts "$TS" --arg vs "$SOURCE" --arg ev "$EVENT" \
        --argjson score "$SCORE" --arg fb "$FEEDBACK" --argjson input "$INPUT" \
    '{source:$s, type:$t, externalId:$e, repo:$repo, occurredAt:$ts,
      payload:{verdict_source:$vs, event:$ev, score:$score, feedback:$fb, input:$input}}')"
  if curl -fsS -m 5 -X POST "${OTTA_PULSE_URL%/}/event" \
       -H "x-pulse-token: ${OTTA_PULSE_TOKEN}" -H "content-type: application/json" \
       -d "$BODY" >/dev/null 2>&1; then
    echo "  → pushed loop_verdict to Pulse" >&2
  else
    echo "  (pulse push skipped — local ledger still written)" >&2
  fi
fi
