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
  local cmd_path
  cmd_path="$(command -v "$name" 2>/dev/null)" || true
  if [ -z "$cmd_path" ]; then
    step "CLI '$name' not on PATH. Skipped registration."
    return 0
  fi
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would register '$name' ($cmd_path) as capability '$capability'"
    return 0
  fi
  # Register the resolved path so the CLI's own PATH probe cannot disagree.
  if (cd "$DIRECTORY" && "$CLI" tool register --name "$name" --kind cli \
      --capability "$capability" --command "$cmd_path" \
      --description "$description" --responsibility "$responsibility"); then
    step "Registered '$name' -> $capability"
  else
    step "Registration of '$name' failed or already exists. Continuing."
  fi
}

register_tool codex external-review "Verification" "GPT reviewer via Codex CLI for plan-review and code-review gates"
register_tool agy repo-explore "Context selection" "Gemini explorer via Antigravity CLI for wide repo scans"
[ "$DRY_RUN" = "--dry-run" ] || (cd "$DIRECTORY" && "$CLI" tool check)

# --- 4. Enable plugin for this project only -----------------------------------
SETTINGS_DIR="$DIRECTORY/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.local.json"
PLUGIN_KEY="harness-powers@harness-powers"
MARKETPLACE_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would enable $PLUGIN_KEY in .claude/settings.local.json"
elif [ -f "$SETTINGS_FILE" ] && grep -q "$PLUGIN_KEY" "$SETTINGS_FILE"; then
  step "Plugin already enabled in .claude/settings.local.json. Skipped."
elif [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq --arg key "$PLUGIN_KEY" --arg path "$MARKETPLACE_PATH" \
     '.enabledPlugins[$key] = true
      | .extraKnownMarketplaces["harness-powers"] = {source:{source:"local",path:$path}}' \
     "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
  step "Enabled $PLUGIN_KEY for this project only (.claude/settings.local.json)"
elif [ -f "$SETTINGS_FILE" ]; then
  step "MANUAL STEP (jq not found): merge into $SETTINGS_FILE:"
  step "  \"enabledPlugins\": { \"$PLUGIN_KEY\": true }"
  step "  \"extraKnownMarketplaces\": { \"harness-powers\": { \"source\": { \"source\": \"local\", \"path\": \"$MARKETPLACE_PATH\" } } }"
else
  mkdir -p "$SETTINGS_DIR"
  cat > "$SETTINGS_FILE" <<EOF
{
  "enabledPlugins": { "$PLUGIN_KEY": true },
  "extraKnownMarketplaces": {
    "harness-powers": { "source": { "source": "local", "path": "$MARKETPLACE_PATH" } }
  }
}
EOF
  step "Enabled $PLUGIN_KEY for this project only (.claude/settings.local.json)"
fi

step "Done. Open a fresh Claude Code session in the target repo to activate the pipeline."
