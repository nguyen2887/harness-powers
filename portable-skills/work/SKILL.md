---
name: work
description: Use when the human invokes /work, says work with a task, starts a new Harness task, or resumes an existing task id. Resolve durable mailbox state, infer the required role and stage, claim it, execute the matching internal procedure, persist the handoff, and stop at the next boundary. Never require the human to name a role or copy a handoff packet.
---

# Work Resolver

`work` is the only normal entrypoint. The human supplies a new task description
or an existing task id; Harness resolves everything else.

**Announce at start:** "Resolving Harness task state and next stage."

## Runtime

Use `.harness-powers/bin/harness-powers-workflow` as `workflow`. If it is missing,
ask the human to re-run harness-powers init. Call `workflow actor` once and reuse
that exact actor id for every mailbox command in this invocation.

## Resolve or Create

- If the argument resolves with `workflow show <task-id>`, resume it.
- Otherwise treat the full argument as a new task description:
  1. Follow the sibling `intake` skill completely.
  2. Capture its printed intake id and lane.
  3. Create task id `I-<intake-id>` with
     `workflow create I-<id> <lane> <id> "<summary>"`.
  4. Continue into the new task's `context` stage in this invocation.

Do not ask the human for a role. `workflow show` returns `required_role`.

## Claim

Run `workflow claim <task-id> <actor-id>`.

- Existing live claim: report its owner/expiry and stop.
- Review artifact authored by this actor: ask the human to run `work <task-id>`
  in another session, or explicitly approve degraded self-review. Only after an
  explicit answer may you retry with `--allow-self`.
- `human-freeze`: stop and ask for `/approve <task-id>`.

Renew the lease with `workflow renew <task-id> <actor-id>` before a long-running
command and periodically during long stages. If execution stops before advance,
release the claim unless preserving it is necessary to prevent conflicting writes.

## Dispatch

Read the sibling stage skill and follow it, passing the task id, actor id,
current mailbox state, and an artifact path created with
`workflow artifact <task-id> <actor-id> <stage-label>`.

| Mailbox stage | Internal skill |
| --- | --- |
| context | `context` |
| contract, freeze | `designing` |
| plan-review, code-review | `reviewing` |
| prepare, reconcile | `implementing` |
| verify | `verifying` |
| debugging | `debugging` |
| close | `done` |

The internal skill writes its result to the mailbox artifact and calls
`workflow advance`. Never print a packet for the human to copy. At the next
boundary, report only the task id, stage status, and whether the next invocation
may use this session or should use an independent session.
