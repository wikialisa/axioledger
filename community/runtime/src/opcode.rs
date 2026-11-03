//! Opcode definitions — minimal EVM-compatible instruction set
//! Chỉ implement subset cần thiết cho mục đích giáo dục và CTF simulation.

/// Một opcode trong instruction set
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Opcode {
    // Stack operations
    Push1  = 0x60,
    Push2  = 0x61,
    Pop    = 0x50,
    Dup1   = 0x80,
    Swap1  = 0x90,

    // Arithmetic
    Add    = 0x01,
    Sub    = 0x03,
    Mul    = 0x02,
    Div    = 0x04,
    Mod    = 0x06,

    // Comparison & bitwise
    Lt     = 0x10,
    Gt     = 0x11,
    Eq     = 0x14,
    IsZero = 0x15,
    And    = 0x16,
    Or     = 0x17,
    Xor    = 0x18,

    // Memory
    MLoad  = 0x51,
    MStore = 0x52,
    MSize  = 0x59,

    // Storage (simulated)
    SLoad  = 0x54,
    SStore = 0x55,

    // Control flow
    Jump   = 0x56,
    JumpI  = 0x57,  // conditional jump (JUMPI)
    JumpDest = 0x5b,
    Pc     = 0x58,

    // Environment
    Caller = 0x33,
    CallValue = 0x34,
    CallDataLoad = 0x35,
    CallDataSize = 0x36,

    // Cryptography
    Sha3   = 0x20,

    // Logging (for CTF event emission)
    Log0   = 0xa0,
    Log1   = 0xa1,
    Log2   = 0xa2,

    // System
    Return = 0xf3,
    Revert = 0xfd,
    Stop   = 0x00,

    // CTF-specific: simulates external call (no actual call — for reentrancy demos)
    CtfCall = 0xfe,
}

impl Opcode {
    /// Decode byte → Opcode. Returns None for unknown opcodes.
    pub fn from_byte(byte: u8) -> Option<Self> {
        match byte {
            0x00 => Some(Self::Stop),
            0x01 => Some(Self::Add),
            0x02 => Some(Self::Mul),
            0x03 => Some(Self::Sub),
            0x04 => Some(Self::Div),
            0x06 => Some(Self::Mod),
            0x10 => Some(Self::Lt),
            0x11 => Some(Self::Gt),
            0x14 => Some(Self::Eq),
            0x15 => Some(Self::IsZero),
            0x16 => Some(Self::And),
            0x17 => Some(Self::Or),
            0x18 => Some(Self::Xor),
            0x20 => Some(Self::Sha3),
            0x33 => Some(Self::Caller),
            0x34 => Some(Self::CallValue),
            0x35 => Some(Self::CallDataLoad),
            0x36 => Some(Self::CallDataSize),
            0x50 => Some(Self::Pop),
            0x51 => Some(Self::MLoad),
            0x52 => Some(Self::MStore),
            0x54 => Some(Self::SLoad),
            0x55 => Some(Self::SStore),
            0x56 => Some(Self::Jump),
            0x57 => Some(Self::JumpI),
            0x58 => Some(Self::Pc),
            0x59 => Some(Self::MSize),
            0x5b => Some(Self::JumpDest),
            0x60 => Some(Self::Push1),
            0x61 => Some(Self::Push2),
            0x80 => Some(Self::Dup1),
            0x90 => Some(Self::Swap1),
            0xa0 => Some(Self::Log0),
            0xa1 => Some(Self::Log1),
            0xa2 => Some(Self::Log2),
            0xf3 => Some(Self::Return),
            0xfd => Some(Self::Revert),
            0xfe => Some(Self::CtfCall),
            _    => None,
        }
    }

    /// Human-readable mnemonic for trace output
    pub fn mnemonic(&self) -> &'static str {
        match self {
            Self::Stop        => "STOP",
            Self::Add         => "ADD",
            Self::Mul         => "MUL",
            Self::Sub         => "SUB",
            Self::Div         => "DIV",
            Self::Mod         => "MOD",
            Self::Lt          => "LT",
            Self::Gt          => "GT",
            Self::Eq          => "EQ",
            Self::IsZero      => "ISZERO",
            Self::And         => "AND",
            Self::Or          => "OR",
            Self::Xor         => "XOR",
            Self::Sha3        => "SHA3",
            Self::Caller      => "CALLER",
            Self::CallValue   => "CALLVALUE",
            Self::CallDataLoad => "CALLDATALOAD",
            Self::CallDataSize => "CALLDATASIZE",
            Self::Pop         => "POP",
            Self::MLoad       => "MLOAD",
            Self::MStore      => "MSTORE",
            Self::SLoad       => "SLOAD",
            Self::SStore      => "SSTORE",
            Self::Jump        => "JUMP",
            Self::JumpI       => "JUMPI",
            Self::Pc          => "PC",
            Self::MSize       => "MSIZE",
            Self::JumpDest    => "JUMPDEST",
            Self::Push1       => "PUSH1",
            Self::Push2       => "PUSH2",
            Self::Dup1        => "DUP1",
            Self::Swap1       => "SWAP1",
            Self::Log0        => "LOG0",
            Self::Log1        => "LOG1",
            Self::Log2        => "LOG2",
            Self::Return      => "RETURN",
            Self::Revert      => "REVERT",
            Self::CtfCall     => "CTF_CALL",
        }
    }
}
