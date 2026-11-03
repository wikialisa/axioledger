//! axio-run — CLI entry point cho Axio Runtime

use axio_runtime::{Program, Vm, ExecutionContext};
use clap::Parser;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(
    name        = "axio-run",
    version     = "0.1.0",
    about       = "Axio VM — bytecode execution sandbox for education and CTF",
    long_about  = None,
)]
struct Cli {
    /// Hex-encoded bytecode (e.g. 600a600b0100)
    #[arg(short, long, group = "input")]
    bytecode: Option<String>,

    /// Path to a .hex file containing raw bytecode
    #[arg(short = 'f', long, group = "input")]
    file: Option<PathBuf>,

    /// Gas limit for execution
    #[arg(short, long, default_value = "1000000")]
    gas: u64,

    /// Simulate msg.caller (20-byte hex address, no 0x prefix)
    #[arg(long, default_value = "0000000000000000000000000000000000000001")]
    caller: String,

    /// Simulate msg.value (in wei, decimal)
    #[arg(long, default_value = "0")]
    value: u128,

    /// Print execution trace (opcode-by-opcode)
    #[arg(long, default_value_t = false)]
    trace: bool,
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    let hex_src = if let Some(hex) = cli.bytecode {
        hex
    } else if let Some(path) = cli.file {
        std::fs::read_to_string(path)?.trim().to_string()
    } else {
        anyhow::bail!("provide --bytecode <hex> or --file <path>");
    };

    let program = Program::from_hex(&hex_src)?;
    println!("📦 Parsed {} instructions", program.instructions.len());

    // Build caller bytes
    let caller_hex = cli.caller.trim_start_matches("0x");
    if caller_hex.len() != 40 {
        anyhow::bail!("--caller must be exactly 20 bytes (40 hex chars)");
    }
    let caller_bytes = hex::decode(caller_hex)?;
    let mut caller = [0u8; 20];
    caller.copy_from_slice(&caller_bytes);

    let ctx = ExecutionContext::default()
        .with_caller(caller)
        .with_value(cli.value);

    let mut vm = Vm::new(cli.gas);

    match vm.execute(&program, &ctx) {
        Ok(result) => {
            println!("✅ Execution succeeded");
            println!("   gas_used   : {}", result.gas_used);
            println!("   logs       : {}", result.logs.len());

            if let Some(top) = result.stack_top() {
                println!("   stack_top  : 0x{}", hex::encode(top));
            }

            if !result.return_data.is_empty() {
                println!("   return_data: 0x{}", hex::encode(&result.return_data));
            }

            if cli.trace {
                println!("\n📋 Trace ({} steps):", result.trace.len());
                for entry in &result.trace {
                    println!(
                        "  pc={:04x}  {}  gas_left={}",
                        entry.pc, entry.mnemonic, entry.gas_left
                    );
                }
            }
        }
        Err(e) => {
            eprintln!("❌ Execution failed: {e}");
            std::process::exit(1);
        }
    }

    Ok(())
}
