//! Axio Runtime — bytecode execution sandbox
//!
//! Tầng Thực thi (Layer 0) — biên dịch và chạy bytecode an toàn trong môi trường
//! sandboxed, không phụ thuộc vào validator node hay RPC thật.
//!
//! # Mục đích
//! - Mô phỏng hành vi on-chain để kiểm tra logic trước khi deploy
//! - Cung cấp trace chi tiết từng opcode cho mục đích giáo dục / audit
//! - Phục vụ CTF framework: thực thi bytecode lỗi để học từ thực tế
//!
//! # Sử dụng cơ bản
//! ```no_run
//! use axio_runtime::{Vm, bytecode::Program};
//!
//! let program = Program::from_hex("600a600b01...").unwrap();
//! let mut vm = Vm::new(1_000_000); // gas limit
//! let result = vm.execute(&program).unwrap();
//! println!("result: {:?}, gas_used: {}", result.stack_top(), result.gas_used);
//! ```

pub mod bytecode;
pub mod context;
pub mod error;
pub mod opcode;
pub mod vm;

pub use vm::Vm;
pub use bytecode::Program;
pub use context::ExecutionContext;
pub use error::RuntimeError;
