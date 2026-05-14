use thiserror::Error;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, Error)]
pub enum Error {
    #[error("manifest parse failed: {0}")]
    ManifestParse(#[from] toml::de::Error),
    #[error("policy validation failed: {0}")]
    Policy(String),
    #[error("manifest is missing required section: {0}")]
    MissingSection(&'static str),
}
