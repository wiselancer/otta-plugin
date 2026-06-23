# Changelog

All notable changes to the Otta plugin. Versions follow the plugin manifest.

## 0.5.0

- **Pipeline as a workflow** — `/otta:build <issue>` runs the TDD build → spec-review → verify → ship pipeline as a [dynamic workflow](https://code.claude.com/docs/en/workflows), orchestrating four specialist subagents (`builder`, `reviewer`, `qa`, `devops`). Ships only if the gate passed and every acceptance criterion passed.
- **Autonomous routine** — `/otta:schedule` sets up a cloud routine that runs the pipeline laptop-off.
- **Free LEARN-layer capture** — every gate run appends a `{score, feedback}` record to `~/.otta/ledger/<repo>.jsonl` (a file write, zero LM tokens), building the trainset for future GEPA prompt optimization.
- **Clean names** — commands `/otta:build|start|ship|setup|schedule`; agents `builder|reviewer|qa|devops` (namespace already scopes them).
- **Engine wiring** — workflow stages call the real otta scripts (seed / gate / capture) deterministically.
- First public distribution repo (extracted from the Otta monorepo).
