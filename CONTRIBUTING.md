# Contributing

Thanks for your interest in the Otta plugin.

## Source of truth

This repo is the **public distribution** of the Otta plugin. The canonical source
lives in the private Otta monorepo and is synced here on release. PRs against this
repo are welcome for the plugin's public surface (commands, subagents, scripts,
docs); they're reviewed and folded back into the monorepo.

## Layout

```
.claude-plugin/   plugin.json + marketplace.json
agents/           the pipeline subagents (builder, reviewer, qa, devops)
commands/         /otta:build|start|ship|setup|schedule
workflows/        otta-build.mjs — the pipeline orchestration
scripts/          seed / gate / ledger-append / pulse-install
hooks/            pre-push gate guard
skills/           the shipping-loop discipline
tests/            shell self-tests
```

## Before opening a PR

- `bash tests/ledger-append.test.sh` passes
- JSON manifests parse (`python3 -c "import json,sys; json.load(open(f))"`)
- agents have `name:` + `description:` frontmatter; commands have `description:`
- the `validate` workflow is green

## Scope

This plugin is the client-side discipline + pipeline. The Otta Pulse GitHub App
(measurement, DORA, merge gates) and any data-tuned/optimized prompts are served
separately — they are intentionally not part of this repo.
