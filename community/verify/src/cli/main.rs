//! axio-verify CLI entry point

use axio_verify::{
    Artifact, ArtifactKind, ArtifactHash, HashAlgorithm,
    OnchainVerifier, NetworkConfig,
    VerifyReport, VerifyStatus,
};
use clap::{Parser, ValueEnum};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(
    name       = "axio-verify",
    version    = "0.1.0",
    about      = "On-chain artifact verification — compare local hash with deployed bytecode",
)]
struct Cli {
    /// Path to artifact file (source or compiled bytecode)
    #[arg(short, long)]
    artifact: PathBuf,

    /// Type of artifact
    #[arg(short = 't', long, default_value = "evm-bytecode")]
    artifact_type: ArtifactTypeArg,

    /// Contract/program address to compare against
    #[arg(short, long)]
    address: String,

    /// RPC endpoint URL (e.g. https://mainnet.infura.io/v3/...)
    #[arg(short, long, env = "AXIO_RPC_URL")]
    rpc: String,

    /// Blockchain type
    #[arg(long, default_value = "evm")]
    chain: ChainArg,

    /// Hash algorithm to use
    #[arg(long, default_value = "sha256")]
    algo: AlgoArg,

    /// Output as JSON
    #[arg(long, default_value_t = false)]
    json: bool,
}

#[derive(Debug, Clone, ValueEnum)]
enum ArtifactTypeArg {
    SoliditySource,
    EvmBytecode,
    SolanaElf,
    AnchorIdl,
}

#[derive(Debug, Clone, ValueEnum)]
enum ChainArg { Evm, Solana }

#[derive(Debug, Clone, ValueEnum)]
enum AlgoArg { Sha256, Blake3 }

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    // Load artifact
    let kind = match cli.artifact_type {
        ArtifactTypeArg::SoliditySource => ArtifactKind::SoliditySource,
        ArtifactTypeArg::EvmBytecode    => ArtifactKind::EvmBytecode,
        ArtifactTypeArg::SolanaElf      => ArtifactKind::SolanaElf,
        ArtifactTypeArg::AnchorIdl      => ArtifactKind::AnchorIdl,
    };
    let artifact = Artifact::from_file(cli.artifact.clone(), kind)?;

    let algo = match cli.algo {
        AlgoArg::Sha256 => HashAlgorithm::Sha256,
        AlgoArg::Blake3 => HashAlgorithm::Blake3,
    };
    let local_hash = ArtifactHash::compute(&artifact, algo);

    // Fetch on-chain
    let network = match cli.chain {
        ChainArg::Evm    => NetworkConfig::evm(&cli.rpc),
        ChainArg::Solana => NetworkConfig::solana(&cli.rpc),
    };
    let verifier = OnchainVerifier::new(network);

    let (onchain_hash, status) = match verifier.fetch_bytecode(&cli.address).await {
        Ok(bytes) => {
            let onchain_artifact = axio_verify::Artifact {
                kind:    axio_verify::artifact::ArtifactKind::EvmBytecode,
                path:    PathBuf::from("onchain"),
                content: bytes,
            };
            let oh = ArtifactHash::compute(&onchain_artifact, algo);
            let ok = oh.digest == local_hash.digest;
            let status = if ok { VerifyStatus::Match } else { VerifyStatus::Mismatch };
            (Some(oh), status)
        }
        Err(e) => (None, VerifyStatus::FetchError(e.to_string())),
    };

    let report = VerifyReport {
        artifact_path: cli.artifact,
        address:       cli.address,
        local_hash,
        onchain_hash,
        status: status.clone(),
    };

    if cli.json {
        println!("{}", report.to_json());
    } else {
        report.print_summary();
    }

    // Exit code: 0 = match, 1 = mismatch/error
    if status != VerifyStatus::Match {
        std::process::exit(1);
    }
    Ok(())
}
