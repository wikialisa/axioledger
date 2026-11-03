//! On-chain bytecode fetcher — lấy deployed bytecode qua JSON-RPC

use anyhow::Context;
use serde_json::{json, Value};

/// Network configuration
#[derive(Debug, Clone)]
pub struct NetworkConfig {
    /// JSON-RPC endpoint URL
    pub rpc_url:    String,
    /// Chain type
    pub chain_type: ChainType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChainType {
    Evm,
    Solana,
}

impl NetworkConfig {
    pub fn evm(rpc_url: impl Into<String>) -> Self {
        Self { rpc_url: rpc_url.into(), chain_type: ChainType::Evm }
    }
    pub fn solana(rpc_url: impl Into<String>) -> Self {
        Self { rpc_url: rpc_url.into(), chain_type: ChainType::Solana }
    }
}

/// Fetcher cho on-chain bytecode
pub struct OnchainVerifier {
    client: reqwest::Client,
    config: NetworkConfig,
}

impl OnchainVerifier {
    pub fn new(config: NetworkConfig) -> Self {
        Self {
            client: reqwest::Client::builder()
                .timeout(std::time::Duration::from_secs(15))
                .build()
                .expect("failed to build HTTP client"),
            config,
        }
    }

    /// Lấy deployed bytecode (EVM: eth_getCode, Solana: getAccountInfo)
    pub async fn fetch_bytecode(&self, address: &str) -> anyhow::Result<Vec<u8>> {
        match self.config.chain_type {
            ChainType::Evm     => self.fetch_evm_bytecode(address).await,
            ChainType::Solana  => self.fetch_solana_bytecode(address).await,
        }
    }

    async fn fetch_evm_bytecode(&self, address: &str) -> anyhow::Result<Vec<u8>> {
        let body = json!({
            "jsonrpc": "2.0",
            "id":      1,
            "method":  "eth_getCode",
            "params":  [address, "latest"]
        });

        let resp: Value = self.client
            .post(&self.config.rpc_url)
            .json(&body)
            .send()
            .await
            .context("RPC request failed")?
            .json()
            .await
            .context("failed to parse RPC response")?;

        let hex_code = resp["result"]
            .as_str()
            .context("missing 'result' in eth_getCode response")?;

        if hex_code == "0x" {
            anyhow::bail!("no contract deployed at address {address}");
        }

        let stripped = hex_code.trim_start_matches("0x");
        hex::decode(stripped)
            .with_context(|| format!("invalid hex bytecode from RPC: {hex_code}"))
    }

    async fn fetch_solana_bytecode(&self, program_id: &str) -> anyhow::Result<Vec<u8>> {
        let body = json!({
            "jsonrpc": "2.0",
            "id":      1,
            "method":  "getAccountInfo",
            "params":  [
                program_id,
                { "encoding": "base64" }
            ]
        });

        let resp: Value = self.client
            .post(&self.config.rpc_url)
            .json(&body)
            .send()
            .await
            .context("Solana RPC request failed")?
            .json()
            .await
            .context("failed to parse Solana RPC response")?;

        let data_arr = resp["result"]["value"]["data"]
            .as_array()
            .context("unexpected Solana account data format")?;

        let b64 = data_arr[0]
            .as_str()
            .context("missing base64 data in Solana response")?;

        use base64::{Engine as _, engine::general_purpose::STANDARD};
        STANDARD.decode(b64).context("failed to decode base64 Solana bytecode")
    }
}
