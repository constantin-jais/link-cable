use serde::{Deserialize, Serialize};

use crate::Result;
use crate::platform::{ChannelKind, Platform};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReleaseManifest {
    pub package: Package,
    pub core: CoreConfig,
    #[serde(default)]
    pub policy: PolicyConfig,
    #[serde(default)]
    pub platforms: Vec<Platform>,
    #[serde(default)]
    pub channels: Vec<Channel>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Package {
    pub name: String,
    pub version: String,
    pub repository: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CoreConfig {
    pub language: String,
    pub workspace: String,
    pub binary: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PolicyConfig {
    #[serde(default = "default_true")]
    pub append_only: bool,
    #[serde(default = "default_true")]
    pub keyless_preferred: bool,
    #[serde(default = "default_true")]
    pub require_slsa: bool,
    #[serde(default = "default_true")]
    pub require_sbom: bool,
    #[serde(default = "default_true")]
    pub require_checksums: bool,
    #[serde(default = "default_true")]
    pub require_signatures: bool,
    #[serde(default = "default_true")]
    pub require_sovereign_floor: bool,
}

impl Default for PolicyConfig {
    fn default() -> Self {
        Self {
            append_only: true,
            keyless_preferred: true,
            require_slsa: true,
            require_sbom: true,
            require_checksums: true,
            require_signatures: true,
            require_sovereign_floor: true,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Channel {
    pub name: String,
    pub kind: ChannelKind,
    #[serde(default)]
    pub prerelease: bool,
    #[serde(default)]
    pub stable: bool,
}

pub fn parse_manifest(input: &str) -> Result<ReleaseManifest> {
    Ok(toml::from_str(input)?)
}

fn default_true() -> bool {
    true
}
