#!/usr/bin/env bash
# Initializes a project with the vendored repository-harness scaffold and the
# harness-powers pipeline. Idempotent and merge-safe: existing files are never
# overwritten. Mirror of init-project.ps1.
set -euo pipefail

DIRECTORY="${1:-$(pwd)}"
DRY_RUN="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAFFOLD="$ROOT/scaffold"
TEMPLATES="$ROOT/templates"

step() { echo "[harness-powers] $*"; }
step "Target project: $DIRECTORY"

# --- 1. git init ---------------------------------------------------------------
if [ -d "$DIRECTORY/.git" ]; then
  step "Git repository already present."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would git init"
else
  git -C "$DIRECTORY" init >/dev/null
  step "Initialized git repository."
fi

# --- 2. Merge-copy scaffold -----------------------------------------------------
created=0; skipped=0
while IFS= read -r -d '' file; do
  rel="${file#"$SCAFFOLD"/}"
  # The root gitignore is stored without its dot so it stays inert inside the plugin repo.
  [ "$rel" = "gitignore" ] && rel=".gitignore"
  dest="$DIRECTORY/$rel"
  if [ -e "$dest" ]; then
    skipped=$((skipped + 1))
  elif [ "$DRY_RUN" = "--dry-run" ]; then
    created=$((created + 1))
  else
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
    created=$((created + 1))
  fi
done < <(find "$SCAFFOLD" -type f -print0)
step "Scaffold: $created file(s) created, $skipped already present (skipped)."

# --- 3. harness-cli + database ---------------------------------------------------
CLI="$DIRECTORY/scripts/bin/harness-cli"
[ -x "$CLI" ] || CLI="$DIRECTORY/scripts/bin/harness-cli.exe"
if [ ! -x "$CLI" ]; then
  step "WARNING: no runnable harness-cli for this platform (only windows-x64 is vendored)."
  step "Download your platform binary from https://github.com/hoangnb24/repository-harness/releases into scripts/bin/ and re-run."
elif [ -f "$DIRECTORY/harness.db" ]; then
  step "harness.db already present."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would run harness-cli init"
else
  (cd "$DIRECTORY" && "$CLI" init)
  step "Initialized harness.db."
fi

# --- 4. CLAUDE.md pipeline block ---------------------------------------------------
CLAUDE_MD="$DIRECTORY/CLAUDE.md"
if [ -f "$CLAUDE_MD" ] && grep -q 'HARNESS-POWERS:BEGIN' "$CLAUDE_MD"; then
  step "CLAUDE.md already has the harness-powers block."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would append harness-powers block to CLAUDE.md"
else
  { [ -f "$CLAUDE_MD" ] && [ -s "$CLAUDE_MD" ] && echo ""; cat "$TEMPLATES/claude-md-block.md"; } >> "$CLAUDE_MD"
  step "Appended harness-powers block to CLAUDE.md."
fi

# --- 5. Lean trace profile note ------------------------------------------------------
TRACE_SPEC="$DIRECTORY/docs/TRACE_SPEC.md"
if [ -f "$TRACE_SPEC" ]; then
  if grep -q 'HARNESS-POWERS:LEAN-TRACE:BEGIN' "$TRACE_SPEC"; then
    step "TRACE_SPEC.md already has the lean profile note."
  elif [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would append lean trace note to docs/TRACE_SPEC.md"
  else
    { echo ""; cat "$TEMPLATES/trace-spec-lean-block.md"; } >> "$TRACE_SPEC"
    step "Appended lean trace profile note to docs/TRACE_SPEC.md."
  fi
fi

# --- 6. Tool registry: external-review / repo-explore --------------------------------
register_tool() {
  local name="$1" capability="$2" responsibility="$3" description="$4"
  local cmd_path
  cmd_path="$(command -v "$name" 2>/dev/null)" || true
  if [ -z "$cmd_path" ]; then
    step "CLI '$name' not on PATH. Skipped registration."
    return 0
  fi
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would register '$name' ($cmd_path) as '$capability'"
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

if [ -x "$CLI" ]; then
  register_tool codex external-review "Verification" "GPT reviewer via Codex CLI for plan-review and code-review gates"
  register_tool agy repo-explore "Context selection" "Gemini explorer via Antigravity CLI for wide repo scans"
  [ "$DRY_RUN" = "--dry-run" ] || (cd "$DIRECTORY" && "$CLI" tool check) || true
fi

step "Init complete. Commit the scaffold, then start a fresh session (the CLAUDE.md block loads at session start)."
