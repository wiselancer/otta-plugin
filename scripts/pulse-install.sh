#!/usr/bin/env bash
# pulse-install.sh [--open] — onboard the Otta Pulse GitHub App.
#
# Install is interactive browser consent (GitHub never lets a tool install an
# App silently). This prints the install URL and, with --open, launches it.
# Detection of an existing install needs the App's own JWT, which a customer
# doesn't have — so we guide rather than auto-detect.
set -euo pipefail

APP_SLUG="otta-pulse"
INSTALL_URL="https://github.com/apps/${APP_SLUG}/installations/new"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '<your repo>')"

cat <<EOF
Otta Pulse — DORA metrics + merge gates for your repos.

1. Open:   ${INSTALL_URL}
2. Pick your account/org (the owner of ${REPO}).
3. Choose "All repositories" (auto-covers future repos) or select specific ones.
4. Install. Backfill of ~180 days runs automatically within minutes.

After install, Pulse ingests your PR/CI/tag webhooks with zero further config.
EOF

if [ "${1:-}" = "--open" ]; then
  if command -v open >/dev/null; then open "$INSTALL_URL"
  elif command -v xdg-open >/dev/null; then xdg-open "$INSTALL_URL"
  else echo "(could not auto-open — visit the URL above)"; fi
fi
