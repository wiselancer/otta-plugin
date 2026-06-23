---
description: Run the Otta TDD shipping pipeline (build → spec-review → verify → ship) for an issue as a workflow
argument-hint: <issue-number>
---

Run the Otta shipping pipeline for issue **#$1** as a dynamic workflow.

First make sure the workspace is seeded — if `.pr-body.md` doesn't exist yet, run `/otta:start $1` to seed the acceptance criteria.

Then invoke the **Workflow** tool with the bundled pipeline script (this is an explicit, user-invoked opt-in to orchestration):

```
Workflow({
  scriptPath: "${CLAUDE_PLUGIN_ROOT}/workflows/otta:build.mjs",
  args: { issue: "$1", pluginRoot: "${CLAUDE_PLUGIN_ROOT}" }
})
```

`pluginRoot` lets each stage call the real otta engine scripts (`seed-pr-body.sh`, `otta-gate.sh` — which also captures the verdict to the LEARN ledger) instead of generic instructions.

The workflow runs four stages, each a focused subagent:
1. **Build** — `builder` implements test-first (TDD)
2. **Spec Review** — `reviewer` checks every AC is met, nothing extra (one fix loop)
3. **Verify** — `qa` runs the gate and adversarially verifies each AC has real evidence
4. **Ship** — `devops` opens the PR (`Fixes #N` + `idea_ref`) — **only if** the gate passed and every AC passed

When it finishes, report the result: shipped (PR URL) or blocked (which AC/gate failed). The pipeline never opens a PR for work that didn't pass verify.
