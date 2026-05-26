use serde::{Deserialize, Serialize};

use crate::Result;
use crate::manifest::ReleaseManifest;
use crate::platform::{Arch, Os, Platform};
use crate::policy::{PolicyReport, validate_policy};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Host {
    pub os: Os,
    pub arch: Arch,
}

impl Host {
    pub fn current() -> Self {
        Self {
            os: current_os(),
            arch: current_arch(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DistributionPlan {
    pub package: String,
    pub version: String,
    pub host: Host,
    pub artifacts: Vec<Artifact>,
    pub actions: Vec<ArtifactAction>,
    pub policy: PolicyReport,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Artifact {
    pub name: String,
    pub target: String,
    pub package_kind: String,
    pub expected_path: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ArtifactAction {
    pub artifact: String,
    pub kind: ArtifactActionKind,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ArtifactActionKind {
    Build,
    Package,
    Checksum,
    Signature,
    Sbom,
    Provenance,
}

pub fn plan(manifest: &ReleaseManifest, host: Host) -> Result<DistributionPlan> {
    let policy = validate_policy(manifest)?;
    let artifacts = manifest
        .platforms
        .iter()
        .flat_map(|platform| planned_artifacts(manifest, platform))
        .collect::<Vec<_>>();
    let actions = artifacts
        .iter()
        .flat_map(|artifact| planned_actions(manifest, artifact))
        .collect::<Vec<_>>();

    Ok(DistributionPlan {
        package: manifest.package.name.clone(),
        version: manifest.package.version.clone(),
        host,
        artifacts,
        actions,
        policy,
    })
}

fn planned_artifacts(manifest: &ReleaseManifest, platform: &Platform) -> Vec<Artifact> {
    let packages = if platform.packages.is_empty() {
        vec!["tar.gz".to_string()]
    } else {
        platform.packages.clone()
    };

    packages
        .into_iter()
        .map(|package_kind| {
            let name = format!(
                "{}-{}-{}.{}",
                manifest.package.name, manifest.package.version, platform.target, package_kind
            );
            Artifact {
                expected_path: format!("dist/{name}"),
                name,
                target: platform.target.clone(),
                package_kind,
            }
        })
        .collect()
}

fn planned_actions(manifest: &ReleaseManifest, artifact: &Artifact) -> Vec<ArtifactAction> {
    let mut kinds = vec![ArtifactActionKind::Build, ArtifactActionKind::Package];
    if manifest.policy.require_checksums {
        kinds.push(ArtifactActionKind::Checksum);
    }
    if manifest.policy.require_signatures {
        kinds.push(ArtifactActionKind::Signature);
    }
    if manifest.policy.require_sbom {
        kinds.push(ArtifactActionKind::Sbom);
    }
    if manifest.policy.require_slsa {
        kinds.push(ArtifactActionKind::Provenance);
    }
    kinds
        .into_iter()
        .map(|kind| ArtifactAction {
            artifact: artifact.name.clone(),
            kind,
        })
        .collect()
}

fn current_os() -> Os {
    if cfg!(target_os = "macos") {
        Os::Macos
    } else if cfg!(target_os = "windows") {
        Os::Windows
    } else if cfg!(target_os = "android") {
        Os::Android
    } else if cfg!(target_arch = "wasm32") {
        Os::Web
    } else {
        Os::Linux
    }
}

fn current_arch() -> Arch {
    if cfg!(target_arch = "aarch64") {
        Arch::Aarch64
    } else if cfg!(target_arch = "wasm32") {
        Arch::Wasm32
    } else {
        Arch::X86_64
    }
}

#[cfg(test)]
mod tests {
    use crate::manifest::parse_manifest;

    use super::*;

    #[test]
    fn plan_is_deterministic_and_includes_required_actions() {
        let manifest = parse_manifest(include_str!(
            "../../../examples/cos-matic/gear-cable.toml"
        ))
        .unwrap();
        let plan = plan(
            &manifest,
            Host {
                os: Os::Linux,
                arch: Arch::X86_64,
            },
        )
        .unwrap();
        assert_eq!(plan.package, "cos-matic");
        assert!(!plan.artifacts.is_empty());
        assert!(
            plan.actions
                .iter()
                .any(|a| a.kind == ArtifactActionKind::Checksum)
        );
        assert!(
            plan.actions
                .iter()
                .any(|a| a.kind == ArtifactActionKind::Signature)
        );
    }
}
