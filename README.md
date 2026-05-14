# Link Cable

Rust-first distribution substrate for multi-platform developer tools.

Link Cable owns the release/distribution layer: build matrices, artifact graphs,
release manifests, install/update/doctor flows, checksums, signatures,
provenance, and channel-specific publishing primitives. Agent-O-Matic is the
first consumer; distribution logic lives here rather than inside the autonomy
product.

## Doctrine

- **Forward-only releases** — publish is append-only; recovery is `compensate`, not rollback.
- **Signed artifacts** — checksums, signatures, SBOM, and provenance are modeled as release gates.
- **Sovereign install floors** — every supported platform needs at least one store-free install path, with the iOS EU DMA caveat documented explicitly.
- **One Rust core** — generated bindings may expose the core, but distribution logic is not reimplemented in Swift/Kotlin/TypeScript.
- **Dry-run by default** — planning and doctor commands are safe; mutating publish/promote commands will require explicit opt-in.

## Workspace

- `crates/link-cable-core` — pure Rust core: manifests, platforms, artifact graph, policy gates.
- `crates/link-cable-dist` — side-effect boundary for distribution channels.
- `crates/link-cable-cli` — `link-cable` command surface.

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

## License

MIT © Constantin Jais
