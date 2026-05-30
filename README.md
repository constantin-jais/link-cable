# gear-cable

> Rust-first distribution substrate for multi-platform developer tools — build matrices, artifact graphs, release manifests, checksums, signatures, provenance, and sovereign install floors.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Rust 1.95+](https://img.shields.io/badge/Rust-1.95%2B-orange.svg)](https://www.rust-lang.org)
[![CI](https://github.com/constantin-jais/gear-cable/actions/workflows/ci.yml/badge.svg)](https://github.com/constantin-jais/gear-cable/actions/workflows/ci.yml)

> **Status:** `v0` · WIP — core manifest/artifact model proven; install/update/doctor flows in progress.

## Why it exists

Distribution logic for developer tools tends to get reimplemented in each consumer: install scripts, update flows, artifact verification. `gear-cable` extracts that layer into a single Rust core, so cos-matic and other tools get forward-only releases, signed artifacts, and store-free install paths without duplicating the logic.

## Ecosystem

```mermaid
graph TB
    subgraph products["🎯 Rumble products"]
        RL["rumble-lm<br/>Collaborative learning platform"]
        RC["rumble-cos<br/>Public knowledge site"]
    end
    subgraph tools["🛠️ Sovereign tooling"]
        CM["cos-matic<br/>Agent config + autonomous code-ops"]
        WL["wrench-loader<br/>Document ingestion worker"]
        GM["gear-memory<br/>Local agent context"]
    end
    subgraph infra["⚙️ Infrastructure"]
        GC["gear-cable<br/>Distribution substrate"]
        GD["gear-depot<br/>Registry proxy/cache"]
        VI["vault-inspector<br/>Postgres security audit"]
    end
    RL --> WL
    RL --> GM
    RL --> VI
    RL --> GD
    RL --> GC
    RC --> RL
    CM --> GC
    WL --> GM
    style GC fill:#dbeafe,stroke:#2563eb,stroke-width:2px
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
| `gear-cable-core` | Pure Rust core: manifests, platforms, artifact graph, policy gates |
| `gear-cable-dist` | Side-effect boundary for distribution channels                     |
| `gear-cable-cli`  | `gear-cable` command surface                                       |

## Quick start

```bash
cargo run -p gear-cable-cli -- doctor
cargo run -p gear-cable-cli -- plan --manifest examples/cos-matic/gear-cable.toml
cargo run -p gear-cable-cli -- plan --manifest examples/cos-matic/gear-cable.toml --format json
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
| [cos-matic](https://github.com/constantin-jais/cos-matic)     | Primary consumer — distribution substrate for cosmatic releases |
| [rumble-lm](https://github.com/constantin-jais/rumble-lm)          | Sovereign learning platform                                |
| [wrench-loader](https://github.com/constantin-jais/wrench-loader)         | Document ingestion worker                                  |
| [gear-memory](https://github.com/constantin-jais/gear-memory)         | Local agent context layer                                  |
| [gear-depot](https://github.com/constantin-jais/gear-depot)       | Sovereign registry proxy / cache                           |
| [vault-inspector](https://github.com/constantin-jais/vault-inspector) | Postgres security audit                                    |

## License

MIT © Constantin Jais
