//! Distribution channel boundary.
//!
//! Implementations live behind this trait so Link Cable never pretends that an
//! append-only publish can be rolled back. Recovery is `compensate`.

use async_trait::async_trait;
use link_cable_core::DistributionPlan;
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum DistError {
    #[error("distribution channel is not implemented yet: {0}")]
    NotImplemented(&'static str),
}

pub type Result<T> = std::result::Result<T, DistError>;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlanRequest {
    pub plan: DistributionPlan,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PublishRequest {
    pub version: String,
    pub channel: String,
    pub yes: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PromoteRequest {
    pub version: String,
    pub channel: String,
    pub yes: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CompensateRequest {
    pub version: String,
    pub channel: String,
    pub yes: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ChannelReport {
    pub channel: String,
    pub status: String,
}

#[async_trait]
pub trait Distributor: Send + Sync {
    async fn plan(&self, req: PlanRequest) -> Result<ChannelReport>;
    async fn publish_prerelease(&self, req: PublishRequest) -> Result<ChannelReport>;
    async fn smoke(&self, req: PublishRequest) -> Result<ChannelReport>;
    async fn promote(&self, req: PromoteRequest) -> Result<ChannelReport>;
    async fn compensate(&self, req: CompensateRequest) -> Result<ChannelReport>;
}

pub struct DirectDownloadDryRun;

#[async_trait]
impl Distributor for DirectDownloadDryRun {
    async fn plan(&self, _req: PlanRequest) -> Result<ChannelReport> {
        Ok(ChannelReport {
            channel: "direct".into(),
            status: "dry-run".into(),
        })
    }

    async fn publish_prerelease(&self, _req: PublishRequest) -> Result<ChannelReport> {
        Err(DistError::NotImplemented(
            "publish_prerelease requires explicit release design",
        ))
    }

    async fn smoke(&self, _req: PublishRequest) -> Result<ChannelReport> {
        Err(DistError::NotImplemented(
            "smoke requires install implementation",
        ))
    }

    async fn promote(&self, _req: PromoteRequest) -> Result<ChannelReport> {
        Err(DistError::NotImplemented(
            "promote requires immutable prerelease evidence",
        ))
    }

    async fn compensate(&self, _req: CompensateRequest) -> Result<ChannelReport> {
        Err(DistError::NotImplemented(
            "compensate requires channel-specific runbook",
        ))
    }
}
