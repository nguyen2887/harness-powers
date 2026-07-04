# Agent Instructions

Add project-specific agent instructions here.

<!-- HARNESS:BEGIN -->
## Harness

This repo uses Harness. Before work, read:

- `docs/HARNESS.md` — operating model, task loop, done definition
- `docs/FEATURE_INTAKE.md` — input types, risk lanes, classification rules
- `docs/ARCHITECTURE.md` — architecture discovery and boundary rules
- `scripts/bin/harness-cli query matrix` — current behavior-to-proof status

Use the Harness CLI at `scripts/bin/harness-cli` on macOS/Linux or
`.\scripts\bin\harness-cli.exe` on Windows as the main operational tool.
Before a step that could use an external tool, run
`scripts/bin/harness-cli query tools --capability <name> --status present`
to see what is equipped; an absent capability is a clean skip. See
`docs/TOOL_REGISTRY.md` for the registry model.
<!-- HARNESS:END -->
