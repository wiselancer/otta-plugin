# Security

## What this plugin does on your machine

- Runs local shell scripts (gate checks, `.pr-body.md` seeding, ledger append) via
  `gh` + `jq`. No code is sent anywhere by the plugin itself.
- The `pre-push` hook / `PreToolUse` guard runs the local gate before a push. Bypass
  with `OTTA_SKIP_GATE=1`.
- Writes a local ledger of gate verdicts to `~/.otta/ledger/<repo>.jsonl`
  (`{score, feedback, input}` — your gate results). It stays on your machine. Opt out
  with `OTTA_NO_CAPTURE=1`; relocate with `OTTA_LEDGER_DIR`.
- No secrets are stored or transmitted by the plugin. The optional Otta Pulse GitHub
  App is installed and authenticated separately by you.

## Reporting a vulnerability

Open a private security advisory on this repository, or email the maintainer. Please
do not file public issues for security reports.
