---
name: done
description: Internal closer procedure dispatched by work at close. Require fresh verification and approved code review, perform durable story and trace bookkeeping, persist the close report, and advance the mailbox to closed.
---

# Close Stage

Use the task id, actor id, latest artifact, and close artifact path supplied by
the `work` resolver. Reject the stage if fresh passing verification, an approved
code-review verdict, finding resolutions, changed paths, or required ids are missing.

1. Story-backed work: update proof flags and run
   `harness-cli story update --id <story> --status implemented`. Confirm the
   `code-review passed:` reviewer intervention.
2. Record the lean trace. Tiny work may use summary and outcome only; normal and
   high-risk work includes intake, story, changed paths, and friction.
3. Record unresolved Harness friction with `harness-cli backlog add`.
4. Write the final outcome, exact verification evidence, review rounds, finding
   resolutions, changed paths, and unattempted work to the supplied close artifact.
5. Run `workflow advance <task> <actor> close closed none <artifact>`.

Only this stage may claim completion. Integration actions such as merge, PR, or
push still require the human's separate instruction.
