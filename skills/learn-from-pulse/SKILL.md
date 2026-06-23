---
name: learn-from-pulse
description: Use BEFORE implementing an issue or starting a build/loop on a repo that uses Otta Pulse — consults the idea's history (shipped issues/PRs/versions, escaped defects, prior loop verdicts) so you don't repeat a failure the loop already learned about. Runs after shipping-loop, before the builder writes code.
---

# Learn From Pulse

The ledger and Pulse record every loop's verdict and every defect that escaped. This skill **closes the loop in-session**: before you build, you check what the factory already knows about this idea, so a failure caught (or missed) once isn't repeated.

## When

Right after `shipping-loop` establishes the issue + `idea_ref`, and **before** the builder writes code. Skip only if Pulse isn't configured (no `OTTA_PULSE_URL`) — then proceed without it; the loop still works, it just doesn't learn yet.

## How

1. **Find the `idea_ref`.** It's in `.pr-body.md` (the `idea_ref:` line) or the issue/epic body. No `idea_ref` yet → there's no history to consult; continue.

2. **Ask Pulse what it knows** (best-effort — a failed/slow call must never block the build):
   ```bash
   curl -fsS -m 5 "${OTTA_PULSE_URL%/}/idea?ref=<idea_ref>" \
     -H "x-pulse-token: ${OTTA_PULSE_TOKEN}" | jq .
   ```
   You get back: `items` (shipped issues → PRs → versions), `defects` (issues reopened + PRs reverted traced to this idea), `verdicts` (loop pass/fail counts on this idea's branches).

3. **Act on it before building:**
   - **`defects.total > 0`** → an earlier change on this idea came back (reopened/reverted). Find that issue/PR, read *why* it failed, and make this change not reintroduce it. State the prior failure in `.pr-body.md` and add an AC that guards against it.
   - **`verdicts.fail > 0`** → the loop has rejected work here before. Check the `loop_verdict` feedback (gate/reviewer/qa) for the failing branch and pre-empt the same gap — most often a missing test for an AC.
   - **`items`** → see what already shipped for this idea so you build the *next* slice, not a duplicate. Respect the epic's merge order.

4. **Record what you learned** in `.pr-body.md` (one line: "Prior escape: #N reopened for X — guarded by ACk"). That note becomes part of the PR, so the next loop sees it too.

## Why

Offline GEPA optimization needs data to accrue first. This is the **online** half: cheap, deterministic, every loop — the agent reads the grades it already produced and doesn't walk into a known wall. The factory gets a little less wrong each run, not just at the next retrain.

If `OTTA_PULSE_URL`/`OTTA_PULSE_TOKEN` aren't set, or the call returns nothing, that's fine — proceed and let the ledger keep accruing for later.
