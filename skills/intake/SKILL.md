---
name: intake
description: Internal intake procedure used by harness-powers:work for a new task in a Harness repo. Classify and record the request before clarification or exploration, return the intake id and lane to the work resolver, and do not create a human-copy handoff.
---

# Harness Intake

Classify work before any exploration or edit.

**Announce at start:** "Using harness-powers:intake to classify this task."

`harness-cli` means `scripts/bin/harness-cli` on macOS/Linux or
`.\scripts\bin\harness-cli.exe` on Windows.

## Checklist

1. If `harness.db` is missing, run `harness-cli init`.
2. Run `harness-cli tool check`.
3. Choose the input type:
   - `new-spec`, `spec-slice`, `change-request`, `new-initiative`,
     `maintenance`, or `harness-improvement`
4. Mark every applicable risk flag: Auth, Authorization, Data model,
   Audit/security, External systems, Public contracts, Cross-platform,
   Existing behavior, Weak proof, Multi-domain.
5. Choose the lane:
   - 0-1 flags: tiny or normal according to code impact
   - 2-3 flags: normal with stronger validation
   - 4+ flags: high-risk
   - any hard gate: high-risk unless the human narrows scope
6. Record: `harness-cli intake --type <type> --summary "<one line>" --lane <lane>`.
   Keep the printed intake id.
7. State `Lane: <lane>. Reason: <flags/rationale>.`
8. Return the intake id, lane, summary, and flags to the active `work` resolver.
   The resolver creates the mailbox task at `context`; do not print a handoff for
   the human to copy and do not launch another actor.

Hard gates: Auth, Authorization, data loss/migration, Audit/security, external
provider behavior, or weakening validation. Tiny may cover dependency wiring,
server entrypoints, and smoke endpoints only when no domain schema, CRUD, auth,
contract, or migration behavior changes.

Bug/test failure requests still pass through intake, then context; the context
worker prepares reproduction evidence and hands off to debugging.
