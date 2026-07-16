# Documentation Map

This directory holds the project harness and any product contract derived from a
user-provided spec.

## Main Files

- `HARNESS.md`: how humans and agents collaborate.
- `AGENT_WORKFLOW.md`: public work/approve/pause/doctor interface, durable stage machine, interruption recovery, role contracts, mailbox, and review independence.
- `FEATURE_INTAKE.md`: how prompts become tiny, normal, or high-risk work.
- `ARCHITECTURE.md`: architecture discovery and boundary rules.
- `TOOL_REGISTRY.md`: how external tools are registered and looked up.
- `TRACE_SPEC.md`: trace field reference (this project runs the lean profile).
- `TEST_MATRIX.md`: legacy proof map; current proof status is queried with
  `scripts/bin/harness-cli query matrix`.
- `HARNESS_BACKLOG.md`: legacy improvement list; current improvement records
  are stored with `scripts/bin/harness-cli backlog`.
- `GLOSSARY.md`: shared terms.

## Folders

- `product/`: current product truth, empty until a spec is derived.
- `stories/`: feature packets and backlog.
- `decisions/`: durable decisions and tradeoffs.
- `templates/`: reusable spec-intake, story, decision, and validation formats.

## Current State

A fresh harness exists before implementation. These docs define how the project
will grow; they do not imply that app code, tests, CI, or deployment automation
exist yet.
