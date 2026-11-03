//! Runtime errors

use thiserror::Error;

#[derive(Debug, Error, Clone)]
pub enum RuntimeError {
    #[error("parse error: {0}")]
    ParseError(String),

    #[error("stack underflow at pc={pc}")]
    StackUnderflow { pc: usize },

    #[error("stack overflow at pc={pc}")]
    StackOverflow { pc: usize },

    #[error("out of gas: required={required}, available={available}")]
    OutOfGas { required: u64, available: u64 },

    #[error("invalid jump destination: pc={pc}, target={target}")]
    InvalidJumpDest { pc: usize, target: usize },

    #[error("revert at pc={pc}: {reason}")]
    Revert { pc: usize, reason: String },

    #[error("unknown opcode 0x{opcode:02x} at pc={pc}")]
    UnknownOpcode { pc: usize, opcode: u8 },

    #[error("memory access out of bounds at pc={pc}")]
    MemoryOutOfBounds { pc: usize },

    #[error("CTF scenario triggered: {scenario}")]
    CtfScenario { scenario: String },
}
