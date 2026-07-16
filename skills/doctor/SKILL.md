---
name: doctor
description: Use when the human asks whether Harness is installed, current, trusted, wired, healthy, or ready across Claude Code, Codex, and Grok. Run the read-only Harness doctor and report missing, stale, duplicate, or untrusted activation surfaces without patching them implicitly.
---

# Harness Doctor

**Announce at start:** "Running the read-only Harness installation and activation doctor."

Run from the wrapper checkout root:

```bash
.harness-powers/bin/harness-powers-doctor
```

Report every `FAIL` and `WARN`, the active-task summary, and the exact corrective
action. Do not install, trust, rewrite, or delete anything unless the human asks.
