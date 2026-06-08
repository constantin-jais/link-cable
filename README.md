# Gear Cable

[![CI](https://github.com/constantin-jais/gear-cable/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/constantin-jais/gear-cable/actions/workflows/ci.yml)
[![Security](https://github.com/constantin-jais/gear-cable/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/constantin-jais/gear-cable/actions/workflows/security.yml)
[![Contracts](https://github.com/constantin-jais/gear-cable/actions/workflows/contracts.yml/badge.svg?branch=main)](https://github.com/constantin-jais/gear-cable/actions/workflows/contracts.yml)
[![Release](https://github.com/constantin-jais/gear-cable/actions/workflows/release.yml/badge.svg)](https://github.com/constantin-jais/gear-cable/actions/workflows/release.yml)

**Layer:** Gear — Infrastructure  
**Role:** Rust-first release and distribution wiring  
**Mission:** define how tools become reproducible, verifiable, installable artifacts across targets.

---

## Stack role

- **Layer:** Gear — Infrastructure.
- **Role:** Rust-first release and distribution wiring.
- **Mission:** define how tools become reproducible, verifiable, installable artifacts across targets.
- **Maturity:** `contract-first`.
- **Scale-ready:** no — CLI/library proof exists, but release plans still need Depot manifest verification.
- **Current increment:** P1 CLI/library proof.
- **Learning value:** reproducible release planning, checksums, target matrices, and distribution boundaries.
- **Next quality step:** connect release plans to `gear-depot` artifact manifests and verification.

See the ecosystem cockpit in [`constantin-jais/ecosystem/status.md`](https://github.com/constantin-jais/constantin-jais/blob/main/ecosystem/status.md).

## Dogfooding

This repository is part of the forge dogfooding loop: the ecosystem should use its own tools to make specs, maturity, contracts, releases, and product documentation observable.

Current visible evidence:

- release and CI workflows exercise reproducible release wiring;
- contracts describe target matrices, checksums, and artifact handoff boundaries;
- README maturity notes keep distribution limits explicit.

Expected next evidence:

- publish example release plans and checksum outputs;
- connect release-plan evidence to Gear Depot manifests.

Dogfooding claims should stay backed by visible commands, fixtures, CI workflows, generated reports, or linked docs.

## Forge role

`gear-cable` is Gear distribution plumbing. It helps Rumble products, Wrench tools, and Bolt/Gear components become reproducible, checksummed, installable artifacts without each repo inventing release wiring.

## Boundary

It must not own application runtime logic, product UX, supply-chain registry policy, memory, or agent decisions. Depot owns verification/cache policy; products own user workflows; Bolt owns orchestration.

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
