---
name: reviewing
description: Internal technical-review procedure dispatched by harness-powers:work for plan-review or code-review. Read mailbox artifacts and repository evidence, write only the structured verdict artifact to the mailbox, advance state, and stop. Never run harness-cli, project verification, or edit product/docs.
---

# Technical Review

Review one artifact boundary independently.

**Announce at start:** "Using harness-powers:reviewing in read-only mode."

## Hard Boundary

- Never run `harness-cli` or modify `harness.db`.
- Never run project verification; assess the supplied fresh evidence.
- Never edit the plan, code, tests, or docs. The only allowed write is the
  supplied mailbox verdict artifact under `.harness-powers/runtime/`.
- Never launch another CLI, agent, or reviewer.
- Read additional repository files only to understand or verify a specific claim.
- Missing required evidence is a finding, not permission to reconstruct it.

## Plan Review

Check the contract, design, plan, and verify command for missing requirements,
contradictions, untestable acceptance criteria, hidden risks, wrong sequencing,
scope creep, and unsupported assumptions.

## Code Review

Check the story/contract, diff, and verification evidence for correctness bugs,
spec deviations, missing tests, security issues, silent behavior changes, and
evidence that does not actually cover the changed behavior.

## Output

Write the `review` schema from `docs/AGENT_WORKFLOW.md` to the supplied mailbox
artifact. Every finding needs a
specific claim, severity, evidence, and reason. Do not add praise or general
summaries. Use `approved` only when there are no Critical/Important findings;
Minor findings may remain if they are explicit.

Advance using the current mailbox stage:

- plan: `workflow advance <task> <actor> plan-review freeze design-authority <artifact>`
- code: `workflow advance <task> <actor> code-review reconcile implementation-worker <artifact>`

Return control to the `work` resolver. It stops at the role boundary and reports
only the task id, verdict, and that `work <task>` may resume; the artifact owner
reads the verdict from the mailbox.
