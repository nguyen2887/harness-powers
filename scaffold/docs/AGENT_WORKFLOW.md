# Agent Workflow

Harness is the control plane. The public interface is task-oriented; roles,
stages, panes, providers, and models are execution details.

```text
work <description>   create and start a task
work <task-id>       claim and continue the task's current stage
approve <task-id>    explicit human freeze after an approved plan review
```

Slash-capable runtimes may expose those as `/work` and `/approve` (possibly
namespaced). Skill-capable runtimes may expose `$work`. Plain text is the
portable fallback. The human never needs to name the next role or copy a packet.

## Topology

Within the same Harness checkout, the protocol supports one long-lived session,
several panes, multiple sessions from one provider, or a mixed-provider setup.
Every actor reads and writes the shared task mailbox under
`.harness-powers/runtime/tasks/`. Isolated worktrees are outside the default
topology and require an explicitly shared Harness control plane.

- One actor claims one stage at a time and renews its lease during long work.
- A completed stage persists its artifact and releases the claim.
- The active `work` invocation immediately reclaims and continues consecutive
  same-role stages; otherwise the next invocation resumes durable state.
- Product-code writes remain single-writer per task.
- Plan and code review should use a session independent of the artifact author.
  Explicit self-review is a visible degraded mode, never an invisible fallback.

## Roles

| Role | Responsibility | Write boundary |
| --- | --- | --- |
| `context-worker` | ground the request in repository evidence | mailbox context artifact only |
| `design-authority` | own contract, design, plan, and freeze reconciliation | planning docs and mailbox artifacts |
| `implementation-worker` | prepare, build, debug, verify, and reconcile findings | assigned product code, tests, proof, mailbox artifacts |
| `technical-reviewer` | judge plans or code against the supplied contract and evidence | mailbox verdict only |
| `closer` | durable story, trace, friction, and completion bookkeeping | Harness records and close artifact |
| `human` | explicitly freeze a reviewed plan and authorize external actions | approval record only |

No role is bound to a model, provider, pane count, or price tier. The runtime or
human may choose any suitable actor for the role at claim time.

## Stage Machine

```text
intake -> context -> contract -> plan-review -> freeze -> human-freeze
                                                     -> approve -> prepare
prepare -> verify -> code-review -> reconcile -> close -> closed
              |                         |
              +---- debugging <---------+
debugging -> verify | contract/design escalation
tiny mechanical: verify -> close
```

Tiny work may go `context -> prepare`. Normal and high-risk work require the
contract, plan-review, freeze, and explicit human-freeze path. Contract, design,
and plan may share one story artifact; the boundaries remain independently
reviewable.

## Execution Boundaries

Mailbox stages stay granular, but human interaction follows role boundaries.
One `work` invocation auto-chains consecutive stages when the required role is
unchanged. It also auto-chains the safe completion transitions
`verify -> close` for tiny mechanical work and `reconcile -> close` after an
approved code review.

Stop for a role change, plan/code review, human freeze, blocker, clarification,
closed task, six executed stages, or two debugging cycles. Auto-chaining never
collapses artifacts or bypasses a review/human gate.

During build, run targeted Red/Green checks only. `verify` runs the official
acceptance and broader checks once against the final working tree.

Before the first story-backed product edit, implementation marks the story
`in_progress`. The hard gate checks open normal/high-risk mailbox tasks plus
unapproved `in_progress` stories; dormant roadmap stories that are only
`planned` never block unrelated work.

Every task defaults to `review_policy: required`. Context may set
`skip-mechanical` only when all are true: lane is tiny, no executable behavior
changes, no risk flag exists, and deterministic mechanical proof is sufficient.
Runtime-affecting config always requires review.

## Mailbox Contract

The installed `.harness-powers/bin/harness-powers-workflow` helper owns task
state, claims, and transitions. Each task stores its lane, intake/story ids,
current stage, required role, review policy, latest artifact, artifact author,
reviewer actor, review independence, and append-only handoff artifacts.

After every transition, the resolver calls `next-action`; this deterministic
helper enforces same-role continuation, safe-close exceptions, review/human
boundaries, and stage/debug budgets.

An actor must:

1. `show` current state;
2. `claim` with a stable actor id;
3. read the latest artifact and referenced repository paths;
4. request a new mailbox artifact path and write the stage result there;
5. `advance` exactly one valid boundary.

Chat is not durable workflow state. Do not reconstruct a stage from memory or
ask the human to ferry context between panes.

## Review Contract

Review artifacts contain mode, verdict, evidence-backed findings, missing
evidence, and independence level. Reviewers do not patch the reviewed artifact
or run bookkeeping. Critical and Important findings are reconciled and reviewed
again; Minor findings are fixed or rejected with a technical reason.

After plan review and the explicit human freeze, record two distinct events:

```bash
harness-cli intervention add --story US-XXX --type approval --source human \
  --description "human-freeze approved: <artifact>"
harness-cli intervention add --story US-XXX --type approval --source reviewer \
  --description "plan-review passed: <reviewer and artifact>"
```

After code review passes, reconciliation records:

```bash
harness-cli intervention add --story US-XXX --type approval --source reviewer \
  --description "code-review passed: <reviewer and artifact>"
```

These prefixes are machine-enforced stage identifiers, not decorative prose.

## Completion

Only `close` may claim completion. It always requires fresh passing verification
and durable Harness records; required-review tasks also need an approved
code-review verdict and resolved findings. A `skip-mechanical` task instead needs
durable proof that the narrow exception remains valid.
Merge, push, PR creation, deployment, and other external actions remain separate
human decisions.
