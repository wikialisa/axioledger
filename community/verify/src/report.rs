//! Verification report — kết quả so sánh local hash vs on-chain

use crate::hasher::ArtifactHash;
use std::path::PathBuf;

/// Trạng thái kết quả xác thực
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum VerifyStatus {
    /// Hash khớp — artifact đúng với deployed
    Match,
    /// Hash không khớp — cảnh báo sai lệch
    Mismatch,
    /// Không thể lấy bytecode on-chain (network error, not deployed, ...)
    FetchError(String),
}

impl std::fmt::Display for VerifyStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Match             => write!(f, "✅ MATCH"),
            Self::Mismatch          => write!(f, "❌ MISMATCH"),
            Self::FetchError(msg)   => write!(f, "⚠️  FETCH_ERROR: {msg}"),
        }
    }
}

/// Báo cáo xác thực đầy đủ
#[derive(Debug, Clone)]
pub struct VerifyReport {
    pub artifact_path:    PathBuf,
    pub address:          String,
    pub local_hash:       ArtifactHash,
    /// Hash của bytecode on-chain (nếu lấy được)
    pub onchain_hash:     Option<ArtifactHash>,
    pub status:           VerifyStatus,
}

impl VerifyReport {
    /// In báo cáo ra stdout theo định dạng human-readable
    pub fn print_summary(&self) {
        println!("─────────────────────────────────────────────────");
        println!("Artifact  : {}", self.artifact_path.display());
        println!("Address   : {}", self.address);
        println!("Algorithm : {}", self.local_hash.algorithm);
        println!("Local     : {}", self.local_hash.to_hex());
        if let Some(ref oh) = self.onchain_hash {
            println!("On-chain  : {}", oh.to_hex());
        } else {
            println!("On-chain  : (unavailable)");
        }
        println!("Status    : {}", self.status);
        println!("─────────────────────────────────────────────────");
    }

    /// Serialize sang JSON string
    pub fn to_json(&self) -> String {
        serde_json::json!({
            "artifact": self.artifact_path.display().to_string(),
            "address":  self.address,
            "algorithm": self.local_hash.algorithm.to_string(),
            "local_hash":   self.local_hash.to_hex(),
            "onchain_hash": self.onchain_hash.as_ref().map(|h| h.to_hex()),
            "status": match &self.status {
                VerifyStatus::Match           => "MATCH",
                VerifyStatus::Mismatch        => "MISMATCH",
                VerifyStatus::FetchError(_)   => "FETCH_ERROR",
            },
        }).to_string()
    }
}
