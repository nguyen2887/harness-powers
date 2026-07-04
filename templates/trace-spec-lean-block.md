<!-- HARNESS-POWERS:LEAN-TRACE:BEGIN -->
## Lean Trace Profile (harness-powers override)

This repo runs the harness-powers lean trace profile:

- Tiny lane: `--summary` and `--outcome` only.
- Normal / high-risk: additionally `--intake`, `--story`, `--changed`, `--friction`.
- The Detailed tier above is RETIRED here. Do not spend effort on `--actions`, `--read`, `--decisions` (decision records in `docs/decisions/` cover that), `--duration`, or `--tokens`.
- Low `score-trace` values are expected under this profile and are not a quality problem.
<!-- HARNESS-POWERS:LEAN-TRACE:END -->
