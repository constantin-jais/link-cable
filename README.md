# link-cable

> Rust-first distribution substrate for multi-platform developer tools — build matrices, artifact graphs, release manifests, checksums, signatures, provenance, and sovereign install floors.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Rust 1.95+](https://img.shields.io/badge/Rust-1.95%2B-orange.svg)](https://www.rust-lang.org)
[![CI](https://github.com/constantin-jais/link-cable/actions/workflows/ci.yml/badge.svg)](https://github.com/constantin-jais/link-cable/actions/workflows/ci.yml)

> **Status:** `v0` · WIP — core manifest/artifact model proven; install/update/doctor flows in progress.

## Why it exists

Distribution logic for developer tools tends to get reimplemented in each consumer: install scripts, update flows, artifact verification. `link-cable` extracts that layer into a single Rust core, so Agent-O-Matic and other tools get forward-only releases, signed artifacts, and store-free install paths without duplicating the logic.

## Ecosystem

```mermaid
graph TB
    subgraph product["🎯 Product"]
        RL["Presto-Matic · rumble-lm<br/>Collaborative Learning App"]
    end
    subgraph agentic["🤖 Agentic Tools"]
        AOM["agent-o-matic<br/>Config Compiler + Orchestrator"]
        DL["disc-loader<br/>Document Ingestion Worker"]
        MC["memory-card<br/>Local Agent Context"]
    end
    subgraph devops["🔧 DevOps Tools"]
        LC["link-cable<br/>Distribution Substrate"]
        SD["supply-depot<br/>Registry Proxy / Cache"]
        VI["vault-inspector<br/>Postgres Security Audit"]
    end
    RL --> DL
    RL --> MC
    RL --> VI
    RL --> SD
    RL --> LC
    AOM --> LC
    DL --> MC
    style LC fill:#dbeafe,stroke:#2563eb,stroke-width:2px
```

## Doctrine

- **Forward-only releases** — publish is append-only; recovery is `compensate`, not rollback.
- **Signed artifacts** — checksums, signatures, SBOM, and provenance are modeled as release gates.
- **Sovereign install floors** — every supported platform needs at least one store-free install path (iOS EU DMA caveat documented).
- **One Rust core** — generated bindings may expose the core, but distribution logic is not reimplemented in Swift/Kotlin/TypeScript.
- **Dry-run by default** — planning and doctor commands are safe; mutating publish/promote commands require explicit opt-in.

## Workspace

| Crate             | Role                                                               |
| ----------------- | ------------------------------------------------------------------ |
| `link-cable-core` | Pure Rust core: manifests, platforms, artifact graph, policy gates |
| `link-cable-dist` | Side-effect boundary for distribution channels                     |
| `link-cable-cli`  | `link-cable` command surface                                       |

## Quick start

```bash
cargo run -p link-cable-cli -- doctor
cargo run -p link-cable-cli -- plan --manifest examples/agent-o-matic/link-cable.toml
cargo run -p link-cable-cli -- plan --manifest examples/agent-o-matic/link-cable.toml --format json
```

## Development

```bash
cargo fmt --all --check
RUSTFLAGS="-D warnings" cargo clippy --workspace --all-targets --all-features
cargo test --workspace --all-features
./scripts/audit-deps.sh
```

## Related projects

| Repo                                                                  | Role                                                       |
| --------------------------------------------------------------------- | ---------------------------------------------------------- |
| [agent-o-matic](https://github.com/constantin-jais/Agent-O-Matic)     | Primary consumer — distribution substrate for AOM releases |
| [Presto-Matic](https://github.com/constantin-jais/Rumble-LM)          | Sovereign learning platform                                |
| [disc-loader](https://github.com/constantin-jais/disc-loader)         | Document ingestion worker                                  |
| [memory-card](https://github.com/constantin-jais/memory-card)         | Local agent context layer                                  |
| [supply-depot](https://github.com/constantin-jais/supply-depot)       | Sovereign registry proxy / cache                           |
| [vault-inspector](https://github.com/constantin-jais/vault-inspector) | Postgres security audit                                    |

## License

MIT © Constantin Jais
