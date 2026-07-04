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
- **Cross-model review gates.** Plan review after designing, code review before
  done. Wired through the harness **tool registry** by capability, never by
  tool name: `external-review` (e.g. GPT via Codex CLI) and `repo-explore`
  (e.g. Gemini via Antigravity CLI). Absent provider = clean skip with a
  self-review fallback, per the registry's degrade ladder.
- **Review stop rule.** Fix Critical/Important, reject Minor with reasons; loop
  until a round adds no new Critical/Important; escalate past 4 rounds. LLM
  reviewers never say "no issues" unprompted — the stop rule keeps the loop
  convergent.

## Install

One-time, in Claude Code (registers the marketplace globally — marketplaces
have no project scope; the plugin itself stays project-scoped):

```
/plugin marketplace add C:\Users\<you>\Codes\harness-powers
```

Do NOT `/plugin install` at user level — per-repo enablement is handled by the
installer below via `.claude/settings.local.json` (`enabledPlugins` +
`extraKnownMarketplaces`), which overrides user-level settings for that repo
only. If you already installed globally, disable it: `/plugin` → harness-powers
→ disable at user level.

Per harness repo (PowerShell / bash):

```powershell
& "$HOME\Codes\harness-powers\scripts\install.ps1" -Directory C:\path\to\repo
```

```bash
~/Codes/harness-powers/scripts/install.sh /path/to/repo
```

The installer:

1. Appends the bootstrap block to the repo's `CLAUDE.md` (idempotent, marker-guarded) —
   this is what makes the pipeline auto-trigger and tells Superpowers to stand down.
2. Appends the lean-trace override note to `docs/TRACE_SPEC.md`.
3. Registers `codex` (capability `external-review`) and `agy` (capability
   `repo-explore`) in the harness tool registry when those CLIs are on PATH,
   then runs `tool check`.
4. Enables the plugin for that repo only, by merging `enabledPlugins` and
   `extraKnownMarketplaces` into `.claude/settings.local.json` (personal,
   gitignored — the machine-specific marketplace path never gets committed).

Both installers accept a dry-run flag (`-DryRun` / `--dry-run` as second arg).

**Iterating on skills:** installed plugins are cached under
`~/.claude/plugins/cache/`, not read in-place. After editing skills here, run
`/plugin marketplace update harness-powers` to refresh. To test edits live
without the cache, launch with `claude --plugin-dir ~/Codes/harness-powers`.

## Acceptance test

Open a fresh Claude Code session in an installed repo and ask for a small code
change. A working install classifies the task through `harness-powers:intake`
(announcing the lane) before touching anything.

## Layout

```
.claude-plugin/   plugin.json + marketplace.json
skills/           intake / designing / implementing / debugging / done
templates/        claude-md-block.md, trace-spec-lean-block.md
scripts/          install.ps1, install.sh
```
