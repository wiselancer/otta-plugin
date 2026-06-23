---
description: Start work on a GitHub issue the Otta way — seed .pr-body.md with acceptance criteria
argument-hint: <issue-number>
---

Start the Otta shipping loop for issue **#$1**.

1. Run the bundled seeder to create `.pr-body.md` from the issue's acceptance criteria:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/seed-pr-body.sh" $1 --force
   ```

2. Read the seeded `.pr-body.md`. If the issue had no `- [ ]` acceptance checkboxes, the AC block is a placeholder — **stop and ask the user to add testable acceptance criteria to the issue first**, then re-run. ACs that can't become a check aren't ACs.

3. Confirm the plan with the user in one or two lines: what you'll build, and which acceptance criteria it satisfies.

Then begin implementing — write the smallest failing test first (TDD), implement, keep the `.pr-body.md` Verification section honest as you go. When ready to push, use `/otta:ship`.
