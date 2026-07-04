# Glossary

## Agent

An AI coding collaborator operating inside the repository.

## Harness

The repo-level operating model that tells humans and agents how to turn intent
into safe product changes.

## Feature Intake

The classification step that turns a prompt into tiny, normal, or high-risk work
before implementation begins.

## Lane

The risk tier chosen at intake — `tiny`, `normal`, or `high-risk` — which
decides how much process, validation, and durable record a task needs.

## Product Contract

The current expected behavior of the product. Product docs plus executable tests
become the living contract once implementation exists.

## Story Packet

A story-sized work file or folder describing the product contract, affected
docs, design notes, and validation expectations for a feature.

## Verification Gate

A mechanical proof check run before a task is closed. `story verify <id>`
executes a story's `verify_command`; `story verify-all` runs every configured
story proof command.

## Trace

A structured record of what an agent did during a task: outcome, files changed,
and any harness friction discovered. This project runs the lean trace profile
(see `docs/TRACE_SPEC.md`).

## Tool Registry

The compiled and user-registered tool manifest exposed by
`scripts/bin/harness-cli query tools` and documented in `docs/TOOL_REGISTRY.md`.
It lets a workflow step look up what external capability is equipped and present.

## Backlog

Harness improvement / friction items recorded with
`scripts/bin/harness-cli backlog add` and reviewed with `query backlog`. The
harness grows from recorded friction.

## Durable Layer

The SQLite database and CLI (`scripts/bin/harness-cli`) that store operational
records (intakes, stories, decisions, backlog items, traces) as structured,
queryable data. Policy docs describe how to work; the durable layer stores what
happened.

## Product Delta

A product-facing change: code, tests, API shape, data model, or product docs.

## Harness Delta

A docs, template, validation, backlog, or decision update that makes future
agent work safer or easier.
