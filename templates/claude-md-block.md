<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses the durable role-based workflow in `docs/AGENT_WORKFLOW.md`.

- New or resumed work enters through `/work <description-or-task-id>`.
- Explicit plan freeze enters through `/approve <task-id>`.
- Mid-stage session switches enter through `/pause <task-id>`.
- `/doctor` is a read-only installation, trust, hook, and active-task check.
- Plain `work`, `approve`, `pause`, and `doctor` are equivalent portable triggers;
  namespaced plugin commands are optional aliases, not a runtime dependency.
- Repository-vendored `.claude/skills/<entry>/SKILL.md` is the current native
  adapter. Its `.agents/skills/` twin is the cross-runtime contract; a cached
  plugin adapter must not override newer repository state.
- The human never needs to name a role, model, provider, pane, or stage.
- Each invocation writes a separate artifact per stage and auto-chains safe
  consecutive same-role stages. Stop at role/review/human or safety boundaries.
  Never ask the human to invoke the next same-role stage or copy a handoff.
- A paused stage records a dirty-tree checkpoint and releases its claim; resume
  it from any supported session with `work <task-id>`.
- Do not implicitly launch another CLI, pane, Task, or sub-agent.
- Plan/code review should use a session independent of the artifact author;
  explicit self-review is recorded as degraded independence.
- Only the `done` stage skill may claim completion.
- Tiny mechanical work may skip independent code review only when it changes no
  executable behavior and has no risk flags.

Precedence: harness-powers replaces Superpowers process skills in this repo.
Utility skills remain available when they do not bypass Harness boundaries.
<!-- HARNESS-POWERS:END -->
