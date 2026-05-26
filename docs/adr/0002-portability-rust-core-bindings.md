# ADR-0002 — Portability: Rust core, generated bindings, no reimplementation

- Status: Accepted
- Date: 2026-06-29

## Context

Distribution logic must behave identically across CLI, native hosts, and future
bindings. Reimplementing manifest parsing, planning, and policy gates per
platform would multiply the audit surface and create semantic drift.

## Decision

Use one Rust core (`gear-cable-core`) as the source of truth. Non-Rust surfaces
may use generated bindings, but they must not reimplement distribution logic.
Native code may provide UI or thin host glue only.

## Consequences

- One policy engine is audited and tested.
- Cross-platform parity is structural rather than sampled.
- CI must keep `gear-cable-core` portable, including a compile-only wasm gate.
