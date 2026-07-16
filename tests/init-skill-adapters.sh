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

echo 'init skill adapter tests: PASS'
