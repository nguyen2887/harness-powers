---
name: init
description: Use when your human partner asks to initialize, bootstrap, or set up the harness for a new or existing project (/harness-powers:init) - copies the vendored repository-harness scaffold, installs harness-cli, initializes the durable database, wires the harness-powers pipeline into CLAUDE.md, and registers external review/explore tools. Safe to re-run; never overwrites existing files.
---

# Initialize Harness Project

Turn the current directory into a harness-powers-ready project in one pass.

**Announce at start:** "Using harness-powers:init to set up the harness scaffold."

## Steps

1. **Run the init script** from the plugin root, targeting the current project directory:

   - Windows (PowerShell): `& "$env:CLAUDE_PLUGIN_ROOT\scripts\init-project.ps1" -Directory <project-dir>`
   - macOS/Linux: `"$CLAUDE_PLUGIN_ROOT/scripts/init-project.sh" <project-dir>`

   If `CLAUDE_PLUGIN_ROOT` is not set in your environment, locate the plugin root by finding this skill's own directory (the plugin root is two levels up from `skills/init/`).

   The script is idempotent and merge-safe: it git-inits if needed, copies only missing scaffold files, installs the vendored `harness-cli`, creates `harness.db`, appends the pipeline block to `CLAUDE.md` (marker-guarded), ensures the lean trace profile note in `docs/TRACE_SPEC.md`, and registers `codex` (external-review) and `agy` (repo-explore) when present on PATH.

2. **Read the script output.** Every line is prefixed `[harness-powers]`. Verify:
   - scaffold files created (or skipped as already present — fine on re-run)
   - `harness.db` initialized
   - CLAUDE.md block present
   - tool registry shows `present` for available CLIs

   If any step failed, fix it before proceeding — do not leave a half-initialized project.

3. **Commit the scaffold** as its own commit (e.g. `chore: harness-powers scaffold`) so project work starts from a clean baseline. If the repo has uncommitted user work, commit ONLY the scaffold files.

4. **Confirm activation and hand off.** Tell your human partner:
   - the scaffold is in place and committed
   - the pipeline activates on the NEXT session (this session did not load the new CLAUDE.md block; offer to restart, or simply follow the pipeline manually from here)
   - they can now describe what they want to build — that request enters through `harness-powers:intake`

## Notes

- Only the Windows x64 `harness-cli` binary is vendored. On other platforms the script warns and points to the upstream releases (https://github.com/hoangnb24/repository-harness/releases) — download the platform binary to `scripts/bin/harness-cli` and re-run.
- Existing files are NEVER overwritten. To refresh a stale scaffold file, delete it and re-run.
- This skill sets up structure only. Do not start designing or implementing the product here — that is `harness-powers:intake`'s job, in response to an actual request.
