#!/usr/bin/env bash
# Initializes a project with the vendored repository-harness scaffold and the
# harness-powers pipeline. Idempotent. Re-running REFRESHES harness-powers-owned
# artifacts (pipeline blocks, workflow reference, vendored skills, gate script)
# so a new plugin version lands without deleting anything by hand. User code/docs,
# hook JSON, harness.db, and content outside owned markers are preserved.
# Mirror of init-project.ps1.
set -euo pipefail

DIRECTORY="${1:-$(pwd)}"
DRY_RUN="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAFFOLD="$ROOT/scaffold"
TEMPLATES="$ROOT/templates"

step() { echo "[harness-powers] $*"; }
step "Target project: $DIRECTORY"

# Bump this when the vendored scaffold pins a new harness-cli version.
HARNESS_CLI_TAG="harness-cli-v0.1.11"
HARNESS_CLI_RELEASE_BASE="https://github.com/hoangnb24/repository-harness/releases/download"

detect_platform() {
  local os arch
  os="$(uname -s)"; arch="$(uname -m)"
  case "$os:$arch" in
    Darwin:arm64)               echo "macos-arm64" ;;
    Darwin:x86_64)              echo "macos-x64" ;;
    Linux:x86_64)               echo "linux-x64" ;;
    Linux:aarch64|Linux:arm64)  echo "linux-arm64" ;;
    *)                          echo "unsupported" ;;
  esac
}

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else echo ""; fi
}

# Fetch the platform harness-cli into scripts/bin/harness-cli when it is missing.
# Soft-fails (warns, never aborts) so init still completes offline; the vendored
# windows-x64 .exe is left as the Windows fallback.
ensure_cli_binary() {
  local bin_dir="$DIRECTORY/scripts/bin"
  local target="$bin_dir/harness-cli"
  [ -x "$target" ] && return 0                    # runnable native binary already present
  [ -x "$bin_dir/harness-cli.exe" ] && return 0   # Windows: vendored .exe covers it

  local platform; platform="$(detect_platform)"
  if [ "$platform" = "unsupported" ]; then
    step "WARNING: unsupported platform ($(uname -s)/$(uname -m)); cannot fetch harness-cli."
    return 0
  fi

  local name="harness-cli-$platform"
  local url="$HARNESS_CLI_RELEASE_BASE/$HARNESS_CLI_TAG/$name"

  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would download $name ($HARNESS_CLI_TAG) into scripts/bin/harness-cli"
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    step "WARNING: curl not found; cannot download $name."
    step "Fetch $url into scripts/bin/harness-cli, chmod +x it, and re-run."
    return 0
  fi

  mkdir -p "$bin_dir"
  local tmp; tmp="$(mktemp -d)"
  step "Downloading $name ($HARNESS_CLI_TAG)..."
  if ! curl -fsSL "$url" -o "$tmp/$name"; then
    step "WARNING: download failed ($url)."
    step "Fetch it manually into scripts/bin/harness-cli and re-run."
    rm -rf "$tmp"; return 0
  fi
  # Verify the checksum when the .sha256 is published alongside the binary.
  if curl -fsSL "$url.sha256" -o "$tmp/$name.sha256" 2>/dev/null; then
    local expected actual
    expected="$(awk '{print $1; exit}' "$tmp/$name.sha256")"
    actual="$(sha256_of "$tmp/$name")"
    if [ -n "$expected" ] && [ -n "$actual" ] && [ "$expected" != "$actual" ]; then
      step "WARNING: checksum mismatch for $name (expected $expected, got $actual). Not installing."
      rm -rf "$tmp"; return 0
    fi
  fi
  cp "$tmp/$name" "$target"
  chmod 755 "$target"
  rm -rf "$tmp"
  if "$target" --help >/dev/null 2>&1; then
    step "Installed scripts/bin/harness-cli ($platform)."
  else
    step "WARNING: downloaded harness-cli did not run cleanly; check the binary."
  fi
}

# Replace the harness-powers block between markers in $1 with template $2 (the
# template includes its own BEGIN/END markers), or append it if absent. Only the
# marked block is touched; everything else in the file is preserved verbatim.
upsert_block() {
  local file="$1" template="$2" label="$3"
  if [ -f "$file" ] && grep -q 'HARNESS-POWERS:BEGIN' "$file"; then
    if [ "$DRY_RUN" = "--dry-run" ]; then
      step "DRY RUN: would refresh harness-powers block in $label"
      return 0
    fi
    local tmp; tmp="$(mktemp)"
    awk -v tpl="$template" '
      /HARNESS-POWERS:BEGIN/ && !repl {
        while ((getline line < tpl) > 0) print line
        close(tpl); in_old=1; repl=1; next
      }
      in_old && /HARNESS-POWERS:END/ { in_old=0; next }
      !in_old { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
    step "Refreshed harness-powers block in $label."
  elif [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would append harness-powers block to $label"
  else
    { [ -f "$file" ] && [ -s "$file" ] && echo ""; cat "$template"; } >> "$file"
    step "Appended harness-powers block to $label."
  fi
}

# Claude Code loads AGENTS.md through the official @ import syntax. Keep
# AGENTS.md canonical. New/owned CLAUDE.md files become a one-line shim; custom
# legacy content is preserved behind the import and surfaced for manual merge.
ensure_claude_shim() {
  local file="$DIRECTORY/CLAUDE.md" tmp cleaned
  if [ -f "$file" ] && [ "$(awk 'NF {print}' "$file")" = "@AGENTS.md" ]; then
    step "CLAUDE.md already imports canonical AGENTS.md."
    return 0
  fi
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would install @AGENTS.md Claude import shim"
    return 0
  fi
  if [ ! -f "$file" ]; then
    printf '%s\n' '@AGENTS.md' > "$file"
    step "Installed CLAUDE.md -> @AGENTS.md import shim."
    return 0
  fi

  tmp="$(mktemp)"
  awk '
    /HARNESS-POWERS:BEGIN/ {in_old=1; next}
    in_old && /HARNESS-POWERS:END/ {in_old=0; next}
    !in_old {print}
  ' "$file" > "$tmp"
  cleaned="$(awk 'NF {print}' "$tmp")"
  if [ -z "$cleaned" ]; then
    printf '%s\n' '@AGENTS.md' > "$file"
    step "Replaced legacy owned CLAUDE.md block with @AGENTS.md import shim."
  else
    if ! grep -qx '@AGENTS.md' "$tmp"; then
      { printf '%s\n\n' '@AGENTS.md'; cat "$tmp"; } > "$file"
    else
      mv "$tmp" "$file"; tmp=""
    fi
    step "WARNING: preserved custom CLAUDE.md content after @AGENTS.md; migrate it into AGENTS.md to reach the one-line canonical setup."
  fi
  [ -z "${tmp:-}" ] || rm -f "$tmp"
}

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

# --- 2b. Portable runtime skills -----------------------------------------------
# Overwritten on re-init so a new plugin version refreshes only
# harness-powers-owned skill directories.
PORTABLE_SKILLS="$ROOT/portable-skills"
is_harness_skill_dir() {
  local dir="$1"
  [ -f "$dir/SKILL.md" ] && grep -Eqi 'Harness|harness-powers|\.harness-powers|durable mailbox' "$dir/SKILL.md"
}
if [ -d "$PORTABLE_SKILLS" ]; then
  sk_n=0; legacy_n=0
  for src in "$PORTABLE_SKILLS"/*/; do
    [ -d "$src" ] || continue
    name="$(basename "$src")"
    for legacy_base in ".codex/skills" ".grok/skills"; do
      legacy_dir="$DIRECTORY/$legacy_base/$name"
      if [ -d "$legacy_dir" ]; then
        if ! is_harness_skill_dir "$legacy_dir"; then
          step "WARNING: preserving unrecognized $legacy_base/$name; it may shadow the shared Harness skill."
        elif [ "$DRY_RUN" = "--dry-run" ]; then
          legacy_n=$((legacy_n + 1))
        else
          rm -rf "$legacy_dir"
          legacy_n=$((legacy_n + 1))
        fi
      fi
    done
    for base in ".agents/skills" ".claude/skills"; do
      dest="$DIRECTORY/$base/$name"
      if [ "$DRY_RUN" = "--dry-run" ]; then
        sk_n=$((sk_n + 1))
      else
        mkdir -p "$dest"
        cp -R "$src." "$dest"
        sk_n=$((sk_n + 1))
      fi
    done
  done
  step "Portable skills: $sk_n vendored/refreshed across runtime adapters; $legacy_n redundant .codex/.grok skill dir(s) removed."
fi

# --- 2c. Role/stage workflow reference (harness-powers-owned) ------------------
workflow_src="$SCAFFOLD/docs/AGENT_WORKFLOW.md"
workflow_dest="$DIRECTORY/docs/AGENT_WORKFLOW.md"
if [ -f "$workflow_src" ]; then
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would install/refresh docs/AGENT_WORKFLOW.md"
  else
    mkdir -p "$(dirname "$workflow_dest")"
    cp "$workflow_src" "$workflow_dest"
    step "Installed/refreshed docs/AGENT_WORKFLOW.md."
  fi
fi

# --- 2d. Remove legacy harness-powers.toml -------------------------------------
# Older installs vendored a harness-powers.toml that bound workflow roles to
# runtime choices. The durable role resolver replaces it. Delete OUR copy
# (identified by its header); leave any unrelated same-named file alone.
legacy_toml="$DIRECTORY/harness-powers.toml"
if [ -f "$legacy_toml" ] && head -n 3 "$legacy_toml" | grep -q 'harness-powers'; then
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would remove legacy harness-powers.toml (obsolete model-hints file)."
  else
    rm -f "$legacy_toml"
    step "Removed legacy harness-powers.toml (obsolete runtime bindings)."
  fi
fi

# --- 3. harness-cli + database ---------------------------------------------------
ensure_cli_binary
CLI="$DIRECTORY/scripts/bin/harness-cli"
[ -x "$CLI" ] || CLI="$DIRECTORY/scripts/bin/harness-cli.exe"
if [ ! -x "$CLI" ] && [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: harness-cli not present yet; would download it, then run harness-cli init."
elif [ ! -x "$CLI" ]; then
  step "WARNING: no runnable harness-cli (auto-download failed or offline; see warnings above)."
  step "Fetch the $HARNESS_CLI_TAG binary from https://github.com/hoangnb24/repository-harness/releases into scripts/bin/harness-cli and re-run."
elif [ -f "$DIRECTORY/harness.db" ]; then
  step "harness.db already present."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would run harness-cli init"
else
  (cd "$DIRECTORY" && "$CLI" init)
  step "Initialized harness.db."
fi

# --- 4. AGENTS.md is canonical; CLAUDE.md imports it --------------------------
upsert_block "$DIRECTORY/AGENTS.md" "$TEMPLATES/agents-md-block.md" "AGENTS.md"
ensure_claude_shim

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

# --- 6. Shared mailbox helper + hard-gate adapters -----------------------------
GATE_SRC="$ROOT/gate"
if [ -d "$GATE_SRC" ]; then
  gate_bin="$DIRECTORY/.harness-powers/bin/harness-powers-gate"
  workflow_bin="$DIRECTORY/.harness-powers/bin/harness-powers-workflow"
  doctor_bin="$DIRECTORY/.harness-powers/bin/harness-powers-doctor"
  if [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would install/refresh mailbox helper and hard gate"
  else
    mkdir -p "$(dirname "$gate_bin")"
    cp "$GATE_SRC/harness-powers-gate" "$gate_bin"
    cp "$GATE_SRC/harness-powers-workflow" "$workflow_bin"
    cp "$GATE_SRC/harness-powers-doctor" "$doctor_bin"
    chmod 755 "$gate_bin"
    chmod 755 "$workflow_bin"
    chmod 755 "$doctor_bin"
    step "Installed/refreshed mailbox helper, doctor, and hard gate."
  fi

  install_hook() { # $1 src rel, $2 dest rel, $3 label
    local src="$GATE_SRC/$1" dest="$DIRECTORY/$2"
    if [ -f "$dest" ]; then
      step "$3 hook config exists at $2 — left as is; add the gate hook manually if you want it there."
    elif [ "$DRY_RUN" = "--dry-run" ]; then
      step "DRY RUN: would write $2 ($3 gate hook)"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      step "Wired $3 gate hook -> $2"
    fi
  }
  install_hook "hooks/codex-hooks.json"     ".codex/hooks.json"               "Codex"
  install_hook "hooks/grok-hooks.json"      ".grok/hooks/harness-powers.json" "Grok"
  install_hook "hooks/claude-settings.json" ".claude/settings.json"           "Claude Code"

  if [ "$DRY_RUN" != "--dry-run" ]; then
    step "Hard-gate active: code edits for active normal/high-risk tasks require a 'plan-review passed:' reviewer approval; dormant planned roadmap stories are ignored."
    step "TRUST REQUIRED: in Codex and Grok run '/hooks-trust' (or launch with --trust) once, or project hooks will NOT execute."
  fi
fi

step "Init complete. Start a fresh session, then use 'work <description>' or its runtime adapter."
