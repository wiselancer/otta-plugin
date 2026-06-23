# Changelog

All notable changes to the Otta plugin. Versions follow the plugin manifest.

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
