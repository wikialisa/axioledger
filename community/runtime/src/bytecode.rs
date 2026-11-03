//! Bytecode parsing and program representation

use crate::error::RuntimeError;

/// Một instruction sau khi decode
#[derive(Debug, Clone)]
pub struct Instruction {
    pub pc:      usize,
    pub opcode:  u8,
    pub operand: Vec<u8>,
}

/// Bytecode program — danh sách instructions đã parse
#[derive(Debug, Clone, Default)]
pub struct Program {
    pub instructions: Vec<Instruction>,
    /// Raw bytes (dùng cho jump destination validation)
    pub raw: Vec<u8>,
}

impl Program {
    /// Parse từ hex string (có thể bỏ prefix `0x`)
    pub fn from_hex(hex_str: &str) -> Result<Self, RuntimeError> {
        let stripped = hex_str.trim_start_matches("0x");
        let bytes = hex::decode(stripped)
            .map_err(|e| RuntimeError::ParseError(format!("invalid hex: {e}")))?;
        Self::from_bytes(bytes)
    }

    /// Parse từ raw bytes
    pub fn from_bytes(bytes: Vec<u8>) -> Result<Self, RuntimeError> {
        let mut instructions = Vec::new();
        let raw = bytes.clone();
        let mut i = 0;

        while i < bytes.len() {
            let pc     = i;
            let opcode = bytes[i];
            i += 1;

            // PUSH1..PUSH32: tiếp theo N bytes là operand
            let operand_size = if (0x60..=0x7f).contains(&opcode) {
                (opcode - 0x5f) as usize
            } else {
                0
            };

            if i + operand_size > bytes.len() {
                return Err(RuntimeError::ParseError(format!(
                    "pc={pc}: PUSH{} operand truncated", operand_size
                )));
            }

            let operand = bytes[i..i + operand_size].to_vec();
            i += operand_size;

            instructions.push(Instruction { pc, opcode, operand });
        }

        Ok(Self { instructions, raw })
    }

    /// Kiểm tra một PC có phải JUMPDEST hợp lệ không
    pub fn is_valid_jumpdest(&self, pc: usize) -> bool {
        self.raw.get(pc) == Some(&0x5b) // JUMPDEST
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_push1_add_stop() {
        // PUSH1 0x0a, PUSH1 0x0b, ADD, STOP
        let prog = Program::from_hex("600a600b0100").unwrap();
        assert_eq!(prog.instructions.len(), 4);
        assert_eq!(prog.instructions[0].operand, vec![0x0a]);
        assert_eq!(prog.instructions[1].operand, vec![0x0b]);
        assert_eq!(prog.instructions[2].opcode, 0x01); // ADD
        assert_eq!(prog.instructions[3].opcode, 0x00); // STOP
    }

    #[test]
    fn invalid_hex_returns_error() {
        assert!(Program::from_hex("0xZZZZ").is_err());
    }
}
