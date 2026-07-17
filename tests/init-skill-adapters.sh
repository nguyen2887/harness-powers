#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'find "$TMP" -depth -delete 2>/dev/null || true' EXIT

mkdir -p "$TMP/scripts/bin" "$TMP/.grok/skills/work" "$TMP/.grok/skills/pause" "$TMP/.grok/skills/custom"
cat > "$TMP/scripts/bin/harness-cli" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod 755 "$TMP/scripts/bin/harness-cli"
printf '%s\n' 'stale Harness workflow copy' > "$TMP/.grok/skills/work/SKILL.md"
printf '%s\n' 'custom pause override' > "$TMP/.grok/skills/pause/SKILL.md"
printf '%s\n' custom > "$TMP/.grok/skills/custom/SKILL.md"

"$ROOT/scripts/init-project.sh" "$TMP" >/dev/null

[ "$(awk 'NF {print}' "$TMP/CLAUDE.md")" = '@AGENTS.md' ]
[ "$(grep -c 'HARNESS-POWERS:BEGIN' "$TMP/AGENTS.md")" -eq 1 ]
[ "$(grep -c 'HARNESS-POWERS:BEGIN' "$TMP/CLAUDE.md" || true)" -eq 0 ]

for src in "$ROOT/portable-skills"/*/; do
  name="$(basename "$src")"
  [ -f "$TMP/.agents/skills/$name/SKILL.md" ]
  [ -f "$TMP/.claude/skills/$name/SKILL.md" ]
  if [ "$name" = pause ]; then
    [ -f "$TMP/.grok/skills/pause/SKILL.md" ]
  else
    [ ! -e "$TMP/.grok/skills/$name" ]
  fi
  [ ! -e "$TMP/.codex/skills/$name" ]
done

[ -f "$TMP/.grok/skills/custom/SKILL.md" ]

CUSTOM="$TMP/custom-project"
mkdir -p "$CUSTOM/scripts/bin"
cp "$TMP/scripts/bin/harness-cli" "$CUSTOM/scripts/bin/harness-cli"
printf '%s\n' '# Claude-specific legacy note' > "$CUSTOM/CLAUDE.md"
"$ROOT/scripts/init-project.sh" "$CUSTOM" >/dev/null
grep -qx '@AGENTS.md' "$CUSTOM/CLAUDE.md"
grep -q 'Claude-specific legacy note' "$CUSTOM/CLAUDE.md"
[ "$(grep -c 'HARNESS-POWERS:BEGIN' "$CUSTOM/CLAUDE.md" || true)" -eq 0 ]
[ "$(grep -c 'HARNESS-POWERS:BEGIN' "$CUSTOM/AGENTS.md")" -eq 1 ]

echo 'init skill adapter tests: PASS'
