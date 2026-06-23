---
name: shipping-loop
description: Use when building, fixing, or shipping any change to a GitHub repo — the Otta loop (issue → acceptance criteria → local gate → PR → ship) that makes work traceable end-to-end and feeds DORA + lifecycle metrics to Otta Pulse. Runs FIRST, before debugging or other skills.
---

# The Otta Shipping Loop

Every change is traceable from the idea that prompted it to the version that shipped it. The loop makes that automatic. It runs **first** — before debugging, before writing code. Even for an urgent one-line fix: issue first, then the fix.

## Why

**Prompts drift, gates don't.** An intent pasted in chat degrades as it passes builder → reviewer → deploy. A fenced acceptance block does not — it's the same text the builder implements against, the reviewer checks, and the PR body echoes as evidence. And the linkage keys (`Fixes #N`, `idea_ref`) are what let Otta Pulse join idea → issue → PR → version without anyone wiring it by hand.

## The loop

```
issue (with ACs) → /otta:start → build (TDD) → /otta:ship (gate) → PR → merge → Pulse
```

1. **Issue first.** Find or create a GitHub issue with acceptance criteria as `- [ ]` checkboxes. Each AC must be falsifiable — if you can't name the check that proves it, rewrite it or move it to Out of scope. "Make it better" is not an AC.

2. **`/otta:start <issue>`.** Seeds `.pr-body.md` from the issue's ACs with the canonical acceptance block. If the issue has no checkboxes, stop and get real ACs added first.

3. **Build, test-first.** Write the smallest failing test that captures the intended behavior, make it pass, keep the `.pr-body.md` Verification section honest as you go. Typecheck is not test coverage.

4. **`/otta:ship`.** Runs the local gate (mirrors the Pulse merge gates), then opens the PR with the seeded body. The body must carry:
   - a ` ```acceptance ` fenced block
   - a test in the diff, OR `[test-impractical: <reason>]`
   - `Fixes #<issue>` — the GitHub issue number, so the issue→PR link exists in GitHub
   - `idea_ref:` — where the work came from (`intercom:...`, `sentry:...`, `issue:#N`)

5. **Merge → ship.** After merge + release tag, Pulse ingests the PR/tag webhooks automatically. The `Fixes #N` + `idea_ref` in the body close the idea→version chain. Nothing else to do.

## Setup (once per repo)

Run `/otta:setup` — installs the pre-push gate hook and walks through installing the Otta Pulse GitHub App. A pushed change that skips the loop fails the gate locally before it ever reaches CI.

## Rules

- Issue before code, always — even urgent fixes.
- An AC that can't become a check isn't an AC.
- Don't push past the gate. Fix what it reports. (`OTTA_SKIP_GATE=1` exists for genuine emergencies — declare why.)
- `Fixes #<issue>` (GitHub), not only a tracker id — the GitHub link is what Pulse and reviewers join on.
- Keep `idea_ref` real, not a placeholder.
