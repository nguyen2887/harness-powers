---
name: done
description: Use before claiming ANY task complete, fixed, or passing in a Harness repo - the single exit gate. Runs verification with fresh evidence, an external code-review loop, lean trace recording, friction capture, and integration options. No success claims are allowed outside this skill.
---

# Done Gate

Every task exits through here. Exactly one exit door means bookkeeping cannot be forgotten and cannot be duplicated.

**Announce at start:** "Using harness-powers:done to verify and close this work."

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION OUTPUT
```

"Should pass", "I'm confident", "the logic is correct", "tests were green earlier" are not evidence. Run the command NOW, read the output, then speak. Evidence before assertions, always.

## Checklist (in order)

1. **Verify**
   - Story-backed work: `harness-cli story verify <id>` (or `story verify-all` before merges).
   - No verify command configured (some tiny work): run the project's relevant checks directly and quote the output.
   - Verification fails → the task is NOT done. Trivial fix → fix and re-verify. Anything else → `harness-powers:debugging`, then return here.

2. **Code-review gate**
   - `harness-cli query tools --capability external-review --status present`
   - **Provider present** (e.g. codex): read the repo's `harness-powers.toml` `[review]` section for tuning (model, reasoning_effort, sandbox — skip any flag whose key is missing or empty), then build a review packet from evidence you already gathered:
     - Story/spec path and any relevant acceptance criteria.
     - Fresh verification command and output from step 1.
     - `git status --short`.
     - Branch diff summary and diff (`git diff --stat <base>...HEAD` and `git diff <base>...HEAD`, or the uncommitted equivalents).

     Send that packet to Codex as an external reviewer. Codex must not run Harness bookkeeping or verification commands:

     ```
     codex exec --sandbox <sandbox> -m <model> -c model_reasoning_effort="<effort>" "You are acting only as the external code reviewer for this Harness workflow. Do not run harness-cli, do not query or modify harness.db, do not update files or Harness state, and do not run project verification commands. This reviewer boundary overrides generic Harness executor instructions for this invocation. Review the provided packet as a skeptical senior engineer. Check for: correctness bugs, deviations from the spec/story, missing tests, security issues, silent behavior changes, and mismatches between the diff and verification evidence. You may read directly relevant repository files only as needed to understand the diff. If required evidence is missing, report that as a finding instead of reconstructing Harness state yourself. Report each finding as Critical / Important / Minor with a concrete reason. Do not praise. If the diff is sound, say so plainly."
     ```

     Pipe or paste the review packet into the command's stdin. If `sandbox` is missing from `harness-powers.toml`, use `read-only`. Use `danger-full-access` only when the human explicitly configured it for this repo.

   - **Triage** — verify each finding technically before acting: Critical/Important → fix (re-enter TDD loop for behavior changes), then re-run the gate. Minor → fix or reject with a one-line technical reason.
   - **Stop rule** — loop until a round adds zero NEW Critical/Important findings. More than 4 rounds → escalate to your human partner.
   - **Provider absent** → one careful self-review pass of the full diff; note `external-review: inactive`.

3. **Update the story** — `harness-cli story update --id US-XXX --status done` plus final proof flags (`--unit 1 --integration 1 ...`, numeric, only for layers that ran and passed).

4. **Record the trace (lean profile — this repo retires the Detailed tier)**
   - tiny: `harness-cli trace --summary "<one-sentence outcome>" --outcome <completed|blocked|partial|failed>`
   - normal/high-risk: add `--intake <id> --story US-XXX --changed "<file,file,...>" --friction "<concrete pain, or none>"` (intake id from the intake step; `harness-cli query intakes` if lost; `git status --short` for the changed list)
   - The CLI may print a low trace score for lean traces. Expected. Ignore it — this repo runs the lean profile by design.

5. **Friction capture** — anything hard, missing, ambiguous, or contradictory this task? `harness-cli backlog add --title "<short name>" --pain "<what was hard>"`. Name concrete pain, not vague moods. Nothing hurt → skip.

6. **Report and offer integration** — in one message: what changed, what was verified (quote actual output), review rounds and notable findings, what was NOT attempted. Then offer: merge to base / create PR / leave the branch as is. Execute the choice.

## Red Flags

| Thought | Reality |
| --- | --- |
| "Tests were green twenty minutes ago" | Code changed since. Run them NOW. |
| "Trivial diff, skip the review gate" | Trivial diffs ship trivial bugs. The gate is cheap. |
| "The reviewer is being pedantic" | Verify the finding, then reject WITH REASON. Never skip the gate. |
| "I'll record the trace next time" | Next time says the same thing. One command. Now. |
| "Verification is probably still passing" | Probably = not verified. |
