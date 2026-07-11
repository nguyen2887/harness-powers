---
name: approve
description: Use only when the human explicitly invokes /approve or says approve with a task id for a Harness task awaiting human-freeze. Verify the reviewed frozen plan, record the stage-specific plan approval, advance the mailbox to prepare, and stop. Never infer durable approval from vague agreement.
---

# Human Freeze Approval

Treat this invocation as an explicit durable approval, never as a general chat
acknowledgment.

1. Run `.harness-powers/bin/harness-powers-workflow show <task-id>` and require
   `stage: human-freeze`.
2. Read the latest mailbox artifact, frozen story/design/plan, reviewer verdict,
   residual Minor findings, and verify command. If anything is missing, refuse.
3. Require a story id. Record the human freeze first, then the separate review
   gate so code cannot unlock before human approval exists:
   `harness-cli intervention add --story <story-id> --type approval
   --source human --description "human-freeze approved: <artifact>"`, then
   `harness-cli intervention add --story <story-id> --type approval
   --source reviewer --description "plan-review passed: <reviewer>; <artifact>"`.
4. Run `.harness-powers/bin/harness-powers-workflow approve <task-id>`.
5. Report that the task is ready for `work <task-id>`; do not choose a model or pane.
