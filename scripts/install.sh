#!/usr/bin/env bash
# Installs the harness-powers workflow into a target repo that already has the
# repository-harness scaffold: appends the CLAUDE.md bootstrap block, patches
# docs/TRACE_SPEC.md with the lean trace profile, and registers external
# review/explore tools in the harness tool registry when their CLIs are present.
set -euo pipefail

DIRECTORY="${1:-$(pwd)}"
DRY_RUN="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/../templates"

step() { echo "[harness-powers] $*"; }

# --- 0. Preconditions --------------------------------------------------------
CLI="$DIRECTORY/scripts/bin/harness-cli"
[ -x "$CLI" ] || CLI="$DIRECTORY/scripts/bin/harness-cli.exe"
if [ ! -x "$CLI" ]; then
  echo "No Harness scaffold found at $DIRECTORY (scripts/bin/harness-cli missing)." >&2
  exit 1
fi
step "Target repo: $DIRECTORY"

# --- 1. CLAUDE.md bootstrap block ---------------------------------------------
CLAUDE_MD="$DIRECTORY/CLAUDE.md"
if [ -f "$CLAUDE_MD" ] && grep -q 'HARNESS-POWERS:BEGIN' "$CLAUDE_MD"; then
  step "CLAUDE.md already has the harness-powers block. Skipped."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would append harness-powers block to CLAUDE.md"
else
  { [ -f "$CLAUDE_MD" ] && [ -s "$CLAUDE_MD" ] && echo ""; cat "$TEMPLATES/claude-md-block.md"; } >> "$CLAUDE_MD"
  step "Appended harness-powers block to CLAUDE.md"
fi

# --- 2. TRACE_SPEC.md lean profile note ---------------------------------------
TRACE_SPEC="$DIRECTORY/docs/TRACE_SPEC.md"
if [ ! -f "$TRACE_SPEC" ]; then
  step "docs/TRACE_SPEC.md not found. Skipped lean profile note."
elif grep -q 'HARNESS-POWERS:LEAN-TRACE:BEGIN' "$TRACE_SPEC"; then
  step "TRACE_SPEC.md already has the lean profile note. Skipped."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would append lean trace profile note to docs/TRACE_SPEC.md"
else
  { echo ""; cat "$TEMPLATES/trace-spec-lean-block.md"; } >> "$TRACE_SPEC"
  step "Appended lean trace profile note to docs/TRACE_SPEC.md"
fi

# --- 3. Tool registry: external-review / repo-explore -------------------------
register_tool() {
  local name="$1" capability="$2" responsibility="$3" description="$4"
  if ! command -v "$name" >/dev/null 2>&1; then
    step "CLI '$name' not on PATH. Skipped registration."
    return 0
  fi
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would register '$name' as capability '$capability'"
    return 0
  fi
  if (cd "$DIRECTORY" && "$CLI" tool register --name "$name" --kind cli \
      --capability "$capability" --command "$name" \
      --description "$description" --responsibility "$responsibility"); then
    step "Registered '$name' -> $capability"
  else
    step "Registration of '$name' failed or already exists. Continuing."
  fi
}

register_tool codex external-review "Verification" "GPT reviewer via Codex CLI for plan-review and code-review gates"
register_tool agy repo-explore "Context selection" "Gemini explorer via Antigravity CLI for wide repo scans"
[ "$DRY_RUN" = "--dry-run" ] || (cd "$DIRECTORY" && "$CLI" tool check)

step "Done. Open a fresh Claude Code session in the target repo to activate the pipeline."
