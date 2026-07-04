# Scripts

This directory contains the Harness durable-layer tooling for this project.

## Harness CLI

The prebuilt Rust CLI at `scripts/bin/harness-cli` (macOS/Linux) or
`scripts/bin/harness-cli.exe` (Windows) is the primary interface for the durable
layer. Run all Harness operational work through it.

```bash
scripts/bin/harness-cli init                 # Create the database
scripts/bin/harness-cli intake ...           # Record a feature intake classification
scripts/bin/harness-cli story add ...        # Add a story (with --verify "<command>")
scripts/bin/harness-cli story update ...     # Update status / proof flags / verify command
scripts/bin/harness-cli story verify US-001  # Run the story's verify_command
scripts/bin/harness-cli decision add ...     # Add a durable decision record
scripts/bin/harness-cli backlog add ...      # Record a friction / improvement item
scripts/bin/harness-cli trace ...            # Record an agent execution trace
scripts/bin/harness-cli query matrix         # Proof status (add --numeric for 1/0)
scripts/bin/harness-cli query backlog        # Improvement items (--open / --closed)
scripts/bin/harness-cli migrate              # Apply pending schema migrations
scripts/bin/harness-cli --version
```

Run `scripts/bin/harness-cli help` or `scripts/bin/harness-cli query help` for
full usage. On Windows, use the same commands through
`.\scripts\bin\harness-cli.exe`.

## Conventions

- Proof flags on `story update` are numeric booleans: `1` for yes, `0` for no.
  The CLI rejects `yes`/`no`.
- `story verify <id>` runs the configured `verify_command`; it does not accept
  proof flags. Configure the command with `story add/update --verify`.
- Backlog `--risk` uses Harness lanes, not severity words: `tiny`, `normal`, or
  `high-risk` (use `tiny`, never `low`).
- `query matrix` defaults to human-readable `yes`/`no`; use `--numeric` when
  copying values back into `story update`.

## Database And Schema

- The database file (`harness.db`) is `.gitignore`d — it is local to each clone.
- The schema lives in `scripts/schema/` and is version-controlled. Files are
  named `NNN-description.sql`; run `harness-cli migrate` to apply pending ones.
- `HARNESS_DB_PATH=/path/to/harness.db` overrides the database location when a
  workflow needs to operate on an isolated copy.
- Direct SQLite inspection is fine for reads, but normal Harness use should go
  through the CLI.
