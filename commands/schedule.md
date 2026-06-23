---
description: Set up a cloud routine that runs the Otta pipeline autonomously on a schedule (laptop-off)
---

Set up an autonomous Otta routine. Routines run as Claude Code cloud sessions on Anthropic infrastructure, so they keep working when this machine is closed.

Invoke the `/schedule` skill to create a **nightly dev-loop routine** for this repository, using this prompt verbatim as the routine's instructions:

> Pick the highest-priority open GitHub issue in this repo that has an acceptance block (a ` ```acceptance ` fenced block or `- [ ]` AC checkboxes) and no open PR. Run the Otta shipping pipeline on it: seed `.pr-body.md` from its acceptance criteria, implement test-first, verify against the project gate and every AC, and open a PR (`Fixes #N` + an `idea_ref`) targeting `staging` if `.selfloop.yml` names one, else `main`. Open at most one PR. If no suitable issue exists, do nothing. Never merge.

Default schedule: **weeknights**. Confirm the cadence, repository, and environment with the user before saving (the routine commits and opens PRs as them).

Other useful triggers the user can add on the routine's page at claude.ai/code/routines:
- **GitHub `pull_request.opened`** → an Otta review routine (apply the acceptance-gate review checklist, comment inline).
- **API `/fire`** → wire Sentry/alerting to open a fix-PR from a stack trace.

Tell the user routines need Claude Code on the web enabled and count against their daily routine cap.
