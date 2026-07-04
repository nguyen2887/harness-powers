---
name: intake
description: Use when starting ANY task that could change code, docs, or behavior in a repo that has the Harness scaffold (scripts/bin/harness-cli exists) - classifies the request into a risk lane and records intake BEFORE any other response or action. Entry gate for the harness-powers pipeline. Do not use in repos without the Harness scaffold.
---

# Harness Intake

Every task enters through this gate. No code, no edits, no "quick fix" before a lane is chosen and recorded. The human does not need to classify risk — you do, mechanically.

**Announce at start:** "Using harness-powers:intake to classify this task."

`harness-cli` below means `scripts/bin/harness-cli` (macOS/Linux) or `.\scripts\bin\harness-cli.exe` (Windows).

## Checklist

Create a todo per item, complete in order:

1. **Init check** — if `harness.db` does not exist, run `harness-cli init`
2. **Tool scan** — `harness-cli tool check` (refreshes present/missing status for review and explore providers)
3. **Classify input type** (table below)
4. **Run the risk checklist** → choose lane (rules below)
5. **Record intake** — `harness-cli intake --type <type> --summary "<one line>" --lane <lane>`. Note the intake id the CLI prints; the done gate needs it for the trace.
6. **Announce and route** — state `Lane: <lane>. Reason: <flags/rationale>.` then invoke the next skill.

## Input Types

| Type | Use when |
| --- | --- |
| `new-spec` | Turning a user-provided project spec into harness-ready docs |
| `spec-slice` | Implementing selected behavior from an accepted spec |
| `change-request` | Changing, fixing, or refining accepted behavior |
| `new-initiative` | Adding a larger product area that needs multiple stories |
| `maintenance` | Dependency, architecture, performance, security, or operational work |
| `harness-improvement` | Improving how humans and agents collaborate in this repo |

If the CLI rejects a type string, run `harness-cli intake --help` and use the closest supported value.

## Risk Checklist

Mark one flag per item the work touches:

| Flag | Applies when the work touches |
| --- | --- |
| Auth | login, logout, sessions, JWT, password, refresh token |
| Authorization | roles, permissions, tenant or company scope |
| Data model | schema, migrations, uniqueness, deletion, retention |
| Audit/security | audit logs, privacy, sensitive data, access logs |
| External systems | email, payments, cloud services, provider SDKs, queues, webhooks |
| Public contracts | API shape, response envelope, client-visible behavior |
| Cross-platform | desktop/mobile/browser split, native shell behavior, deep links |
| Existing behavior | already implemented or test-covered behavior changes |
| Weak proof | unclear or missing tests around the affected area |
| Multi-domain | more than one product domain changes at once |

## Lane Rules

```
0-1 flags  -> tiny or normal, based on code impact
2-3 flags  -> normal with stronger validation
4+ flags   -> high-risk
Any hard gate -> high-risk unless the human explicitly narrows scope
```

Hard gates: Auth. Authorization. Data loss or migration. Audit/security. External provider behavior. Removing or weakening validation requirements.

Tiny also covers initial project setup limited to: installing declared dependencies, wiring a server entrypoint, adding a health/smoke endpoint — with no domain schema, CRUD, auth, or migration.

## Routing

- **Bug, test failure, or unexpected behavior** → record intake (usually `change-request`), then invoke `harness-powers:debugging`
- **tiny** → invoke `harness-powers:implementing` directly (no story packet; intake record is the only overhead)
- **normal / high-risk** → invoke `harness-powers:designing`

## Red Flags — STOP, You're Rationalizing

| Thought | Reality |
| --- | --- |
| "This is a one-line change" | One-liners touch auth and contracts too. Run the checklist. |
| "I'll classify after I look around" | Exploration IS work. Classify first; explore inside the lane. |
| "The user already told me exactly what to do" | The lane decides process depth, not permission. Record it. |
| "Intake is overhead for something this small" | Tiny lane costs one CLI call. That is the overhead ceiling. |
| "This is just a question" | If answering leads to edits, it enters the gate. |
| "I remember this repo's lanes" | Flags depend on THIS task. Run the checklist fresh. |
