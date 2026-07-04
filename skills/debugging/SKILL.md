---
name: debugging
description: Use when encountering any bug, test failure, or unexpected behavior in a Harness repo, BEFORE proposing fixes - root cause investigation first, fix via a reproducing test, then record harness friction if the harness had gaps. Especially under time pressure.
---

# Systematic Debugging

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Announce at start:** "Using harness-powers:debugging to find the root cause."

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

This applies ESPECIALLY when: you're under time pressure, "just one quick fix" seems obvious, a previous fix didn't work, or the issue seems simple. Simple bugs have root causes too. Systematic is faster than thrashing.

## Phase 1 — Investigate

1. **Read the complete error** — full message, full stack trace, line numbers, error codes. It often contains the answer.
2. **Reproduce reliably** — exact steps, every time. Not reproducible → gather more data; do not guess.
3. **Check recent changes** — `git diff`, recent commits, new dependencies, config or environment changes.
4. **Multi-component paths** (CLI → build → deploy, API → service → DB): instrument the boundaries. Log what enters and exits each component; find where reality diverges from expectation. Fix at the divergence, not downstream.

## Phase 2 — Hypothesize and Test

- Form the single clearest hypothesis from the evidence.
- Design the smallest experiment that can FALSIFY it. Run it.
- Confirmed → Phase 3. Refuted → next hypothesis with the new evidence.
- **After 2-3 refuted hypotheses**: stop. Your mental model of the system is wrong somewhere. Question assumptions and architecture, and say so to your human partner before burning more cycles.

## Phase 3 — Fix the Cause

- FIRST write a failing test that reproduces the bug — this becomes the regression test.
- Fix the root cause, never the symptom. No `try/catch`-and-hope, no retry-until-green, no "handle the edge case" wallpaper over a logic error.
- If the honest fix is a workaround, label it a workaround explicitly and ask your human partner before shipping it.

## Phase 4 — Verify and Capture

1. The reproducing test passes; the full suite is green.
2. **Harness gap check** — did this bug expose a harness problem (missing validation command, stale or contradictory doc, missing rule)? In scope → fix it now. Out of scope → `harness-cli backlog add --title "<short name>" --pain "<what was hard>"`.
3. Return to where you came from: mid-implementation → back to `harness-powers:implementing`; standalone bugfix → `harness-powers:done`.

## Red Flags — Back to Phase 1

| Thought | Reality |
| --- | --- |
| "Just try changing X and see" | That's thrashing, not debugging. |
| "It's probably Y, let me fix that" | Probably = no evidence. Falsify it first. |
| "Add a try/catch so it stops crashing" | The crash is the messenger. Find the sender. |
| "One more quick fix attempt" | Two failed fixes means wrong model. Re-investigate. |
| "No time for the process" | Thrashing is slower. It always is. |
