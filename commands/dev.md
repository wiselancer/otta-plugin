---
description: Run the Otta pipeline interactively (developer-in-the-loop) — the builder can ask you mid-build
argument-hint: <issue-number>
---

Run the Otta shipping pipeline for issue **#$1** **interactively, in this session** — so you can answer questions and give direction while it builds. (For an autonomous, unattended run that can't ask you, use `/otta:build` instead.)

**Do NOT use the Workflow tool.** Run the four stages yourself, dispatching each subagent via the Task tool, and **pause to involve the developer whenever a stage needs a decision.** That ability is the whole point of this mode.

1. **Seed.** If `.pr-body.md` is missing, run:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/seed-pr-body.sh" $1`
   Read it. If the issue has no acceptance criteria, ask the developer to add them before continuing.

2. **Build.** Dispatch the `otta:builder` subagent to implement test-first against the ACs. **If the builder returns a question, NEEDS_CONTEXT, or a real design decision, surface it to the developer, get the answer, then re-dispatch the builder with it.** Do not guess on the developer's behalf for genuine decisions.

3. **Spec Review.** Dispatch `otta:reviewer`. If it reports gaps, send them to the builder (ask the developer first if a gap is ambiguous), then re-review.

4. **Verify.** Dispatch `otta:qa` to run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/otta-gate.sh"` (this also captures the verdict to the LEARN ledger) and adversarially verify each AC. If a gate or AC fails, surface it — fix with the builder, or ask the developer how to proceed.

5. **Ship.** Only when the gate passed and every AC passed: dispatch `otta:devops` to commit and `gh pr create --body-file .pr-body.md`. Confirm the PR target (staging vs main) with the developer if unsure.

Throughout: **when in doubt, ask — don't assume.** Report the result at the end (PR URL, or where you stopped and why).
