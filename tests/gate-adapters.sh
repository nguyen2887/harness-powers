#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$ROOT/gate/harness-powers-gate"
TMP="$(mktemp -d)"
trap 'find "$TMP" -depth -delete 2>/dev/null || true' EXIT

mkdir -p "$TMP/scripts/bin" "$TMP/.harness-powers/runtime/tasks/I-1/fields" "$TMP/docs"
: > "$TMP/harness.db"
printf '%s\n' normal > "$TMP/.harness-powers/runtime/tasks/I-1/fields/lane"
printf '%s\n' context > "$TMP/.harness-powers/runtime/tasks/I-1/fields/stage"
: > "$TMP/.harness-powers/runtime/tasks/I-1/fields/story_id"
cat > "$TMP/scripts/bin/harness-cli" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod 755 "$TMP/scripts/bin/harness-cli"

expect_exit() {
  expected="$1" payload="$2"
  set +e
  printf '%s' "$payload" | "$GATE" >/dev/null 2>&1
  actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || {
    echo "expected gate exit $expected, got $actual for: $payload" >&2
    exit 1
  }
}

code="$TMP/app/code.ts"
doc="$TMP/docs/plan.md"

expect_exit 2 "{\"tool_name\":\"Edit\",\"cwd\":\"$TMP\",\"tool_input\":{\"file_path\":\"$code\"}}"
expect_exit 2 "{\"toolName\":\"edit_file\",\"workspaceRoot\":\"$TMP\",\"toolInput\":{\"path\":\"$code\"}}"
expect_exit 2 "{\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"apply_patch\",\"cwd\":\"$TMP\",\"tool_input\":{\"patch\":\"*** Begin Patch\\n*** Update File: $code\\n@@\\n-old\\n+new\\n*** End Patch\"}}"
expect_exit 2 "{\"tool_name\":\"apply_patch\",\"cwd\":\"$TMP\",\"tool_input\":{\"patch\":\"*** Begin Patch\\n*** Update File: $doc\\n@@\\n-old\\n+new\\n*** Update File: $code\\n@@\\n-old\\n+new\\n*** End Patch\"}}"
expect_exit 0 "{\"tool_name\":\"apply_patch\",\"cwd\":\"$TMP\",\"tool_input\":{\"patch\":\"*** Begin Patch\\n*** Update File: $doc\\n@@\\n-old\\n+new\\n*** End Patch\"}}"

echo 'gate adapter tests: PASS'
