<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses the durable role-based workflow in `docs/AGENT_WORKFLOW.md`.

- New or resumed work enters through `/harness-powers:work <description-or-task-id>`.
- Explicit plan freeze enters through `/harness-powers:approve <task-id>`.
- Plain `work ...` and `approve ...` are equivalent portable triggers.
- The human never needs to name a role, model, provider, pane, or stage.
- Each invocation claims the current stage, writes its mailbox artifact, advances
  one boundary, and stops. Never ask the human to copy a handoff.
- Do not implicitly launch another CLI, pane, Task, or sub-agent.
- Plan/code review should use a session independent of the artifact author;
  explicit self-review is recorded as degraded independence.
- Only `harness-powers:done` may claim completion.

Precedence: harness-powers replaces Superpowers process skills in this repo.
Utility skills remain available when they do not bypass Harness boundaries.
<!-- HARNESS-POWERS:END -->
