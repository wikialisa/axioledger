//! Artifact — đọc file nguồn hoặc compiled bytecode từ disk

use std::path::PathBuf;
use anyhow::Context;

/// Loại artifact cần verify
#[derive(Debug, Clone)]
pub enum ArtifactKind {
    /// Solidity source file (.sol) — hash toàn bộ source
    SoliditySource,
    /// Compiled EVM bytecode (hex string hoặc binary)
    EvmBytecode,
    /// Solana ELF binary (.so)
    SolanaElf,
    /// Anchor IDL JSON
    AnchorIdl,
}

/// Artifact đọc từ file
#[derive(Debug, Clone)]
pub struct Artifact {
    pub kind:    ArtifactKind,
    pub path:    PathBuf,
    /// Nội dung raw bytes
    pub content: Vec<u8>,
}

impl Artifact {
    /// Đọc artifact từ đường dẫn file
    pub fn from_file(path: PathBuf, kind: ArtifactKind) -> anyhow::Result<Self> {
        let content = std::fs::read(&path)
            .with_context(|| format!("cannot read artifact: {}", path.display()))?;
        Ok(Self { kind, path, content })
    }

    /// Parse EVM bytecode từ hex file (bỏ whitespace, prefix 0x)
    pub fn evm_from_hex_file(path: PathBuf) -> anyhow::Result<Self> {
        let raw = std::fs::read_to_string(&path)
            .with_context(|| format!("cannot read hex file: {}", path.display()))?;
        let hex_str = raw.trim().trim_start_matches("0x");
        let bytes = hex::decode(hex_str)
            .with_context(|| format!("invalid hex in {}", path.display()))?;
        Ok(Self {
            kind:    ArtifactKind::EvmBytecode,
            path,
            content: bytes,
        })
    }
}
