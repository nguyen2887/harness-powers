# Test Matrix

The behavior-to-proof matrix is stored in the durable layer, not in this file.
Do not maintain a markdown table here — it would drift from the database.

Query current proof status:

```bash
scripts/bin/harness-cli query matrix
scripts/bin/harness-cli query matrix --numeric   # for copying values back into `story update`
```

Record proof as stories are built (numeric booleans, `1`/`0`):

```bash
scripts/bin/harness-cli story update --id US-XXX --unit 1 --integration 1 --e2e 0 --platform 0
```

## Proof Layer Meaning

- Unit: pure domain and application rules.
- Integration: backend enforcement, data integrity, provider behavior, jobs,
  service contracts.
- E2E: user-visible browser flows.
- Platform: shell, deployment, mobile, desktop, or runtime behavior that cannot
  be proven in lower layers.

A story may ship without every proof column if its packet explains why.
