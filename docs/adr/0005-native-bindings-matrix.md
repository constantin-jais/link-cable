# ADR-0005 — Native bindings matrix

- Status: Accepted
- Date: 2026-06-29

## Context

Link Cable owns distribution logic, not application UI. Future native surfaces may
need to call the core from Swift, Kotlin, C#, JavaScript, or direct Rust hosts.

## Decision

Keep the binding matrix explicit and generated:

| Platform | Binding direction | Rule |
| --- | --- | --- |
| Web | wasm-bindgen / component model | core logic compiled, not rewritten |
| Apple | UniFFI Swift or equivalent | UI/glue only outside Rust |
| Android | UniFFI Kotlin or equivalent | UI/glue only outside Rust |
| Windows | WIT/C# or generated FFI | maturity verified before use |
| Linux | direct Rust link first | preferred zero-FFI vertical |

App stores, notarization, Windows signing, mobile UI, and native installers are deferred until the policy and signing isolation are designed.

## Consequences

- The first implementation can stay CLI + Rust core.
- Binding decisions are recorded before platform UI work starts.
- Generated bindings preserve the single-core doctrine.
