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

# --- 2b. Portable skills for non-Claude CLIs (Codex -> .codex, agy -> .agents) ---
# Claude Code uses the harness-powers plugin skills; these vendored copies give
# Codex and agy the same intake -> done procedures. Merge-safe.
PORTABLE_SKILLS="$ROOT/portable-skills"
if [ -d "$PORTABLE_SKILLS" ]; then
  sk_created=0; sk_skipped=0
  for src in "$PORTABLE_SKILLS"/*/; do
    [ -d "$src" ] || continue
    name="$(basename "$src")"
    for base in ".codex/skills" ".agents/skills"; do
      dest="$DIRECTORY/$base/$name"
      if [ -f "$dest/SKILL.md" ]; then
        sk_skipped=$((sk_skipped + 1))
      elif [ "$DRY_RUN" = "--dry-run" ]; then
        sk_created=$((sk_created + 1))
      else
        mkdir -p "$dest"
        cp -R "$src." "$dest"
        sk_created=$((sk_created + 1))
      fi
    done
  done
  step "Portable skills: $sk_created copied, $sk_skipped already present (.codex/skills + .agents/skills)."
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

# --- 4b. AGENTS.md pipeline block (Codex / agy / Grok read this; Claude does not) ----
AGENTS_MD="$DIRECTORY/AGENTS.md"
if [ -f "$AGENTS_MD" ] && grep -q 'HARNESS-POWERS:BEGIN' "$AGENTS_MD"; then
  step "AGENTS.md already has the harness-powers block."
elif [ "$DRY_RUN" = "--dry-run" ]; then
  step "DRY RUN: would append harness-powers block to AGENTS.md"
else
  { [ -f "$AGENTS_MD" ] && [ -s "$AGENTS_MD" ] && echo ""; cat "$TEMPLATES/agents-md-block.md"; } >> "$AGENTS_MD"
  step "Appended harness-powers block to AGENTS.md."
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

# --- 7. Hard-gate hooks (plan-review) for Claude / Codex / Grok ------------------
GATE_SRC="$ROOT/gate"
if [ -d "$GATE_SRC" ]; then
  gate_bin="$DIRECTORY/.harness-powers/bin/harness-powers-gate"
  if [ -f "$gate_bin" ]; then
    step "Gate script already present."
  elif [ "$DRY_RUN" = "--dry-run" ]; then
    step "DRY RUN: would install .harness-powers/bin/harness-powers-gate"
  else
    mkdir -p "$(dirname "$gate_bin")"
    cp "$GATE_SRC/harness-powers-gate" "$gate_bin"
    chmod 755 "$gate_bin"
    step "Installed .harness-powers/bin/harness-powers-gate."
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
    step "Hard-gate active: edits to code are blocked until each open normal/high-risk story has a reviewer approval."
    step "TRUST REQUIRED: in Codex and Grok run '/hooks-trust' (or launch with --trust) once, or project hooks will NOT execute."
  fi
fi

step "Init complete. Commit the scaffold, then start a fresh session (the CLAUDE.md block loads at session start)."
