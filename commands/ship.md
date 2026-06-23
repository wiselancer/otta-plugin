---
description: Run the Otta gate and open the PR with the seeded body
argument-hint: "[--base <branch>]"
---

Ship the current work through the Otta gate, then open the PR.

1. Make sure `.pr-body.md` is complete and honest:
   - Each acceptance criterion echoed with real evidence (test name, preview observation)
   - `idea_ref:` set to the real origin (e.g. `intercom:...`, `sentry:...`, or `issue:#N`)
   - `Fixes #<issue>` present
   - Either a test was added, or `[test-impractical: <reason>]` is in the body

2. Run the full local gate (mirrors the Otta Pulse merge gates — catches failures before CI):

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/otta-gate.sh"
   ```

   If it fails, fix what it reports and re-run. Do not push past a failing gate.

3. Once green, commit, push the branch, and open the PR using the seeded body verbatim:

   ```bash
   gh pr create --body-file .pr-body.md --title "<conventional-commit title>" $ARGUMENTS
   ```

   Use `--base staging` if the repo's `.selfloop.yml` names a staging branch; otherwise `--base main` (the default).

After merge + release tag, Pulse ingests the PR/tag webhooks automatically. The `idea_ref` + `Fixes #N` in the body are what let Pulse join the idea→issue→PR→version chain — no extra step needed.
