---
name: init
description: Use when your human partner asks to initialize, bootstrap, or set up the harness for a new or existing project (/harness-powers:init). Install the scaffold, harness-cli, shared task mailbox, role-based workflow, portable skills, and hard gate. Safe to re-run; never overwrites user files.
---

# Initialize Harness Project

Turn the current directory into a harness-powers-ready project in one pass.

**Announce at start:** "Using harness-powers:init to set up the harness scaffold."

## Steps

1. **Run the init script** from the plugin root, targeting the current project directory:

   - Windows (PowerShell): `& "$env:CLAUDE_PLUGIN_ROOT\scripts\init-project.ps1" -Directory <project-dir>`
   - macOS/Linux: `"$CLAUDE_PLUGIN_ROOT/scripts/init-project.sh" <project-dir>`

   If `CLAUDE_PLUGIN_ROOT` is not set in your environment, locate the plugin root by finding this skill's own directory (the plugin root is two levels up from `skills/init/`).

   The script is idempotent and merge-safe: it git-inits if needed, copies only missing scaffold files, installs `harness-cli`, creates `harness.db`, installs the marker-guarded workflow block only in canonical `AGENTS.md`, makes `CLAUDE.md` import it with `@AGENTS.md`, adds `docs/AGENT_WORKFLOW.md`, vendors portable skills into `.agents/skills/` and `.claude/skills/`, removes redundant recognizable Harness-owned `.codex/skills/` and `.grok/skills/` copies, installs the shared workflow helper, doctor, and hard gate, and ensures lean trace. Custom legacy `CLAUDE.md` content is preserved and warned about rather than deleted. Codex and Grok discover the shared `.agents/skills/` source; Claude uses the repo-local native adapter. It never binds roles to installed models or CLIs.

2. **Read the script output.** Every line is prefixed `[harness-powers]`. Verify:
   - scaffold files created (or skipped as already present — fine on re-run)
   - `harness.db` initialized
   - `AGENTS.md` block present and `CLAUDE.md` imports `@AGENTS.md`
   - `.harness-powers/bin/harness-powers-workflow` is executable
   - `.harness-powers/bin/harness-powers-doctor` is executable
   - public `work`, `approve`, `pause`, and `doctor` skills are installed for supported runtimes

   If any step failed, fix it before proceeding — do not leave a half-initialized project.

3. **Commit the scaffold** as its own commit (e.g. `chore: harness-powers scaffold`) so project work starts from a clean baseline. If the repo has uncommitted user work, commit ONLY the scaffold files.

4. **Confirm activation and hand off.** Tell your human partner:
   - the scaffold is in place and committed
   - the pipeline activates on the NEXT session (this session did not load the refreshed instruction import; offer to restart, or simply follow the pipeline manually from here)
   - they can now invoke `work <description>` (or the runtime's slash/skill adapter)

## Notes

- Only the Windows x64 `harness-cli` binary is vendored. On macOS/Linux the script auto-downloads the matching binary (`macos-arm64`, `macos-x64`, `linux-x64`, `linux-arm64`) from the pinned upstream release and checksum-verifies it. If the machine is offline or `curl` is missing, it warns and points to the upstream releases (https://github.com/hoangnb24/repository-harness/releases) — download the platform binary to `scripts/bin/harness-cli`, `chmod +x` it, and re-run.
- **Re-running refreshes harness-powers-owned artifacts in place** — the marked `AGENTS.md` block, safe `CLAUDE.md` import shim, `docs/AGENT_WORKFLOW.md`, vendored runtime skills, workflow helper, and gate script. Non-owned Claude content, user code/docs, `harness.db`, and existing hook JSON are preserved. A legacy harness-powers-owned `harness-powers.toml` is removed because its stale comments could auto-trigger another CLI.
- **Hard-gate hooks:** init blocks code edits for active normal/high-risk mailbox tasks and unapproved `in_progress` stories until a reviewer approval starts `plan-review passed:`. Dormant `planned` roadmap stories are ignored. Codex and Grok require one-time hook trust; on Windows the hook needs bash. The gate is fail-open when no db/CLI is available or the edit is docs-only.
- This skill sets up structure only. Do not start product work here; that begins through `work` in response to an actual request.
