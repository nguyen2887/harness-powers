---
name: verifying
description: Internal implementation-worker procedure dispatched by harness-powers:work at verify. Run fresh mechanical verification, persist exact evidence in the task mailbox, and advance to code-review or debugging. Never review or claim completion.
---

# Verification Stage

**Announce at start:** "Using harness-powers:verifying to collect fresh evidence."

Use the task id, actor id, story id, and mailbox artifact path supplied by the
`work` resolver. Read the latest artifact before running anything.

1. Story-backed work: run `harness-cli story verify <id>`. Tiny work without a
   story: run the narrow relevant checks directly.
2. Read complete output and exit status. Run every broader check required by the
   story validation table; record proof flags only for layers observed passing.
3. Gather `git status --short`, base commit, diff stat, diff, exact commands, and
   exact outcomes in the supplied mailbox artifact.
4. On success, inspect `review_policy`:
   - `skip-mechanical`: run
     `workflow advance <task> <actor> verify close closer <artifact>`;
   - otherwise run
     `workflow advance <task> <actor> verify code-review technical-reviewer <artifact>`.
5. On failure, include the full failure and reproduction in the artifact, then run:
   `workflow advance <task> <actor> verify debugging implementation-worker <artifact>`.

After reconciliation changes code, repeat verification with fresh output. Return
control to the `work` resolver; it decides whether to continue or stop. Never
print a packet for the human to copy.
