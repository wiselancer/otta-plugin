#!/usr/bin/env bash
# Regression test: reviewer + qa agents must capture their LLM verdict to the
# LEARN ledger (richer GEPA signal than the deterministic gate alone).
# Guards against the capture step being dropped from the agent prompts.
# Run: bash tests/verdict-capture.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HERE/../agents"
fail() { echo "✗ $1" >&2; exit 1; }

# 1. reviewer captures a spec_review verdict via ledger-append
grep -q 'ledger-append.sh' "$AGENTS/reviewer.md" || fail "reviewer.md missing ledger-append capture"
grep -q -- '--source reviewer' "$AGENTS/reviewer.md" || fail "reviewer.md capture missing --source reviewer"
grep -q -- '--event spec_review' "$AGENTS/reviewer.md" || fail "reviewer.md capture missing --event spec_review"

# 2. qa captures a verify verdict via ledger-append
grep -q 'ledger-append.sh' "$AGENTS/qa.md" || fail "qa.md missing ledger-append capture"
grep -q -- '--source qa' "$AGENTS/qa.md" || fail "qa.md capture missing --source qa"
grep -q -- '--event verify' "$AGENTS/qa.md" || fail "qa.md capture missing --event verify"

# 3. both reference the plugin-root-relative script path (works in session + workflow)
grep -q 'CLAUDE_PLUGIN_ROOT}/scripts/ledger-append.sh' "$AGENTS/reviewer.md" || fail "reviewer.md not using CLAUDE_PLUGIN_ROOT path"
grep -q 'CLAUDE_PLUGIN_ROOT}/scripts/ledger-append.sh' "$AGENTS/qa.md" || fail "qa.md not using CLAUDE_PLUGIN_ROOT path"

echo "✓ verdict-capture: all checks passed"
