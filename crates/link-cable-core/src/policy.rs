use serde::{Deserialize, Serialize};

use crate::manifest::{Channel, ReleaseManifest};
use crate::platform::{ChannelKind, Os, Platform};
use crate::{Error, Result};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PolicyReport {
    pub ok: bool,
    pub warnings: Vec<PolicyWarning>,
    pub violations: Vec<PolicyViolation>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PolicyWarning {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PolicyViolation {
    pub code: String,
    pub message: String,
}

pub fn validate_policy(manifest: &ReleaseManifest) -> Result<PolicyReport> {
    let mut warnings = Vec::new();
    let mut violations = Vec::new();

    if !manifest.policy.append_only {
        violations.push(violation(
            "append_only_disabled",
            "distribution is append-only; rollback semantics are forbidden, use compensate",
        ));
    }
    if manifest.platforms.is_empty() {
        violations.push(violation(
            "no_platforms",
            "at least one platform is required",
        ));
    }
    if manifest.channels.is_empty() {
        violations.push(violation("no_channels", "at least one channel is required"));
    }

    if manifest.policy.require_sovereign_floor {
        for platform in &manifest.platforms {
            if platform.os == Os::Ios {
                warnings.push(warning(
                    "ios_dma_caveat",
                    "iOS has no global sovereign floor; EU DMA sideload/alt-marketplace caveat must be explicit",
                ));
            }
            if !has_store_free_floor(platform, &manifest.channels) {
                violations.push(violation(
                    "missing_sovereign_floor",
                    format!(
                        "platform {} has no store-free sovereign floor",
                        platform.label()
                    ),
                ));
            }
        }
    }

    let ok = violations.is_empty();
    let report = PolicyReport {
        ok,
        warnings,
        violations,
    };
    if ok {
        Ok(report)
    } else {
        Err(Error::Policy(report.summary()))
    }
}

impl PolicyReport {
    pub fn summary(&self) -> String {
        self.violations
            .iter()
            .map(|v| format!("{}: {}", v.code, v.message))
            .collect::<Vec<_>>()
            .join("; ")
    }
}

fn has_store_free_floor(platform: &Platform, channels: &[Channel]) -> bool {
    platform.sovereign_floor.iter().any(|floor| {
        let normalized = floor.trim().to_ascii_lowercase();
        is_known_store_free_floor(&normalized)
            || channels.iter().any(|channel| {
                channel.kind.is_store_free()
                    && (channel.name.eq_ignore_ascii_case(&normalized)
                        || channel_kind_name(&channel.kind) == normalized)
            })
    })
}

fn is_known_store_free_floor(value: &str) -> bool {
    matches!(
        value,
        "direct-download" | "fdroid" | "f-droid" | "self-hosted" | "static" | "appimage"
    )
}

fn channel_kind_name(kind: &ChannelKind) -> &'static str {
    match kind {
        ChannelKind::DirectDownload => "direct-download",
        ChannelKind::Crate => "crate",
        ChannelKind::Npm => "npm",
        ChannelKind::Oci => "oci",
        ChannelKind::AppStore => "app-store",
        ChannelKind::PlayStore => "play-store",
        ChannelKind::Fdroid => "fdroid",
        ChannelKind::SelfHosted => "self-hosted",
    }
}

fn warning(code: impl Into<String>, message: impl Into<String>) -> PolicyWarning {
    PolicyWarning {
        code: code.into(),
        message: message.into(),
    }
}

fn violation(code: impl Into<String>, message: impl Into<String>) -> PolicyViolation {
    PolicyViolation {
        code: code.into(),
        message: message.into(),
    }
}

#[cfg(test)]
mod tests {
    use crate::manifest::parse_manifest;

    use super::*;

    const GOOD: &str = r#"
[package]
name = "agent-o-matic"
version = "0.0.0"
repository = "https://github.com/constantin-jais/Agent-O-Matic"

[core]
language = "rust"
workspace = "."
binary = "aom"

[[platforms]]
os = "linux"
arch = "x86_64"
target = "x86_64-unknown-linux-gnu"
packages = ["tar.gz"]
sovereign_floor = ["direct-download"]

[[channels]]
name = "direct"
kind = "direct-download"
prerelease = true
stable = true
"#;

    #[test]
    fn accepts_direct_download_floor() {
        let manifest = parse_manifest(GOOD).unwrap();
        let report = validate_policy(&manifest).unwrap();
        assert!(report.ok);
        assert!(report.violations.is_empty());
    }

    #[test]
    fn rejects_store_only_platform() {
        let bad = GOOD
            .replace(
                r#"sovereign_floor = ["direct-download"]"#,
                r#"sovereign_floor = ["store"]"#,
            )
            .replace(r#"kind = "direct-download""#, r#"kind = "app-store""#);
        let manifest = parse_manifest(&bad).unwrap();
        let err = validate_policy(&manifest).unwrap_err().to_string();
        assert!(err.contains("missing_sovereign_floor"));
    }

    #[test]
    fn rejects_append_only_false() {
        let bad = GOOD.replace(
            "[[platforms]]",
            "[policy]\nappend_only = false\n\n[[platforms]]",
        );
        let manifest = parse_manifest(&bad).unwrap();
        let err = validate_policy(&manifest).unwrap_err().to_string();
        assert!(err.contains("append_only_disabled"));
    }

    #[test]
    fn documents_ios_caveat() {
        let ios = GOOD.replace(r#"os = "linux""#, r#"os = "ios""#);
        let manifest = parse_manifest(&ios).unwrap();
        let report = validate_policy(&manifest).unwrap();
        assert!(report.warnings.iter().any(|w| w.code == "ios_dma_caveat"));
    }
}
