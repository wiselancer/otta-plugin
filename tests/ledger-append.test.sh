#!/usr/bin/env bash
# Regression test for ledger-append.sh (#36 LEARN-layer capture).
# Run: bash tests/ledger-append.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../scripts/ledger-append.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "✗ $1" >&2; exit 1; }

# 1. append a record → one valid GEPA-shaped JSON line
OTTA_LEDGER_DIR="$TMP" bash "$SCRIPT" --source gate --event gate_run --score 0 \
  --feedback "acceptance-block FAIL" --project "acme/web" --input '{"branch":"x"}' >/dev/null 2>&1
F="$TMP/acme-web.jsonl"
[ -f "$F" ] || fail "ledger file not created"
[ "$(wc -l < "$F" | tr -d ' ')" = "1" ] || fail "expected 1 record"
jq -e '.score==0 and .source=="gate" and .event=="gate_run" and .feedback=="acceptance-block FAIL" and .input.branch=="x"' "$F" >/dev/null || fail "record shape wrong"

# 2. second append → appends (does not overwrite)
OTTA_LEDGER_DIR="$TMP" bash "$SCRIPT" --source gate --event gate_run --score 1 --feedback ok --project "acme/web" >/dev/null 2>&1
[ "$(wc -l < "$F" | tr -d ' ')" = "2" ] || fail "expected 2 records after second append"

# 3. project slug sanitizes the slash
[ -f "$TMP/acme-web.jsonl" ] || fail "project slug not sanitized to acme-web"

# 4. feedback with quotes is escaped (valid JSON)
OTTA_LEDGER_DIR="$TMP" bash "$SCRIPT" --source qa --event verify --score 1 \
  --feedback 'AC1 "redirect" passed' --project "acme/web" >/dev/null 2>&1
tail -1 "$F" | jq -e '.feedback=="AC1 \"redirect\" passed"' >/dev/null || fail "quote escaping broken"

# 5. missing required arg → exit 2
if OTTA_LEDGER_DIR="$TMP" bash "$SCRIPT" --source x >/dev/null 2>&1; then fail "should exit non-zero on missing args"; fi

# 6. an unreachable Pulse push is best-effort: the ledger is still written and
#    the script still exits 0 (a slow/down server must never break the gate).
OTTA_LEDGER_DIR="$TMP" OTTA_PULSE_URL="http://127.0.0.1:9" OTTA_PULSE_TOKEN="t" \
  bash "$SCRIPT" --source qa --event verify --score 1 --feedback ok --project "acme/web" \
    --input '{"branch":"otta/5"}' >/dev/null 2>&1 \
  || fail "best-effort pulse push broke the gate (non-zero exit on unreachable server)"
[ "$(wc -l < "$F" | tr -d ' ')" = "4" ] || fail "ledger not written when pulse push fails"

echo "✓ ledger-append: all 6 checks passed"
