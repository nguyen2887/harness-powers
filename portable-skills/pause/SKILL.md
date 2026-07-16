---
name: pause
description: Use when the human says pause, checkpoint, hand off, or switch agent for an active Harness task. Persist interrupted stage state and dirty-tree evidence in the shared mailbox, then release the claim so another CLI or session can safely resume with work.
---

# Pause Harness Work

Checkpoint an active stage without advancing it.

1. Require a task id and run `workflow show <task-id>`.
2. Reuse the invocation's stable actor id and require that actor to own the claim.
3. Request a mailbox artifact with
   `workflow artifact <task> <actor> checkpoint`.
4. Record the current stage, latest completed artifact, frozen plan/base commit,
   completed and pending work, wrapper and affected nested-repo `git status`,
   changed paths, commands already run, partial failures, and unresolved risks.
5. Run `workflow pause <task> <actor> <checkpoint-artifact>`.
6. Report only the task id, unchanged stage, and that `work <task-id>` may resume
   from any supported session.

Never advance the stage, discard dirty work, or force-release another live
actor. If this actor does not own the claim, show the owner and expiry and stop.
