<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses a durable, role-based Harness stage machine. Read
`docs/AGENT_WORKFLOW.md` before change work.

Messages beginning with `/work` or `work` MUST use the `work` skill/resolver.
Messages beginning with `/approve` or `approve` MUST use the `approve` skill.
The human supplies a description or task id, never a role, model, provider, pane,
or stage. Resolve those from `.harness-powers/runtime/tasks/`.

Every change starts with intake. Each invocation claims and executes only the
current stage, persists its artifact in the shared mailbox, advances one
boundary, and stops. Never ask the human to copy a handoff or launch another CLI,
pane, Task, or sub-agent as an implicit workflow transition.

Roles are `context-worker`, `design-authority`, `implementation-worker`,
`technical-reviewer`, `closer`, and `human`. They are capability contracts, not
bindings to specific models or providers. A single session may perform several
roles sequentially, but plan/code review should use a session independent of the
artifact author; explicit self-review must be recorded as degraded independence.

Only close may claim completion. Code edits for normal/high-risk stories remain
blocked until the explicit human freeze records a reviewer approval beginning
`plan-review passed:`. Code approval separately begins `code-review passed:`.

Detailed procedures live in the installed skills. If this runtime does not
support slash or skill invocation, plain `work <description-or-task-id>` and
`approve <task-id>` are the portable entrypoints.
<!-- HARNESS-POWERS:END -->
