# Otta — the self-learning AI software factory

A Claude Code plugin that turns any agent session into a self-improving software factory. The **Otta loop**:

```
issue → acceptance criteria → local gate → PR → ship → Otta Pulse (DORA + lifecycle)
```

It's the *discipline layer* of Otta. It needs no private engine and no secrets — just `gh` + `jq` and (optionally) the Otta Pulse GitHub App for metrics.

## Install

```
/plugin marketplace add wiselancer/otta
/plugin install otta
```

Then, once per repo:

```
/otta:setup
```

This installs a pre-push gate hook and walks you through installing the **Otta Pulse** GitHub App (interactive — GitHub requires your consent to install an App).

## Commands

| Command | Does |
|---|---|
| `/otta:start <issue>` | Seed `.pr-body.md` from a GitHub issue's acceptance criteria |
| `/otta:build <issue>` | Run the full TDD pipeline as a workflow: build → spec-review → verify → ship |
| `/otta:ship` | Run the local gate, then open the PR with the seeded body (manual ship) |
| `/otta:setup` | Install the pre-push gate hook + onboard the Pulse GitHub App |
| `/otta:schedule` | Set up a cloud routine that runs the pipeline autonomously (laptop-off) |

## The pipeline (`/otta:build`)

`/otta:build <issue>` runs a [dynamic workflow](https://code.claude.com/docs/en/workflows) that orchestrates four focused subagents — the plan lives in code, so it's repeatable and the stages can't be skipped:

1. **Build** — `builder` implements test-first (TDD)
2. **Spec Review** — `reviewer` checks every AC is met, nothing extra (one fix loop)
3. **Verify** — `qa` runs the gate and *adversarially* verifies each AC has real evidence
4. **Ship** — `devops` opens the PR — **only if** the gate passed and every AC passed

The subagents (`agents/*.md`) are reusable on their own — Claude delegates to them by name, and you can use them as agent-team teammates too.

## Autonomous (`/otta:schedule`)

`/otta:schedule` sets up a **cloud routine** (runs on Anthropic infra, laptop-off) that nightly picks a ready issue and runs the pipeline to a PR. Add GitHub (`pull_request.opened` → review) or API (`/fire` → Sentry-alert→fix) triggers from claude.ai/code/routines.

## LEARN-layer capture (free)

Every gate run appends a `{score, feedback}` record to a local ledger at `~/.otta/ledger/<repo>.jsonl` — a file write, **zero LM tokens**. With the plugin installed at user scope this accrues across **every project you push from**, building the trainset for future GEPA prompt optimization (ADR-0004) with no extra work. Opt out per-run with `OTTA_NO_CAPTURE=1`; relocate with `OTTA_LEDGER_DIR`.

## What the gate checks (local mirror of the Pulse merge gates)

- a ` ```acceptance ` fenced block in `.pr-body.md`
- a test in the diff, OR `[test-impractical: <reason>]`
- `Fixes #<issue>` — so the issue→PR link exists in GitHub
- `idea_ref:` — so Pulse can join idea → issue → PR → version

Failures surface **before** you push, not in CI. Bypass once with `OTTA_SKIP_GATE=1 git push`.

## How it connects to Otta Pulse

Pulse is the GitHub App that ingests your PR/CI/tag webhooks into an append-only event store and computes DORA metrics. This plugin doesn't talk to Pulse directly — it makes sure every PR body carries the `Fixes #N` + `idea_ref` linkage, which **Pulse already reads from the `pull_request` webhook**. No extra auth, no secret on your machine.

## Scope

This plugin is the discipline layer. The autonomous loop engine (scheduled `sense→score→govern→act→learn` runs) and direct lifecycle emission are separate components — see the Otta roadmap.
