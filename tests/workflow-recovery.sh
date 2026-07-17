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

workflow create I-3 high-risk 3 "review discussion test" >/dev/null
workflow claim I-3 context-actor >/dev/null
context_artifact="$(workflow artifact I-3 context-actor context)"
printf '%s\n' '# context' > "$TMP/$context_artifact"
workflow advance I-3 context-actor context contract design-authority "$context_artifact" >/dev/null

workflow claim I-3 design-actor >/dev/null
contract_artifact="$(workflow artifact I-3 design-actor contract)"
printf '%s\n' '# contract' > "$TMP/$contract_artifact"
workflow advance I-3 design-actor contract plan-review technical-reviewer "$contract_artifact" >/dev/null

workflow claim I-3 review-actor >/dev/null
draft_artifact="$(workflow artifact I-3 review-actor plan-review-draft)"
printf '%s\n' '# independent draft' 'status: draft' > "$TMP/$draft_artifact"
workflow pause I-3 review-actor "$draft_artifact" >/dev/null
show="$(workflow show I-3)"
grep -q 'stage: plan-review' <<<"$show"
grep -q "checkpoint_artifact: $draft_artifact" <<<"$show"
grep -q 'claimed_by: $' <<<"$show"
next="$(workflow next-action I-3 plan-review technical-reviewer 1 0)"
grep -q 'action: stop' <<<"$next"
grep -q 'reason: human-review-discussion' <<<"$next"

workflow claim I-3 review-actor >/dev/null
final_review="$(workflow artifact I-3 review-actor plan-review)"
printf '%s\n' '# final review' 'verdict: approved' > "$TMP/$final_review"
workflow advance I-3 review-actor plan-review freeze design-authority "$final_review" >/dev/null
show="$(workflow show I-3)"
grep -q 'stage: freeze' <<<"$show"
grep -q 'checkpoint_artifact: $' <<<"$show"

workflow claim I-3 design-actor >/dev/null
freeze_artifact="$(workflow artifact I-3 design-actor freeze)"
printf '%s\n' '# frozen plan' > "$TMP/$freeze_artifact"
workflow advance I-3 design-actor freeze human-freeze human "$freeze_artifact" >/dev/null
if workflow claim I-3 feedback-actor >/dev/null 2>&1; then
  echo 'expected ordinary claim at human-freeze to block' >&2
  exit 1
fi
workflow claim I-3 feedback-actor --human-feedback >/dev/null
if workflow approve I-3 >/dev/null 2>&1; then
  echo 'expected approval to block while human feedback owns the decision' >&2
  exit 1
fi
feedback_artifact="$(workflow artifact I-3 feedback-actor human-feedback)"
printf '%s\n' '# human objection' > "$TMP/$feedback_artifact"
workflow advance I-3 feedback-actor human-freeze freeze design-authority "$feedback_artifact" >/dev/null
show="$(workflow show I-3)"
grep -q 'stage: freeze' <<<"$show"
grep -q 'required_role: design-authority' <<<"$show"

workflow claim I-3 design-actor >/dev/null
refreeze_artifact="$(workflow artifact I-3 design-actor freeze)"
printf '%s\n' '# revised frozen plan' > "$TMP/$refreeze_artifact"
workflow advance I-3 design-actor freeze human-freeze human "$refreeze_artifact" >/dev/null
workflow approve I-3 >/dev/null
show="$(workflow show I-3)"
grep -q 'stage: prepare' <<<"$show"
grep -q 'required_role: implementation-worker' <<<"$show"
grep -q 'claimed_by: $' <<<"$show"

echo 'workflow recovery tests: PASS'
