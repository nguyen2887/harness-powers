---
name: done
description: Internal closer procedure dispatched by harness-powers:work at close. Require fresh verification plus either approved code review or a valid tiny-mechanical exception, perform durable bookkeeping, persist the close report, and advance to closed.
---

# Close Stage

**Announce at start:** "Using harness-powers:done to close verified, policy-compliant work."

Use the task id, actor id, latest artifact, and close artifact path supplied by
the `work` resolver. Always require fresh passing verification, changed paths,
and required ids. When `review_policy` is `required`, also require an approved
code-review verdict and finding resolutions. When it is `skip-mechanical`,
require proof that the task is tiny, risk-free, and changes no executable behavior.

1. Story-backed work: update proof flags and run
   `harness-cli story update --id <story> --status implemented`. For required
   review, confirm the `code-review passed:` reviewer intervention.
2. Record the lean trace. Tiny work may use summary and outcome only; normal and
   high-risk work includes intake, story, changed paths, and friction.
3. Record unresolved Harness friction with `harness-cli backlog add`.
4. Write the final outcome, exact verification evidence, review rounds, finding
   resolutions, changed paths, and unattempted work to the supplied close artifact.
5. Run `workflow advance <task> <actor> close closed none <artifact>`.

Only this stage may claim completion. Integration actions such as merge, PR, or
push still require the human's separate instruction. Return the closed state to
the `work` resolver for the final report.
