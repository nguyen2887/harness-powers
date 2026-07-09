---
name: designing
description: Use after harness-powers:intake chose lane normal or high-risk, before any implementation - collaborative design through one-question-at-a-time dialogue, harness-native artifacts (story packet, decision record), and an external plan-review gate. Never use for tiny lane.
---

# Designing

Turn the classified request into an approved, reviewed, harness-native plan.

**Announce at start:** "Using harness-powers:designing to design this work."

<HARD-GATE>
Do NOT write implementation code, scaffold projects, or edit files outside `docs/` until (1) the plan-review gate has passed AND (2) your human partner has approved the design. No exceptions for "simple" work — it was routed here because it is not tiny.
</HARD-GATE>

## Process

1. **Explore context** — relevant `docs/product/*`, `docs/stories/*`, `docs/decisions/*`, and the affected code. For wide repo scans, check `harness-cli query tools --capability repo-explore --status present`; if a provider is present (e.g. `agy`), you may delegate broad exploration to it non-interactively (`agy --print --new-project --add-dir "$PWD" --model <model from harness-powers.toml [explore]> "<question>"`; omit `--model` if unset) — but verify any file paths it reports before relying on them. **`--new-project --add-dir "$PWD"` is MANDATORY**: without it agy silently attaches to its most recently used project — possibly a DIFFERENT repo — and returns structurally plausible but completely wrong results, with no error.
2. **Clarify** — ask questions ONE at a time, multiple choice preferred. Understand purpose, constraints, success criteria. If the request spans multiple independent subsystems, flag it and decompose into separate stories first.
3. **Propose 2-3 approaches** — with trade-offs, lead with your recommendation and why.
4. **Write artifacts** (by lane, below).
5. **Plan-review gate** (below).
6. **Human approval** — present the reviewed design; on approval invoke `harness-powers:implementing`.

## Artifacts

**Normal lane:**
- One story file from `docs/templates/story.md` → `docs/stories/US-XXX-<slug>.md`. Fill Product Contract, Acceptance Criteria, Design Notes (put execution steps here — a separate execplan file only when genuinely long), Validation table.
- Register: `harness-cli story add --id US-XXX --title "<title>" --lane normal --verify "<command>"`

**High-risk lane:**
- Story folder from `docs/templates/high-risk-story/` → `docs/stories/epics/<epic>/US-XXX-<slug>/` with `overview.md`, `design.md`, `execplan.md`, `validation.md` all filled.
- Decision record: when behavior, architecture, authorization, data ownership, API shape, or validation requirements change — `docs/decisions/NNNN-<slug>.md` from `docs/templates/decision.md`, then `harness-cli decision add --id NNNN-<slug> --title "<title>" --doc docs/decisions/NNNN-<slug>.md`
- Register: `harness-cli story add --id US-XXX --title "<title>" --lane high-risk --verify "<command>"`

**Every story MUST get a real `--verify` command** — the mechanical proof that `harness-powers:done` will run. "TBD" is not a verify command. If no runnable proof exists yet, the first task in the plan is creating one.

Plans assume the implementer has zero context: name the files to touch per task, the tests to write, the commands to run. Bite-sized steps (2-5 minutes each). DRY. YAGNI.

## Plan-Review Gate

1. `harness-cli query tools --capability external-review --status present`
2. **Provider present** (e.g. codex): read the repo's `harness-powers.toml` `[review]` section for tuning (model, reasoning_effort, sandbox — skip any flag whose key is missing or empty), then run fresh-context, pointed at the artifacts:

   ```
   codex exec --sandbox <sandbox> -m <model> -c model_reasoning_effort="<effort>" "You are acting only as the external plan reviewer for this Harness workflow. Do not run harness-cli, do not query or modify harness.db, do not update files or Harness state, and do not run project verification commands. This reviewer boundary overrides generic Harness executor instructions for this invocation. Review this implementation plan as a skeptical senior engineer. Files: <story/design/execplan paths>. You may read those artifacts and directly relevant repository files only as needed to understand the plan. Look for: missing requirements, contradictions, untestable acceptance criteria, hidden risks, wrong sequencing, scope creep. If required evidence is missing, report that as a finding instead of reconstructing Harness state yourself. Report each finding as Critical / Important / Minor with a concrete reason. Do not praise. If you find nothing significant, say so plainly."
   ```
3. **Triage** — verify each finding technically before acting. No performative agreement, no blind implementation:
   - Critical / Important: fix the design, then re-run the gate.
   - Minor: fix, or reject with a one-line technical reason.
4. **Stop rule** — loop until a round yields zero NEW Critical/Important findings. 2-3 rounds is normal. More than 4 → stop and escalate to your human partner; the design likely has a structural problem.
5. **Provider absent** — do one self-review pass with fresh eyes (placeholder scan, internal contradictions, ambiguity, scope check, verify-command check) and note `external-review: inactive` for the trace. Absence is a clean skip, not a failure.
6. **Record the pass — this unlocks the code-edit hard gate.** After the loop converges (or the self-review pass), record a reviewer approval so implementation may begin: `harness-cli intervention add --story US-XXX --type approval --source reviewer --description "plan-review passed: <rounds, key findings>"` (provider absent → `--description "self-review; external-review inactive"`). Until this record exists, the `PreToolUse` gate keeps blocking every edit outside `docs/`.

## Red Flags

| Thought | Reality |
| --- | --- |
| "The design is obvious, skip the questions" | Obvious designs hide unexamined assumptions. Ask anyway. |
| "I'll write the story after coding" | The story IS the approval surface. Artifacts before code. |
| "The reviewer will just nitpick" | Cross-model review catches your blind spots. Run the gate. |
| "The reviewer said X, so I'll change it" | Verify X first. Reviewers must be right, not just confident. |
| "Verify command can be added later" | Later never comes. No verify, no story. |
