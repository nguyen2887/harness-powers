# harness-powers

A role-based execution layer for repositories using
[repository-harness](https://github.com/hoangnb24/repository-harness). It turns a
change request into a durable stage machine without binding the workflow to a
model, provider, terminal layout, or session count.

Only use it in Harness repos. Repos without the scaffold can keep their existing
process skills.

## Public interface

The human needs two verbs:

```text
work <description>   create and start a task
work <task-id>       resume its current stage
approve <task-id>    explicitly freeze a reviewed plan
```

Runtime adapters may expose `/work`, `$work`, or a namespaced slash command.
Plain text remains the portable fallback. The human does not select or remember
the role, stage, pane, or handoff prompt.

## Workflow

```text
intake -> context -> contract -> plan-review -> freeze -> human-freeze
                                                     -> approve -> prepare
prepare -> verify -> code-review -> reconcile -> close -> closed
              |                         |
              +---- debugging <---------+
```

Tiny work may skip contract and plan review. Normal and high-risk work passes the
full freeze gate.

The internal skills are:

| Skill | Role contract |
| --- | --- |
| `work` | resolve task state, claim the current stage, dispatch one procedure |
| `approve` | record the explicit human freeze |
| `pause` | checkpoint interrupted stage state and release its claim |
| `doctor` | inspect installation, trust, hooks, skills, DB, and active tasks |
| `intake` | classify lane and persist the request |
| `context` | collect grounded, read-only repository evidence |
| `designing` | own contract, design, plan, and freeze reconciliation |
| `reviewing` | return an evidence-backed read-only plan/code verdict |
| `implementing` | prepare, build, and reconcile findings |
| `verifying` | collect fresh mechanical evidence |
| `debugging` | isolate root cause before changing behavior |
| `done` | close story, trace, friction, and completion records |

## Shared mailbox

`.harness-powers/bin/harness-powers-workflow` stores task state and append-only
artifacts under `.harness-powers/runtime/tasks/`. Each `work` invocation:

1. resolves or creates the task;
2. claims its current stage with a lease;
3. infers the required role from durable state;
4. writes a separate result for each stage;
5. auto-chains safe same-role stages until a real execution boundary.

This removes manual copy/paste between panes. One session can run the whole flow,
or multiple sessions can take successive claims. Plan and code review prefer a
session independent from the artifact author. Explicit self-review is supported
only as a recorded degraded-independence mode.

For a deliberate mid-stage switch, `pause <task-id>` persists dirty-tree and
progress evidence without advancing. `work <task-id>` resumes it in another
session. Dead local claim owners are recoverable; live owners remain protected.
Plain `work` resumes the sole active task or lists choices when several exist.

The durable machine remains granular, but one invocation commonly executes:

```text
prepare -> build -> verify
verify failure -> debugging -> verify
reconcile -> verify
reconcile approved -> close -> closed
```

It stops for a role change, independent review, human freeze, blocker,
clarification, or safety budget. Build runs targeted inner-loop checks; verify
runs final acceptance and broader checks once.

Tiny mechanical work with no executable behavior change or risk flags may use
`verify -> close`. Tiny runtime/config changes still require code review.

## Enforcement

The installer delivers the same policy through marker-guarded repository
instructions, vendored portable skills, runtime hook adapters, and one hard-gate
script. The gate blocks code edits for active normal/high-risk mailbox tasks and
unapproved `in_progress` stories until a reviewer approval begins
`plan-review passed:`. Dormant roadmap stories that are merely `planned` do not
block unrelated work. The human freeze is recorded separately as
`human-freeze approved:`.

Verification, judgment, reconciliation, and close are separate. Only `done` may
claim completion. Merge, push, PR, and deployment remain explicit human choices.

## Install

Install the plugin globally so init is available in an empty directory:

```text
/plugin marketplace add nguyen2887/harness-powers
/plugin install harness-powers@harness-powers
```

Then initialize a project:

```text
/harness-powers:init
```

Re-running init refreshes only harness-powers-owned surfaces: the marked
instruction blocks, `docs/AGENT_WORKFLOW.md`, portable skills, workflow helper,
and gate. Existing project files, `harness.db`, and existing hook configuration
are preserved.

Init also:

1. creates the vendored scaffold when files are missing;
2. installs the pinned `harness-cli` and initializes `harness.db`;
3. vendors portable skills into `.agents/skills/` and `.claude/skills/`; Codex
   and Grok discover the shared `.agents/skills/` source, while Claude gets its
   native repo-local adapter; redundant Harness-owned `.codex/skills/` and
   `.grok/skills/` copies are removed when their Harness ownership is
   recognizable; unrecognized runtime-specific overrides are preserved and
   surfaced by doctor;
4. installs the shared mailbox helper, doctor, and plan gate;
5. wires hook adapters when their config files do not already exist.

The installer deliberately does not register specific CLIs or bind roles to
models. Runtime and model selection remain replaceable deployment policy.

## Vendored scaffold

`scaffold/` is derived from repository-harness (MIT, © 2025 Hoang Nguyen; see
`LICENSES-repository-harness-MIT.txt`) and pins harness-cli v0.1.11. Windows x64
is bundled; supported macOS/Linux binaries are downloaded with checksum
verification during init.

## Layout

```text
.claude-plugin/   plugin metadata
skills/           plugin skills, including public work/approve/pause/doctor entrypoints
portable-skills/  runtime-neutral copies vendored by init
gate/             mailbox helper, hard gate, and hook adapters
scaffold/         repository-harness template
templates/        marker-guarded instruction blocks
scripts/          idempotent init scripts
```

## Acceptance check

In an initialized repo, invoke `work <small change>`. It should create an intake,
claim context, persist a mailbox artifact, and report the task id plus next stage.
Invoking `work <task-id>` from another session should resume from that durable
stage without copied chat history.
