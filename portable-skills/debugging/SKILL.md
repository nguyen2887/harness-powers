---
name: debugging
description: Internal evidence-first interrupt dispatched by work at debugging. Prove the root cause, persist the diagnosis or verified fix in the task mailbox, and return to verify or contract/design escalation.
---

# Debugging Interrupt

Use the task id, actor id, latest artifact, and new mailbox artifact path supplied
by the `work` resolver.

1. Observe the complete error, command, environment, expected result, and actual result.
2. Establish the smallest reliable reproduction.
3. Localize where reality first diverges and state one falsifiable hypothesis.
4. Run the smallest refuting experiment. After 2-3 refuted hypotheses, stop;
   persist the evidence and request technical review instead of guessing.
5. For a confirmed bug, first observe a failing regression test, make the minimum
   root-cause fix, and rerun the reproduction, regression, and narrow relevant checks.
6. Write all evidence, changed paths, and unresolved risks to the supplied artifact.

Advance exactly one boundary:

- verified fix: `debugging -> verify`, role `implementation-worker`;
- contract/design cause: `debugging -> contract`, role `design-authority`;
- exhausted investigation: `debugging -> contract`, role `design-authority`, with
  the refuted hypotheses and missing mental model called out explicitly.

Use `workflow advance` for the transition. Record Harness gaps with
`harness-cli backlog add`. Return control to the `work` resolver after advance;
do not print a human-copy handoff or launch another actor.
