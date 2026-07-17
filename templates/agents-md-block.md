<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses a durable, role-based Harness stage machine. Read
`docs/AGENT_WORKFLOW.md` before change work.

Messages beginning with `/work` or `work` MUST use the `work` skill/resolver.
Messages beginning with `/approve` or `approve` MUST use the `approve` skill.
Messages beginning with `/pause` or `pause` MUST use the `pause` skill.
Messages beginning with `/doctor` or `doctor` MUST use the read-only `doctor` skill.
The human supplies a description or task id, never a role, model, provider, pane,
or stage. Resolve those from `.harness-powers/runtime/tasks/`.

Every change starts with intake. Each invocation persists a separate artifact
for every stage, but auto-chains consecutive same-role stages. Stop only for a
role/review/human boundary, blocker, clarification, closed task, or safety
budget. Never ask the human to invoke the next same-role stage, copy a handoff,
or launch another CLI, pane, Task, or sub-agent as an implicit transition.

Plan/code review is conversational but remains independent. The reviewer first
writes a read-only draft, checkpoints without advancing, and discusses it with
the human in the reviewer conversation. Only the settled final verdict advances
the task; then the human switches to the designer/implementer pane and invokes
`work <task-id>`. Chat conclusions must be persisted before that handoff.

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
`approve <task-id>` are the portable entrypoints. Use `pause <task-id>` before
switching sessions during a stage; a new session resumes with `work <task-id>`.
At `human-freeze`, questions leave state unchanged; an explicit objection is
persisted and returns to design. Only explicit `approve` unlocks implementation.
<!-- HARNESS-POWERS:END -->
