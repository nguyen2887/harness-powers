# harness-powers

Lean, harness-native process skills for Claude Code. A distilled fork of the
[Superpowers](https://github.com/obra/superpowers) workflow philosophy, rebuilt
to act as the **enforcement layer** for repos that use the
[repository-harness](https://github.com/hoangnb24/repository-harness) scaffold.

**Only for harness repos.** Repos without the scaffold should keep using
Superpowers as-is.

## Design

The harness owns structure (lanes, stories, decisions, durable records via
`harness-cli` + SQLite). These skills own behavior (when to classify, when to
design, how to test, when work may be called done). Five skills, one pipeline:

```
request → intake ─┬─ tiny ─────────────────────────────→ implementing → done
                  └─ normal/high-risk → designing ──────→ implementing → done
                                        [Gate 1: plan review]        [Gate 2: code review]
any bug / test failure / weirdness → debugging (root cause first, then back)
```

| Skill | Replaces (Superpowers) | Adds (Harness) |
| --- | --- | --- |
| `harness-powers:intake` | brainstorming trigger | risk lanes, `harness-cli intake` |
| `harness-powers:designing` | brainstorming + writing-plans | story packets, decision records, plan-review gate |
| `harness-powers:implementing` | test-driven-development + executing-plans | `story update` proof flags |
| `harness-powers:debugging` | systematic-debugging | friction capture (`backlog add`) |
| `harness-powers:done` | verification-before-completion + requesting-code-review + finishing-a-development-branch | `story verify`, lean trace, code-review gate |

Key choices:

- **Lane decides depth.** Tiny work = one intake call + implement + verify. No
  story packet, no design ceremony.
- **One exit door.** All bookkeeping (verify, review, trace, friction) lives in
  `done` only, so it cannot be forgotten or duplicated.
- **Lean trace profile.** Minimal/Standard tiers only; the Detailed tier is
  retired (the installer patches `docs/TRACE_SPEC.md` accordingly).
- **Cross-model review gates.** Plan review after designing (`codex exec`),
  code review before done (`codex exec review --base <branch>`). Wired through
  the harness **tool registry** by capability, never by tool name:
  `external-review` (e.g. GPT via Codex CLI) and `repo-explore` (e.g. Gemini
  via Antigravity CLI). Absent provider = clean skip with a self-review
  fallback, per the registry's degrade ladder.
- **Per-repo model tuning.** `harness-powers.toml` at the target repo root
  (committed, installed by init) sets the review model, reasoning effort,
  sandbox, and explore model. The registry answers "is the tool installed?"
  (per machine); the toml answers "how is it invoked?" (per repo). Missing
  keys fall back to each CLI's own defaults.
- **Review stop rule.** Fix Critical/Important, reject Minor with reasons; loop
  until a round adds no new Critical/Important; escalate past 4 rounds. LLM
  reviewers never say "no issues" unprompted — the stop rule keeps the loop
  convergent.

## Install

One-time, in Claude Code:

```
/plugin marketplace add nguyen2887/harness-powers
/plugin install harness-powers@harness-powers
```

Global install is intended: `/harness-powers:init` must be available in brand-new
empty projects. The pipeline itself does NOT activate globally — it only
auto-triggers in repos whose `CLAUDE.md` carries the harness-powers block, which
`init` writes. Repos without the block keep running Superpowers untouched.

## Start a project

```
mkdir my-project && cd my-project && claude
> /harness-powers:init
> (commit happens, restart session)
> "I want to build ..."
```

`init` is idempotent and merge-safe (never overwrites existing files). It:

1. `git init` if needed, then copies the vendored scaffold (46 files: AGENTS.md,
   docs/, templates, SQL schema, `harness-cli` binary).
2. Runs `harness-cli init` to create `harness.db`.
3. Appends the pipeline block to `CLAUDE.md` (marker-guarded) — this is what
   makes the pipeline auto-trigger and tells Superpowers to stand down.
4. Ensures the lean-trace override note in `docs/TRACE_SPEC.md`.
5. Registers `codex` (capability `external-review`) and `agy` (capability
   `repo-explore`) in the harness tool registry when those CLIs are on PATH,
   then runs `tool check`.

It also works on repos that already have a harness scaffold — existing files are
skipped, only the harness-powers wiring is added.

**Iterating on skills:** installed plugins are cached under
`~/.claude/plugins/cache/`, not read in-place. After editing skills, push and run
`/plugin marketplace update harness-powers` to refresh. To test edits live
without the cache, launch with `claude --plugin-dir ~/Codes/harness-powers`.

## Vendored scaffold

`scaffold/` is vendored from
[repository-harness](https://github.com/hoangnb24/repository-harness) (MIT,
(c) 2025 Hoang Nguyen — see `LICENSES-repository-harness-MIT.txt`), pinned at
harness-cli v0.1.11. Only the windows-x64 binary is bundled; other platforms
download theirs from the upstream releases. The root `.gitignore` template is
stored as `scaffold/gitignore` (no dot) so it stays inert inside this repo, and
no `CLAUDE.md` lives under `scaffold/` — the block is appended from
`templates/` at init time so this repo's own sessions never load it.

## Acceptance test

Open a fresh Claude Code session in an installed repo and ask for a small code
change. A working install classifies the task through `harness-powers:intake`
(announcing the lane) before touching anything.

## Layout

```
.claude-plugin/   plugin.json + marketplace.json
skills/           init / intake / designing / implementing / debugging / done
scaffold/         vendored repository-harness template (+ harness-cli.exe)
templates/        claude-md-block.md, trace-spec-lean-block.md
scripts/          init-project.ps1, init-project.sh
```
