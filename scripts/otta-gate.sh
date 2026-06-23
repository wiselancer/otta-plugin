#!/usr/bin/env bash
# otta-gate.sh — run the full local Otta gate (body structure + test-coverage).
# Mirrors the Otta Pulse merge gates so failures surface BEFORE push, not in CI.
# Exit 0 = ready to push. Non-zero = blocked.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok=0
reasons=""
out="$(bash "$HERE/check-pr-body.sh" "${1:-.pr-body.md}" 2>&1)" || { ok=1; reasons="$out"; }
[ -z "${OTTA_GATE_QUIET:-}" ] && printf '%s\n' "$out"
out="$(bash "$HERE/check-test-coverage.sh" 2>&1)" || { ok=1; reasons="${reasons}
${out}"; }
[ -z "${OTTA_GATE_QUIET:-}" ] && printf '%s\n' "$out"

# Capture the verdict to the LEARN ledger (free — a write, no LM call). Never
# let a capture failure affect the gate result. Opt out with OTTA_NO_CAPTURE=1.
if [ -z "${OTTA_NO_CAPTURE:-}" ]; then
  fb="$([ "$ok" -eq 0 ] && echo "all gates passed" || printf '%s' "$reasons" | tr '\n' ' ' | sed 's/  */ /g')"
  bash "$HERE/ledger-append.sh" --source gate --event gate_run \
    --score "$([ "$ok" -eq 0 ] && echo 1 || echo 0)" --feedback "$fb" \
    --input "{\"branch\":\"$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')\"}" \
    >/dev/null 2>&1 || true
fi

if [ "$ok" -ne 0 ]; then
  echo "" >&2
  echo "⛔ otta gate failed — fix the above before pushing (or you'll fail CI)." >&2
  exit 1
fi
echo "✓ otta gate passed — clear to push."
