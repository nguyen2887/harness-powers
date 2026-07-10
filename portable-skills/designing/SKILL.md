---
name: designing
description: Use after intake chose lane normal or high-risk, before any implementation - collaborative design through one-question-at-a-time dialogue, harness-native artifacts (story packet, decision record), and an external plan-review gate. Never use for tiny lane.
---

# Designing

Turn the classified request into an approved, reviewed, harness-native plan.

**Announce at start:** "Designing: turning the classified request into a reviewed plan."

<HARD-GATE>
Do NOT write implementation code, scaffold projects, or edit files outside `docs/` until (1) the plan-review gate has passed AND (2) your human partner has approved the design. No exceptions for "simple" work — it was routed here because it is not tiny.
</HARD-GATE>

## Process

1. **Explore context** — relevant `docs/product/*`, `docs/stories/*`, `docs/decisions/*`, and the affected code, using your own read tools. For a very wide or cheap scan you may open a separate explorer pane (e.g. Gemini/agy) and paste back what it finds — but verify any file paths it reports before relying on them.
2. **Clarify** — ask questions ONE at a time, multiple choice preferred. Understand purpose, constraints, success criteria. If the request spans multiple independent subsystems, flag it and decompose into separate stories first.
3. **Propose 2-3 approaches** — with trade-offs, lead with your recommendation and why.
4. **Write artifacts** (by lane, below).
5. **Plan-review gate** (below).
6. **Human approval** — present the reviewed design; on approval continue with the **implementing** skill.

## Artifacts

**Normal lane:**
- One story file from `docs/templates/story.md` → `docs/stories/US-XXX-<slug>.md`. Fill Product Contract, Acceptance Criteria, Design Notes (put execution steps here — a separate execplan file only when genuinely long), Validation table.
- Register: `harness-cli story add --id US-XXX --title "<title>" --lane normal --verify "<command>"`

**High-risk lane:**
- Story folder from `docs/templates/high-risk-story/` → `docs/stories/epics/<epic>/US-XXX-<slug>/` with `overview.md`, `design.md`, `execplan.md`, `validation.md` all filled.
- Decision record: when behavior, architecture, authorization, data ownership, API shape, or validation requirements change — `docs/decisions/NNNN-<slug>.md` from `docs/templates/decision.md`, then `harness-cli decision add --id NNNN-<slug> --title "<title>" --doc docs/decisions/NNNN-<slug>.md`
- Register: `harness-cli story add --id US-XXX --title "<title>" --lane high-risk --verify "<command>"`

**Every story MUST get a real `--verify` command** — the mechanical proof that the **done** skill will run. "TBD" is not a verify command. If no runnable proof exists yet, the first task in the plan is creating one.

Plans assume the implementer has zero context: name the files to touch per task, the tests to write, the commands to run. Bite-sized steps (2-5 minutes each). DRY. YAGNI.

## Plan-Review Gate

The plan is reviewed in a **separate, human-driven reviewer pane — never a sub-invocation you launch**. You pause and hand off; your human runs the reviewer; you record the outcome. A `PreToolUse` hard gate blocks code edits until that approval is recorded.

1. **Hand off to the reviewer — do NOT run it yourself.** The reviewer lives in a separate pane your human drives (e.g. a Codex/GPT terminal, read-only). Do NOT spawn, `exec`, or open a Task/sub-agent to review — that pane is sandboxed and routing the review is the human's job. PAUSE, hand your human the plan artifact paths (`<story/design/execplan paths>`), and ask them to have the reviewer flag, as a senior engineer: missing requirements, contradictions, untestable acceptance criteria, hidden risks, wrong sequencing, scope creep — each as Critical / Important / Minor with a concrete reason, no praise. Wait for the verdict before continuing.
   - *Solo (no review pane handy)?* Do one honest self-review pass with fresh eyes (placeholder scan, internal contradictions, ambiguity, scope check, verify-command check); note `external-review: inactive`.
2. **Triage** — verify each finding technically before acting. No performative agreement, no blind changes. Critical/Important → fix the design, then re-review. Minor → fix, or reject with a one-line technical reason.
3. **Stop rule** — loop until a round yields zero NEW Critical/Important findings. 2-3 rounds is normal. More than 4 → stop and escalate to your human partner; the design likely has a structural problem.
4. **Record the approval — this unlocks the code-edit hard gate.** After the review passes, record it. You (the orchestrator/human) record it; the reviewer pane stays read-only and never writes Harness state: `harness-cli intervention add --story US-XXX --type approval --source reviewer --description "plan-review passed: <reviewer model, rounds, key findings>"` (self-review → `--description "self-review; external-review inactive"`). Until this record exists, the `PreToolUse` gate keeps blocking every edit outside `docs/`.

## Red Flags

| Thought | Reality |
| --- | --- |
| "The design is obvious, skip the questions" | Obvious designs hide unexamined assumptions. Ask anyway. |
| "I'll write the story after coding" | The story IS the approval surface. Artifacts before code. |
| "The reviewer will just nitpick" | Cross-model review catches your blind spots. Run the gate. |
| "The reviewer said X, so I'll change it" | Verify X first. Reviewers must be right, not just confident. |
| "Verify command can be added later" | Later never comes. No verify, no story. |
