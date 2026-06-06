# ADR-0006 — App Store Connect release channel

- Status: Accepted
- Date: 2026-07-01

## Context

Rumble products that ship iOS builds need a reproducible publication path to TestFlight and App Store review. The selected upstream tool is `rorkai/App-Store-Connect-CLI`.

Directly calling that CLI from each product pipeline would couple product repositories to upstream command/flag changes and duplicate release policy.

## Decision

Gear Cable owns the App Store Connect release adapter as a distribution channel:

- wrapper: `channels/appstore-connect/appstore-release.sh`;
- compatibility metadata: `channels/appstore-connect/compatibility.yml`;
- GitLab template: `templates/gitlab/ios-appstore-connect.yml`;
- cross-stack contract: `specs/shared/contracts/app-store-release.v0.1.md`.

Rumble products may provide app-specific metadata, screenshots, signed IPA artifacts, and `appstore/release.config.json`, but must not call the upstream CLI directly.

## Consequences

- Upstream CLI changes are absorbed in one Gear Cable adapter.
- Release jobs stay reproducible through pinned versions and explicit compatibility checks.
- App Store submission remains an append-only distribution action; recovery is compensation, not rollback.
- Gear Cable remains distribution plumbing and does not own iOS build logic, signing identities, or product metadata authoring.
