<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses the Harness scaffold with the harness-powers pipeline. These rules
bind EVERY agent working here — Claude Code, Codex, Antigravity/agy, Grok, or any
other CLI. They are not optional and not Claude-specific.

`harness-cli` below means `scripts/bin/harness-cli` (macOS/Linux) or
`scripts\bin\harness-cli.exe` (Windows).

**Every task starts with intake — before any other response, clarifying question,
or file edit.** Classify the request into a risk lane and record it:
`harness-cli intake --type <type> --summary "<one line>" --lane <tiny|normal|high-risk>`
(input types and lane rules: `docs/FEATURE_INTAKE.md`).

Pipeline — one entry, one exit:

- intake → (tiny) → implement → done
- intake → (normal / high-risk) → design → implement → done
- Any bug, test failure, or unexpected behavior → debugging (root cause first), then back
- EVERY task exits ONLY through the **done** gate (fresh verification + code-review gate + trace)

### Mandatory gates — do NOT skip, even when the work feels simple

1. **Plan-review gate** — normal/high-risk lane, after design, before writing code.
   Check `harness-cli query tools --capability external-review --status present`.
   Provider present → run it over the plan, fix Critical/Important findings, loop
   until a round adds no new Critical/Important. Provider absent → one honest
   self-review pass; note `external-review: inactive`. Skipping this gate is a
   process violation, not a shortcut.

2. **Code-review gate** — inside done, before ANY completion claim. Same reviewer
   loop over the actual diff. No "done" / "it works" / "fixed" / "passing" claim is
   allowed outside the done gate, and none without fresh verification output pasted
   as evidence.

If a gate's reviewer is unavailable it degrades to self-review — it is never
silently dropped.

### Where the step-by-step procedures live

The detailed skills (intake, designing, implementing, debugging, done) live in your
CLI's skills directory (`.codex/skills/`, `.agents/skills/`, `.grok/skills/`, or the
harness-powers Claude Code plugin). **If those skills are not loaded for your CLI,
the rules in this block are still binding** — follow the pipeline and both gates
from here plus `docs/`.

Before starting work, run `harness-cli query matrix` to see current
behavior-to-proof status (this also lets a fresh CLI resume mid-project).

External tool tuning (review/explore model, reasoning effort): `harness-powers.toml`
at the repo root.
<!-- HARNESS-POWERS:END -->
