# ADR-0001 — Product boundary and extraction from cos-matic

- Status: Accepted
- Date: 2026-06-29
- Origin doctrine: cos-matic ADR-0029 through ADR-0032

## Context

cos-matic needs a multi-platform distribution substrate: build matrices,
artifacts, install/update/doctor flows, release manifests, checksums,
signatures, provenance, bindings, and channel publishing primitives. That surface
has its own governance, security model, and release cadence.

## Decision

Extract that distribution substrate into **Link Cable**. cos-matic remains the
autonomy/config/harness product and becomes Link Cable's first consumer.

Link Cable owns:

- platform and artifact models;
- distribution plans;
- release manifests;
- policy gates for append-only publishing, signatures, checksums, provenance,
  SBOM, and sovereign install floors;
- channel-side traits and dry-run-first CLI commands.

Link Cable does not own cos-matic manifest compilation, app UI, GitHub issue
orchestration, or runtime deployment semantics.

## Consequences

- cos-matic can consume distribution as an external tool rather than copying internals.
- Link Cable can be reused by other Rust-first developer tools.
- Distribution-sensitive dependencies and signing policy stay outside the autonomy product.
