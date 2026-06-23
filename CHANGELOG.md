# Changelog

All notable changes to the Otta plugin. Versions follow the plugin manifest.

## 0.8.4

- **`learn-from-pulse` skill — close the loop in-session.** A second skill that fires before the builder writes code: it queries Pulse `GET /idea?ref=<idea_ref>` for the idea's history (shipped issues/PRs/versions, escaped defects, prior loop verdicts) and acts on it — guard against a prior escape, pre-empt a prior gate failure, build the next slice not a duplicate. The *online* half of learning (offline GEPA needs data to accrue first). Best-effort: no `OTTA_PULSE_URL` or no data → proceed.

## 0.8.3

- **Stream loop verdicts to Pulse.** When `OTTA_PULSE_URL` + `OTTA_PULSE_TOKEN` are set, `ledger-append.sh` also pushes each gate/reviewer/qa verdict as a `loop_verdict` event to the Pulse server, so loop grades land next to CI/deploy/defect data (the local ledger jsonl can't be read server-side). Best-effort — time-boxed, failures swallowed, never blocks a gate; `external_id` matches `pulse ingest-ledger` so push + batch-import don't double-count.

## 0.8.2

- **`otta-worktree.sh --prune [hours]`.** GC for orphaned worktrees left by a run that died before DevOps tore its worktree down. Removes worktrees in `~/.otta/worktrees` older than the threshold (default 24h). Age is the safe signal — pipelines take minutes, and it survives squash-merge branch deletion; an in-flight run is never touched. Run manually or on a schedule.

## 0.8.1

- **Harden worktree teardown.** `otta-worktree.sh --remove` is invoked by DevOps from *inside* the worktree being removed. Fixed three issues that left a dangling worktree: a cwd-dependent repo slug (now resolved via the main worktree, stable from any linked checkout), `git worktree remove` refusing the current directory (now steps out first), and macOS path resolution (`/var`→`/private/var`). Regression test now exercises removal from inside the worktree.

## 0.8.0

- **Reviewer/QA verdict capture.** The `reviewer` and `qa` agents now append their verdict to the LEARN ledger (`--source reviewer|qa`), not just the deterministic gate. This records the per-AC compliance + adversarial reasoning — the richest GEPA training signal — at zero LM tokens.
- **Worktree isolation.** Each pipeline run executes in a physically separate `git worktree` off the base branch (`scripts/otta-worktree.sh`), so a run can never touch the session's branch or files. Deterministic path → every stage re-derives the same checkout; DevOps tears it down after the PR. Falls back to in-place branch-off-base when worktrees are unavailable. Hardens the v0.7.0 clean-base fix.

## 0.7.0

- **Clean-base pipeline.** The build stage now branches off the base (default or staging) before implementing, and DevOps verifies the branch contains only this issue's commits before opening the PR — no more PRs dragging unrelated commits from the session's current feature branch.

## 0.6.0

- **`/otta:dev` — interactive mode.** Runs the same build → review → verify → ship pipeline in your live session (via Task subagents) so the **builder can ask you mid-build** and you can give direction. `/otta:build` stays the autonomous, detached workflow. Two drivers, one engine.

## 0.5.0

- **Pipeline as a workflow** — `/otta:build <issue>` runs the TDD build → spec-review → verify → ship pipeline as a [dynamic workflow](https://code.claude.com/docs/en/workflows), orchestrating four specialist subagents (`builder`, `reviewer`, `qa`, `devops`). Ships only if the gate passed and every acceptance criterion passed.
- **Autonomous routine** — `/otta:schedule` sets up a cloud routine that runs the pipeline laptop-off.
- **Free LEARN-layer capture** — every gate run appends a `{score, feedback}` record to `~/.otta/ledger/<repo>.jsonl` (a file write, zero LM tokens), building the trainset for future GEPA prompt optimization.
- **Clean names** — commands `/otta:build|start|ship|setup|schedule`; agents `builder|reviewer|qa|devops` (namespace already scopes them).
- **Engine wiring** — workflow stages call the real otta scripts (seed / gate / capture) deterministically.
- First public distribution repo (extracted from the Otta monorepo).
