# ADR-0004 — Supply-chain and sovereignty floor

- Status: Accepted
- Date: 2026-06-29

## Context

Distribution adds static credential risk and artifact provenance risk. It also
touches gatekeeper channels that can conflict with sovereign deployment goals.

## Decision

- Prefer keyless/OIDC publishing and sigstore-style signing.
- Require checksums, signatures, SBOM, and SLSA provenance as modeled release gates.
- Enforce a store-free sovereign floor for every supported platform.
- Document iOS honestly: outside EU DMA sideload/alternative marketplaces, no full sovereign floor exists.
- Keep static secrets out of git, logs, manifests, fixtures, and audit reports.

## Consequences

- Most channels should need no long-lived token at rest.
- Store channels may exist for reach, but they cannot be the only install path.
- Policy failures stop at `plan`, before build or publish side effects.
