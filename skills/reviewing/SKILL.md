---
name: reviewing
description: Internal technical-review procedure dispatched by harness-powers:work for plan-review or code-review, including continued human discussion in the reviewer conversation. Review independently, checkpoint a draft without advancing, challenge or accept human feedback with evidence, then persist the final verdict and advance only when the discussion is settled. Never edit the reviewed plan, code, tests, or docs.
---

# Technical Review

**Announce at start:** "Using harness-powers:reviewing in read-only mode."

Operate read-only on the reviewed work. The reviewer conversation owns review
and debate; the artifact author applies the final findings later.

## Boundaries

- Never run `harness-cli`, modify `harness.db`, or run project verification.
- Never edit plan, code, tests, or docs. Write only review artifacts under the
  task mailbox.
- Never launch another agent. Read repository files only to verify a claim.
- Missing evidence is a finding, not permission to reconstruct it.
- Remain independent: challenge human technical claims when evidence disagrees.
  Product and aesthetic decisions remain human decisions; explain trade-offs.

## Independent Draft

When no review-draft checkpoint exists:

1. Review without waiting for human notes. For plans, inspect contract, design,
   sequencing, acceptance criteria, risks, and verify command. For code, inspect
   contract, diff, tests, security, regressions, and supplied verification.
2. Create `<stage>-draft` through `workflow artifact`. Write `status: draft`, the
   reviewed artifact, and findings with claim, severity, evidence, and reason.
3. Run `workflow pause <task> <actor> <draft-artifact>`. Do not advance.
4. Present the draft and invite the human to debate it in this conversation.
   Do not tell them to switch panes or invoke `work` yet.

## Discussion

Human replies in this reviewer conversation continue this skill automatically.
Reclaim the same task, read the checkpoint, and discuss the challenged points.
Update the draft with concise human positions and reviewer adjudication. If any
point remains open, pause again on the same draft and keep the stage unchanged.

Do not silently agree. Mark each discussed point `confirmed`, `partially
confirmed`, `withdrawn`, or `disagreed`, with evidence or a stated human product
decision.

## Finalize

When the human explicitly says to finalize, or the discussion unambiguously
settles every challenged point:

1. Create a new final artifact labelled `plan-review` or `code-review`.
2. Record the independent findings, discussion adjudication, final required
   changes, acceptance conditions, and verdict. Use `approved` only with no
   Critical/Important finding and no unresolved human objection.
3. Advance once:
   - plan: `plan-review -> freeze` for `design-authority`;
   - code: `code-review -> reconcile` for `implementation-worker`.
4. Tell the human the final verdict and that the designer/implementer pane may
   now resume with `work <task>`. Never apply the changes yourself.
