# Gear Cable

**Layer:** Gear — Infrastructure  
**Role:** Rust-first release and distribution wiring  
**Mission:** define how tools become reproducible, verifiable, installable artifacts across targets.

---

## Stack Role

- **Maturity:** `contract-first`.
- **Current increment:** P1 CLI/library proof.
- **Learning value:** reproducible release planning, checksums, target matrices, and distribution boundaries.
- **Next quality step:** connect release plans to `gear-depot` artifact manifests and verification.

See the ecosystem cockpit in [`constantin-jais/ecosystem/status.md`](https://github.com/constantin-jais/constantin-jais/blob/main/ecosystem/status.md).

## Purpose

`gear-cable` is the interconnection and release substrate of the ecosystem. It treats Rust as a strong universal source and produces explicit artifact plans for multiple platforms and runtimes.

It connects build outputs to distribution without absorbing product logic.

## Owns

- Artifact plans, checksums, signatures, provenance, and release metadata.
- Forward-only release flows and install floors.
- Cross-target packaging/distribution conventions.
- Channel adapters for append-only publication flows, including App Store Connect for iOS-capable Rumble products.
- Runtime and platform wiring needed to ship developer tools reliably.

## Does Not Own

- Supply-chain registry/cache policy: belongs to `gear-depot`.
- Long-term context or semantic memory: belongs to `gear-memory`.
- Product workflows or UI: belongs to Rumble.
- Agent decisions: belongs to Bolt.

## Allowed Dependencies

- Publishes metadata and artifacts that `gear-depot` can verify/distribute.
- Supports Wrench and Rumble projects that need reproducible release flows.
- Should remain self-hostable and independent from proprietary release platforms.

## Product Vision Challenge

`gear-cable` must stay distribution plumbing, not application runtime logic. Its value is reproducible, sovereign delivery across targets.
