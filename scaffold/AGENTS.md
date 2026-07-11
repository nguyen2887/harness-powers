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

External reviewer boundary:

- If you are invoked only to review a plan, diff, or evidence packet, do not run
  `harness-cli`, query or modify `harness.db`, update stories/traces/backlog, or
  run project verification commands.
- Review only the provided plan/diff/spec/verification evidence. You may read
  repository files needed to understand the reviewed artifact.
- If required evidence is missing, report that as a review finding instead of
  reconstructing Harness state yourself.
<!-- HARNESS:END -->
<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses a durable, role-based Harness stage machine. Read
`docs/AGENT_WORKFLOW.md` before change work.

Messages beginning with `/work` or `work` MUST use the `work` skill/resolver.
Messages beginning with `/approve` or `approve` MUST use the `approve` skill.
The human supplies a description or task id, never a role, model, provider, pane,
or stage. Resolve those from `.harness-powers/runtime/tasks/`.

Every change starts with intake. Each invocation persists a separate artifact
for every stage, but auto-chains consecutive same-role stages. Stop only for a
role/review/human boundary, blocker, clarification, closed task, or safety
budget. Never ask the human to invoke the next same-role stage, copy a handoff,
or launch another CLI, pane, Task, or sub-agent as an implicit transition.

Roles are `context-worker`, `design-authority`, `implementation-worker`,
`technical-reviewer`, `closer`, and `human`. They are capability contracts, not
bindings to specific models or providers. A single session may perform several
roles sequentially, but plan/code review should use a session independent of the
artifact author; explicit self-review must be recorded as degraded independence.

Only close may claim completion. Code edits for normal/high-risk stories remain
blocked until the explicit human freeze records a reviewer approval beginning
`plan-review passed:`. Code approval separately begins `code-review passed:`.

Build runs targeted inner-loop checks. Verify runs final acceptance and broader
checks. Tiny mechanical work may use `review_policy: skip-mechanical` only when
it changes no executable behavior and has no risk flags; all other work requires
independent code review.

Detailed procedures live in the installed skills. If this runtime does not
support slash or skill invocation, plain `work <description-or-task-id>` and
`approve <task-id>` are the portable entrypoints.
<!-- HARNESS-POWERS:END -->
