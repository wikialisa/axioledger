//! Hasher — tính hash từ artifact bytes
//! Hỗ trợ SHA-256 và BLAKE3 để khớp với tiêu chuẩn on-chain khác nhau.

use sha2::{Sha256, Digest};
use crate::artifact::Artifact;

/// Thuật toán hash
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HashAlgorithm {
    Sha256,
    Blake3,
}

impl std::fmt::Display for HashAlgorithm {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Sha256 => write!(f, "sha256"),
            Self::Blake3 => write!(f, "blake3"),
        }
    }
}

/// Hash kết quả
#[derive(Debug, Clone)]
pub struct ArtifactHash {
    pub algorithm: HashAlgorithm,
    /// 32-byte digest
    pub digest: [u8; 32],
}

impl ArtifactHash {
    /// Hex string representation (lowercase, no prefix)
    pub fn to_hex(&self) -> String {
        hex::encode(self.digest)
    }

    /// Tính hash từ artifact
    pub fn compute(artifact: &Artifact, algo: HashAlgorithm) -> Self {
        let digest = match algo {
            HashAlgorithm::Sha256 => {
                let mut h = Sha256::new();
                h.update(&artifact.content);
                let result = h.finalize();
                let mut d = [0u8; 32];
                d.copy_from_slice(&result);
                d
            }
            HashAlgorithm::Blake3 => {
                let hash = blake3::hash(&artifact.content);
                *hash.as_bytes()
            }
        };
        Self { algorithm: algo, digest }
    }

    /// So sánh với hash hex string (case-insensitive)
    pub fn matches_hex(&self, other_hex: &str) -> bool {
        let normalized = other_hex.trim().trim_start_matches("0x").to_lowercase();
        self.to_hex() == normalized
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::artifact::{Artifact, ArtifactKind};
    use std::path::PathBuf;

    fn dummy_artifact(content: &[u8]) -> Artifact {
        Artifact {
            kind:    ArtifactKind::SoliditySource,
            path:    PathBuf::from("test.sol"),
            content: content.to_vec(),
        }
    }

    #[test]
    fn sha256_known_value() {
        // sha256("abc") = ba7816bf...
        let a = dummy_artifact(b"abc");
        let h = ArtifactHash::compute(&a, HashAlgorithm::Sha256);
        assert!(h.to_hex().starts_with("ba7816bf"));
    }

    #[test]
    fn blake3_deterministic() {
        let a1 = dummy_artifact(b"hello world");
        let a2 = dummy_artifact(b"hello world");
        let h1 = ArtifactHash::compute(&a1, HashAlgorithm::Blake3);
        let h2 = ArtifactHash::compute(&a2, HashAlgorithm::Blake3);
        assert_eq!(h1.digest, h2.digest);
    }
}
