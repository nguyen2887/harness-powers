#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW="$ROOT/gate/harness-powers-workflow"
TMP="$(mktemp -d)"
trap 'find "$TMP" -depth -delete 2>/dev/null || true' EXIT

mkdir -p "$TMP/docs" "$TMP/.harness-powers"
: > "$TMP/docs/HARNESS.md"
: > "$TMP/harness.db"

workflow() {
  HARNESS_REPO_ROOT="$TMP" HARNESS_POWERS_RUNTIME="$TMP/runtime" "$WORKFLOW" "$@"
}

workflow create I-1 tiny 1 "recovery test" >/dev/null
dead_actor="$(hostname)-ppid-999999"
workflow claim I-1 "$dead_actor" >/dev/null

recovered="$(workflow claim I-1 recovery-actor)"
grep -q "recovered_claim: $dead_actor" <<<"$recovered"

checkpoint="$(workflow artifact I-1 recovery-actor checkpoint)"
printf '%s\n' '# checkpoint' 'pending: finish context' > "$TMP/$checkpoint"
workflow pause I-1 recovery-actor "$checkpoint" >/dev/null
show="$(workflow show I-1)"
grep -q "stage: context" <<<"$show"
grep -q "status: ready" <<<"$show"
grep -q "checkpoint_artifact: $checkpoint" <<<"$show"
grep -q "claimed_by: $" <<<"$show"

workflow claim I-1 resumed-actor >/dev/null
artifact="$(workflow artifact I-1 resumed-actor context)"
printf '%s\n' '# context complete' > "$TMP/$artifact"
workflow advance I-1 resumed-actor context prepare implementation-worker "$artifact" >/dev/null
show="$(workflow show I-1)"
grep -q "stage: prepare" <<<"$show"
grep -q "checkpoint_artifact: $" <<<"$show"

workflow create I-2 tiny 2 "live owner test" >/dev/null
live_actor="$(hostname)-ppid-$$"
workflow claim I-2 "$live_actor" >/dev/null
workflow claim I-2 "$live_actor" | grep -q 'reused_claim: true'
if workflow claim I-2 competing-actor >/dev/null 2>&1; then
  echo 'expected live owner claim to block' >&2
  exit 1
fi

echo 'workflow recovery tests: PASS'
