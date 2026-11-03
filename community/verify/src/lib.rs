//! axio-verify — Tầng Xác thực (Layer 1)
//!
//! Mục đích:
//! - Build hash từ artifact source (Solidity/Rust) và so sánh với bytecode đã deploy on-chain
//! - Phát hiện sai lệch giữa "mã đã audit" và "mã đang chạy thật"
//! - Phục vụ CI/CD pipeline và cộng đồng kiểm toán độc lập
//!
//! # Quy trình xác thực
//! ```text
//! [Source file]
//!     │
//!     ▼ sha256 / blake3
//! [Local Hash]
//!     │
//!     ▼ compare
//! [On-chain Deployed Bytecode Hash]  ← lấy qua RPC (eth_getCode / getAccountInfo)
//!     │
//!     ▼
//! ✅ MATCH — artifact khớp với deployed
//! ❌ MISMATCH — có thể đã bị thay thế hoặc nguồn không đồng bộ
//! ```

pub mod artifact;
pub mod hasher;
pub mod onchain;
pub mod report;

pub use artifact::{Artifact, ArtifactKind};
pub use hasher::{ArtifactHash, HashAlgorithm};
pub use onchain::{OnchainVerifier, NetworkConfig, ChainType};
pub use report::{VerifyReport, VerifyStatus};
