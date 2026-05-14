# ADR-0003 — Forward-only distribution: compensate, not rollback

- Status: Accepted
- Date: 2026-06-29

## Context

Publishing is not deployment. Registries, release tags, and store submissions are
append-only or practically irreversible. A design that says rollback would hide
that reality.

## Decision

Distribution is append-only and forward-only:

- `plan` and evidence gates run before publish;
- `publish-prerelease` exposes only explicit pre-release artifacts;
- `promote` moves a stable pointer onto an already-smoked artifact;
- recovery is `compensate`, never rollback.

## Consequences

- No rollback theater in APIs, audit logs, or docs.
- Provenance and checks become mandatory before irreversible publication.
- Channel-specific recovery stays inside channel implementations.
