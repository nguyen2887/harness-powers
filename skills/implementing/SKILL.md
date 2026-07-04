---
name: implementing
description: Use to execute an approved design (normal/high-risk) or a tiny-lane task in a Harness repo - TDD discipline, branch isolation, story proof updates as layers pass. Preceded by harness-powers:intake (tiny) or harness-powers:designing (normal/high-risk).
---

# Implementing

Execute the plan with test-first discipline. Coordination stays here; success claims do not — those belong to `harness-powers:done`.

**Announce at start:** "Using harness-powers:implementing to execute this work."

**Branch first:** never work on main/master without explicit consent. Create a branch; use `superpowers:using-git-worktrees` when you need workspace isolation.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Red → Green → Refactor, every behavior:

1. Write the smallest failing test for the next behavior
2. Run it and watch it fail — if it passes, the test is wrong or the behavior exists
3. Write the minimal code to make it pass
4. Run the tests — all green
5. Refactor while keeping green
6. Commit

**Exception:** pure config, docs, or copy edits with no runtime behavior (most tiny-lane work). Verify those by running the relevant check or build instead of a new test.

## Working the Plan

- Follow the story's acceptance criteria / execplan **one task at a time**, in order. Mark progress in your todo list.
- As proof layers actually pass, record them: `harness-cli story update --id US-XXX --unit 1 --integration 1 --e2e 0 --platform 0` (numeric 1/0 only — the CLI rejects yes/no). Record `1` only for layers you ran and saw pass.
- Commit frequently — every green cycle is a commit point.
- 2+ independent tasks with no shared state? `superpowers:dispatching-parallel-agents` is available.

## When to Stop and Ask

STOP immediately and ask your human partner when:

- A dependency is missing, an instruction is unclear, or a plan step contradicts reality
- Verification fails repeatedly on the same step
- The plan has a gap that requires a design decision

Ask instead of guessing. Do not force through blockers.

**Bug or unexpected failure** during work → invoke `harness-powers:debugging`, then return here.

## Exit

All acceptance criteria met and locally green → invoke `harness-powers:done`. That skill is the ONLY exit. Do not declare success, summarize completion, or offer merge options here.

## Red Flags

| Thought | Reality |
| --- | --- |
| "I'll write tests after, it's faster" | Test-after tests what you built, not what was required. |
| "The test obviously would fail, skip running it" | Unrun red tests hide broken tests. Watch it fail. |
| "I'll mark --unit 1 now, tests come later" | Proof flags mirror reality, not intentions. |
| "Small deviation from the plan, no need to mention" | Deviations are design decisions. Ask or record. |
