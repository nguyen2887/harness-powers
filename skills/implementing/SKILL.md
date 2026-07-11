---
name: implementing
description: Internal implementation procedure dispatched by harness-powers:work for prepare or reconcile. Implement test-first, reconcile mailbox findings, write the stage artifact, and advance to verify, contract, or close. Never review your own artifact or claim completion.
---

# Implementation Worker

Own product-code writes for the assigned story and stage only.

**Announce at start:** "Using harness-powers:implementing for the assigned implementation stage."

## Boundary

- Only one implementation worker may write a story at a time.
- Never work on main/master without explicit consent.
- Never change the frozen contract or design. Return such findings to the design authority.
- Never perform final review of your own code or launch a reviewer.

## Prepare

1. Verify the handoff paths. Normal/high-risk work also requires the frozen
   plan, plan-review verdict, and verify command. Tiny work requires its intake
   and context-lite packet; declare the narrow verification command before edits.
2. Create a branch. Multiple panes may share this checkout because the mailbox
   enforces a single product-code writer; do not create an isolated worktree
   unless the project has explicitly configured a shared Harness control plane.
3. Record the base commit and run the narrow baseline check. A failing baseline
   enters debugging before product changes.

## Build

For every behavior, use Red -> Green -> Refactor:

1. Write the smallest failing test and observe the intended failure.
2. Write the minimum production change.
3. Run the targeted test and relevant suite.
4. Refactor while green and commit at coherent checkpoints.

Pure docs/config/copy work may use the relevant check instead of a new test.
Follow the frozen plan in order. Record proof flags only for checks actually run
and observed passing. Stop when reality contradicts the plan or requires a new
design decision.

When the build meets the frozen criteria, write base commit, changed paths,
story path, tests, and verify command to the supplied mailbox artifact, then run:

`workflow advance <task> <actor> prepare verify implementation-worker <artifact>`.

Do not claim completion.

## Reconcile

When a code-review verdict returns:

1. Falsify or confirm each finding against the code and contract.
2. Critical/Important: add or update the failing test, fix, then return to verify.
3. Minor: fix or reject with a technical reason.
4. If a finding changes contract/design, write the evidence to the mailbox and
   advance `reconcile -> contract` with required role `design-authority`.
5. Re-review only changed hunks and unresolved findings.
6. Code changes: write resolutions and changed paths to the artifact, then run
   `workflow advance <task> <actor> reconcile verify implementation-worker <artifact>`.
7. Approved without further code changes:
   - story-backed work: record `code-review passed:` with `--source reviewer`,
     referencing the mailbox verdict and reviewer actor;
   - write the final verdict and resolutions to the artifact;
   - run `workflow advance <task> <actor> reconcile close closer <artifact>`.

Report only the task id and next stage. Never print a handoff for the human to copy.
