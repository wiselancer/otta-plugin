#!/usr/bin/env bash
# install-git-hooks.sh — install a pre-push hook in the CURRENT repo that runs
# the Otta gate. Idempotent. Works whether or not core.hooksPath is set.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo." >&2; exit 1; }
HOOKS_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS_DIR"
HOOK="$HOOKS_DIR/pre-push"

cat > "$HOOK" <<EOF
#!/usr/bin/env bash
# Installed by the Otta plugin — local mirror of the Pulse merge gates.
# Bypass once with: OTTA_SKIP_GATE=1 git push
[ -n "\${OTTA_SKIP_GATE:-}" ] && exit 0
exec "$HERE/otta-gate.sh"
EOF
chmod +x "$HOOK"
echo "✓ installed pre-push gate → $HOOK"
echo "  bypass once with: OTTA_SKIP_GATE=1 git push"
