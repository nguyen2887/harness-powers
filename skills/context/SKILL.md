---
name: context
description: Internal context procedure dispatched by harness-powers:work. Discover source-of-truth documents, affected boundaries, current behavior, risks, and unknowns read-only, write the context artifact to the shared mailbox, and advance state. Do not design or implement.
---

# Context Stage

Build the smallest evidence packet the next role needs.

**Announce at start:** "Using harness-powers:context to gather grounded context."

## Boundary

- Read only. Do not edit code, docs, or Harness state.
- Do not propose architecture or implementation.
- Do not launch another CLI, agent, or reviewer.
- Verify every reported path and symbol.

## Process

1. Read `docs/AGENT_WORKFLOW.md` and the intake lane/risk flags.
2. Read the relevant product, story, decision, architecture, and validation docs.
3. Trace the current behavior through the smallest relevant code path.
4. Record source-of-truth paths, affected boundaries, current behavior, risks,
   contradictions, and unresolved questions.
5. Write the grounded context result to the mailbox artifact supplied by `work`.
6. Advance with the same actor id:
   - bug/test failure -> `workflow advance <task> <actor> context debugging implementation-worker <artifact>`
   - tiny -> `workflow advance <task> <actor> context prepare implementation-worker <artifact>`
   - normal/high-risk -> `workflow advance <task> <actor> context contract design-authority <artifact>`
7. Report the task id and next stage only. Never print a copyable packet or invoke another actor.

For tiny work, keep the packet minimal. If exploration reveals ambiguity,
cross-domain impact, or a hard risk gate, recommend reclassification instead of
silently expanding scope.
