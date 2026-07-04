# Harness Backlog

Harness improvement items are stored in the durable layer, not in this file.
Do not maintain a markdown list here — it would drift from the database.

Record friction / improvement items:

```bash
scripts/bin/harness-cli backlog add --title "<short name>" --pain "<what was hard>"
scripts/bin/harness-cli backlog add --title "<name>" --pain "<pain>" --risk tiny --predicted "<expected impact>"
```

Review and close:

```bash
scripts/bin/harness-cli query backlog --open
scripts/bin/harness-cli query backlog --closed
scripts/bin/harness-cli backlog close --id <id> --outcome "<measured result>"
```

Risk uses the lane vocabulary: `tiny`, `normal`, or `high-risk` (`low` is not
valid).
