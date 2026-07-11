---
name: designing
description: Internal design-authority procedure dispatched by the work skill for contract or freeze. Produce contract/design/plan artifacts, reconcile the mailbox review verdict, and advance to plan-review or human-freeze. Never implement, approve on the human's behalf, or launch another actor.
---

# Design Authority

Turn grounded context into a frozen, reviewed implementation contract.

**Announce at start:** "Design authority: producing a reviewed contract and plan."

<HARD-GATE>
Write only under `docs/`. Do not scaffold or implement product code before the
plan review passes, the human freezes the plan, and the plan approval is recorded.
</HARD-GATE>

## Stage 1: Contract

1. Verify every path and claim in the context packet.
2. Ask unresolved questions one at a time.
3. Define current behavior, target behavior, acceptance criteria, constraints,
   non-goals, and validation expectations. Acceptance criteria must be testable.

## Stage 2: Design

1. Propose 2-3 approaches with trade-offs and a recommendation.
2. Specify domain/application flow, interfaces, data, platform impact, and
   observability only where relevant.
3. Record a decision when behavior, architecture, authorization, data ownership,
   API shape, or validation requirements change.

## Stage 3: Plan

Name the files, symbols, tests, commands, ordering, stop conditions, and one real
verify command. Plans assume the implementer has no conversation history.

- Normal: one story from `docs/templates/story.md`; keep contract, design notes,
  and execution steps as separate sections.
- High-risk: use the complete `docs/templates/high-risk-story/` packet and any
  required decision record.

Register the story with `harness-cli story add --id US-XXX --title "<title>"
--lane <normal|high-risk> --verify "<command>"`.

## Contract Stage Completion

Write the contract/design/plan summary, artifact paths, open questions, verify
command, and review request to the supplied mailbox artifact. Set the runtime
story id with `workflow set-story <task> <story-id>`, then run:

`workflow advance <task> <actor> contract plan-review technical-reviewer <artifact>`.

Report that an independent invocation of `work <task>` is preferred. Do not
print the plan or packet for the human to copy.

## Reconcile and Freeze

When the verdict returns:

1. Verify every finding technically. Fix Critical/Important; fix or reject Minor
   with a reason.
2. Persist a delta-review artifact when review is still required. Escalate after
   four rounds.
3. If another review round is required, write the revised plan and finding
   resolutions to a new mailbox artifact and run
   `workflow advance <task> <actor> freeze plan-review technical-reviewer <artifact>`.
4. When the verdict is `approved` and a round adds no Critical/Important
   findings, write the frozen plan,
   reviewer verdict, residual Minor findings, and verify command to the supplied
   artifact; run `workflow advance <task> <actor> freeze human-freeze human <artifact>`.
5. Ask the human for `/approve <task>`. Never infer approval from ordinary chat.
