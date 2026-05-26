//! Link Cable core: deterministic release manifest parsing, planning, and policy gates.
//!
//! This crate is I/O-light and portable. It owns the distribution semantics, not
//! channel side effects or app-specific build orchestration.

pub mod error;
pub mod manifest;
pub mod plan;
pub mod platform;
pub mod policy;

pub use error::{Error, Result};
pub use manifest::{Channel, CoreConfig, Package, PolicyConfig, ReleaseManifest, parse_manifest};
pub use plan::{Artifact, ArtifactAction, ArtifactActionKind, DistributionPlan, Host, plan};
pub use platform::{Arch, ChannelKind, Os, Platform};
pub use policy::{PolicyReport, PolicyViolation, PolicyWarning, validate_policy};
