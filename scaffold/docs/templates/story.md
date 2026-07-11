# US-XXX Story Title

## Status

planned

## Lane

tiny | normal | high-risk

## Product Contract

Describe the behavior this story must make true.

## Relevant Product Docs

- `docs/product/...`

## Acceptance Criteria

- Criterion 1.
- Criterion 2.
- Criterion 3.

## Design

- Commands:
- Queries:
- API:
- Tables:
- Domain rules:
- UI surfaces:

## Execution Plan

1. Test or proof to add first.
2. Minimal implementation step with exact file/symbol.
3. Verification command.

## Stop Conditions

- Product contract becomes ambiguous.
- A frozen design assumption contradicts the code.
- Validation requirements would need to be weakened.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id <id> --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | |
| Integration | |
| E2E | |
| Platform | |
| Release | |

## Harness Delta

Document any harness updates made or proposed because of this story.

## Evidence

Add commands, reports, screenshots, or links after validation exists.
