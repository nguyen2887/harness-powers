<!-- HARNESS-POWERS:BEGIN -->
## Harness Powers Workflow

This repo uses the Harness scaffold with the harness-powers skill pipeline.

**Every task starts with `harness-powers:intake` — BEFORE any other response, clarifying question, or file exploration.**

Pipeline:

- intake → (tiny) → implementing → done
- intake → (normal / high-risk) → designing → implementing → done
- Any bug, test failure, or unexpected behavior → `harness-powers:debugging`
- Every task exits ONLY through `harness-powers:done` (verification + review gate + trace)

Precedence: in this repo, harness-powers REPLACES the Superpowers process skills. Do NOT invoke: superpowers:brainstorming, superpowers:writing-plans, superpowers:executing-plans, superpowers:subagent-driven-development, superpowers:systematic-debugging, superpowers:test-driven-development, superpowers:verification-before-completion, superpowers:requesting-code-review, superpowers:finishing-a-development-branch. Superpowers utility skills (superpowers:using-git-worktrees, superpowers:dispatching-parallel-agents) remain available.

Trace profile: LEAN — Minimal/Standard tiers only; the Detailed tier in `docs/TRACE_SPEC.md` is retired here. Low `score-trace` values are expected and are not a quality problem.

External tool tuning (review/explore model, reasoning effort): `harness-powers.toml` at the repo root.
<!-- HARNESS-POWERS:END -->
