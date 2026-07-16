---
name: work
description: Use when the human invokes /work, says work with a task, starts a new Harness task, or resumes an existing task id. Resolve durable mailbox state, infer roles and stages, claim work, auto-chain safe consecutive stages, persist artifacts, and stop only at a role, review, human, blocker, or safety boundary. Never require the human to name a role or copy a handoff packet.
---

# Work Resolver

The human may supply a description, a task id, or no argument. Resolve everything else.

**Announce at start:** "Resolving Harness task state and next execution boundary."

## Runtime

Use `.harness-powers/bin/harness-powers-workflow` as `workflow`. Call
`workflow actor` once and reuse that actor id for the entire invocation.

Before resolving work, require executable `workflow`, executable
`scripts/bin/harness-cli`, and `harness.db`. If any is missing, run
`.harness-powers/bin/harness-powers-doctor` when available and stop with its
bootstrap action. Do not edit product code while the hard gate is fail-open.

With no argument, run `workflow list` and consider only non-closed tasks. Resume
the sole active task automatically. If none exist, ask for a description. If
several exist, list task id, stage, status, and required role and ask only which
task to resume.

For a new description, follow `intake`, create `I-<intake-id>`, and execute its
`context` stage. For an existing id, begin from `workflow show <task-id>`. Read
both `latest_artifact` and any `checkpoint_artifact`. A missing id matching
`I-<number>` is an error, not a new description.

## Execution Loop

For each stage:

1. Show state and capture `stage`, `required_role`, `review_policy`, and latest artifact.
2. Claim it with `workflow claim <task> <actor>` and capture whether a dead or
   expired owner was recovered.
3. For review authored by this actor, require another session or explicit
   degraded self-review before retrying with `--allow-self`.
4. Create a mailbox artifact and execute the mapped internal skill.
5. Increment stage/debug counters and run
   `workflow next-action <task> <previous-stage> <previous-role> <stages-run> <debug-runs>`.
   Obey its `continue` or `stop` result.

If a checkpoint exists or claim recovery occurred, perform an interrupted-work
preflight before stage work: read the checkpoint and latest completed artifact,
inspect the wrapper and affected nested Git working trees, compare partial
changes with the frozen plan and base commit, and state what will be preserved,
completed, or redone. Never discard unexplained dirty work.

| Stage | Internal skill |
| --- | --- |
| context | `context` |
| contract, freeze | `designing` |
| plan-review, code-review | `reviewing` |
| prepare, reconcile | `implementing` |
| verify | `verifying` |
| debugging | `debugging` |
| close | `done` |

## Continue Automatically

`next-action` continues in the same invocation when either condition holds:

- the next stage has the same required role; or
- the transition is `verify -> close` for tiny mechanical work or
  `reconcile -> close` after approved code review.

Typical chains are:

- `prepare -> verify`;
- `verify -> debugging -> verify`;
- `reconcile -> verify`;
- `verify -> close -> closed` for tiny mechanical work;
- `reconcile -> close -> closed` after approved review.

Internal stages still write separate artifacts and transitions. Auto-chaining
changes human interaction, not audit granularity.

## Stop Boundaries

Stop and report the task id plus next stage when:

- required role changes, except the safe close transitions above;
- next stage is `plan-review`, `code-review`, or `human-freeze`;
- the task is `closed`;
- evidence requires human clarification or external authorization;
- another actor owns the claim;
- a baseline or environment blocker prevents safe progress;
- six stages or two debugging cycles ran in this invocation.

Renew the lease before long commands. If execution aborts before advance,
release the claim unless holding it is necessary to prevent conflicting writes.
Never ask the human to copy a packet or manually invoke the next same-role stage.
