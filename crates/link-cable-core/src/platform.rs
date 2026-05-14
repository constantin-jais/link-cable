use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Os {
    Linux,
    Macos,
    Windows,
    Android,
    Web,
    Ios,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Arch {
    X86_64,
    Aarch64,
    Wasm32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ChannelKind {
    DirectDownload,
    Crate,
    Npm,
    Oci,
    AppStore,
    PlayStore,
    Fdroid,
    SelfHosted,
}

impl ChannelKind {
    pub fn is_store_free(&self) -> bool {
        matches!(
            self,
            Self::DirectDownload
                | Self::Crate
                | Self::Npm
                | Self::Oci
                | Self::Fdroid
                | Self::SelfHosted
        )
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Platform {
    pub os: Os,
    pub arch: Arch,
    pub target: String,
    #[serde(default)]
    pub packages: Vec<String>,
    #[serde(default)]
    pub sovereign_floor: Vec<String>,
}

impl Platform {
    pub fn label(&self) -> String {
        format!("{:?}/{:?}/{}", self.os, self.arch, self.target)
    }
}
