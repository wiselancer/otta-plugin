# Otta — the self-learning AI software factory

> A Claude Code plugin that turns any agent session into a self-improving software factory.

[![validate](https://github.com/wiselancer/otta-plugin/actions/workflows/validate.yml/badge.svg)](https://github.com/wiselancer/otta-plugin/actions/workflows/validate.yml)
&nbsp;·&nbsp; [otta.build](https://otta.build)

Otta runs your work through a disciplined, test-first pipeline — **issue → acceptance criteria → build → review → verify → ship** — driven by specialist subagents, gated so nothing half-done reaches a PR, and **learning from its own outcomes** over time.

```
issue (with ACs) → /otta:start → /otta:build ─┬─ build  (TDD)
                                              ├─ spec-review (every AC met, nothing extra)
                                              ├─ verify (gate + adversarial per-AC evidence)
                                              └─ ship  (PR only if gate + all ACs pass)
                                                   ↓
                              every gate verdict → local ledger → self-improvement
```

## Install

```
/plugin marketplace add wiselancer/otta-plugin
/plugin install otta@otta        # choose user scope to use it everywhere
/reload-plugins
```

Then, once per repo:

```
/otta:setup        # installs the pre-push gate hook + onboards the Otta Pulse GitHub App
```

## Commands

| Command | Does |
|---|---|
| `/otta:start <issue>` | Seed `.pr-body.md` from a GitHub issue's acceptance criteria |
| `/otta:dev <issue>` | Run the pipeline **interactively** — the builder can ask you mid-build |
| `/otta:build <issue>` | Run the pipeline **autonomously** as a workflow (unattended, can't ask) |
| `/otta:ship` | Run the local gate, then open the PR with the seeded body (manual ship) |
| `/otta:setup` | Install the pre-push gate hook + onboard the Pulse GitHub App |
| `/otta:schedule` | Set up a cloud routine that runs the pipeline autonomously (laptop-off) |

## Two ways to run the pipeline

Same four stages, two drivers — pick by whether you want to stay in the loop:

| | `/otta:dev` — interactive | `/otta:build` — autonomous |
|---|---|---|
| Driver | the agent in your live session (Task subagents) | a detached [workflow](https://code.claude.com/docs/en/workflows) |
| Builder can ask you? | **yes** — pauses for your decisions mid-build | no — returns `blocked` with the reason |
| Best for | real dev, ambiguous specs, "help me decide" | clear specs, overnight, CI-triggered, unattended |

Both run the same `builder → reviewer → qa → devops` stages and open a PR only if the gate + every AC pass.

## The pipeline (`/otta:build`)

`/otta:build <issue>` runs a [dynamic workflow](https://code.claude.com/docs/en/workflows) orchestrating four focused subagents — the plan lives in code, so it's repeatable and the stages can't be skipped:

1. **Build** — `builder` implements test-first (TDD)
2. **Spec Review** — `reviewer` checks every AC is met, nothing extra (one fix loop)
3. **Verify** — `qa` runs the gate and *adversarially* verifies each AC has real evidence
4. **Ship** — `devops` opens the PR — **only if** the gate passed and every AC passed

The subagents (`agents/*.md`) are reusable on their own — Claude delegates to them by name, and they work as agent-team teammates too.

## The gate (local mirror of CI)

Failures surface **before** you push, not in CI:

- a ` ```acceptance ` fenced block in `.pr-body.md`
- a test in the diff, OR `[test-impractical: <reason>]`
- `Fixes #<issue>` — so the issue→PR link exists in GitHub
- `idea_ref:` — so the lifecycle can join idea → issue → PR → version

Bypass once with `OTTA_SKIP_GATE=1 git push`.

## Self-learning (free capture)

Every gate run appends a `{score, feedback}` record to `~/.otta/ledger/<repo>.jsonl` — a file write, **zero LM tokens**. Installed at user scope, this accrues across every project you push from, building the trainset that later optimizes the pipeline's own prompts (via [GEPA](https://arxiv.org/abs/2507.19457)) with no extra work. Opt out per-run with `OTTA_NO_CAPTURE=1`; relocate with `OTTA_LEDGER_DIR`.

## Otta Pulse (optional)

This plugin makes sure every PR body carries the `Fixes #N` + `idea_ref` linkage, which the **Otta Pulse** GitHub App reads from the `pull_request` webhook to compute DORA metrics and the idea → production-version chain. The plugin needs no secret; install the App separately when you want metrics.

## Scope & boundaries

This repo is the **client-side discipline + pipeline** — open source, free to use. The Otta Pulse App (server-side measurement and merge-gate enforcement) and any data-tuned/optimized prompts are served separately and are not part of this repo.

## License

MIT © Sam Petrenko
