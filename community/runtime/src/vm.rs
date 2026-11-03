//! Core VM — stack machine execution engine

use std::collections::HashMap;
use crate::{
    bytecode::Program,
    context::ExecutionContext,
    error::RuntimeError,
    opcode::Opcode,
};

const MAX_STACK_DEPTH: usize = 1024;
const GAS_PER_OPCODE_BASE: u64 = 3;

/// Trace entry — một bước thực thi (dùng để debug / audit / CTF)
#[derive(Debug, Clone)]
pub struct TraceEntry {
    pub pc:       usize,
    pub mnemonic: String,
    pub stack:    Vec<[u8; 32]>,
    pub gas_left: u64,
}

/// Kết quả sau khi VM kết thúc
#[derive(Debug)]
pub struct ExecutionResult {
    /// Return data (từ RETURN opcode)
    pub return_data: Vec<u8>,
    /// Gas đã dùng
    pub gas_used:    u64,
    /// Storage state sau khi chạy
    pub storage:     HashMap<[u8; 32], [u8; 32]>,
    /// Logs emitted
    pub logs:        Vec<LogEntry>,
    /// Execution trace (nếu feature `trace` bật)
    pub trace:       Vec<TraceEntry>,
    /// Top of stack khi kết thúc
    stack_snapshot:  Vec<[u8; 32]>,
}

impl ExecutionResult {
    /// Giá trị trên đỉnh stack khi kết thúc (hoặc None nếu stack rỗng)
    pub fn stack_top(&self) -> Option<[u8; 32]> {
        self.stack_snapshot.last().copied()
    }
}

#[derive(Debug, Clone)]
pub struct LogEntry {
    pub topics: Vec<[u8; 32]>,
    pub data:   Vec<u8>,
}

/// Stack machine VM
pub struct Vm {
    gas_limit: u64,
}

impl Vm {
    pub fn new(gas_limit: u64) -> Self {
        Self { gas_limit }
    }

    /// Chạy program với execution context cho trước.
    /// Trả về ExecutionResult hoặc RuntimeError.
    pub fn execute(
        &mut self,
        program: &Program,
        ctx: &ExecutionContext,
    ) -> Result<ExecutionResult, RuntimeError> {
        let mut stack: Vec<[u8; 32]> = Vec::with_capacity(64);
        let mut memory: Vec<u8>       = Vec::new();
        let mut storage               = ctx.storage.clone();
        let mut logs: Vec<LogEntry>   = Vec::new();
        let mut trace: Vec<TraceEntry> = Vec::new();

        let mut gas_left = self.gas_limit;
        let mut pc       = 0usize;
        let instructions = &program.instructions;

        macro_rules! consume_gas {
            ($cost:expr) => {{
                let cost: u64 = $cost;
                if gas_left < cost {
                    return Err(RuntimeError::OutOfGas {
                        required:  cost,
                        available: gas_left,
                    });
                }
                gas_left -= cost;
            }};
        }

        macro_rules! pop {
            () => {{
                stack.pop().ok_or(RuntimeError::StackUnderflow { pc })?
            }};
        }

        macro_rules! push {
            ($val:expr) => {{
                if stack.len() >= MAX_STACK_DEPTH {
                    return Err(RuntimeError::StackOverflow { pc });
                }
                stack.push($val);
            }};
        }

        while pc < instructions.len() {
            let instr = &instructions[pc];
            let current_pc = instr.pc;

            consume_gas!(GAS_PER_OPCODE_BASE);

            let op = Opcode::from_byte(instr.opcode).ok_or(RuntimeError::UnknownOpcode {
                pc:     current_pc,
                opcode: instr.opcode,
            })?;

            // Trace
            #[cfg(feature = "trace")]
            trace.push(TraceEntry {
                pc:       current_pc,
                mnemonic: op.mnemonic().to_string(),
                stack:    stack.clone(),
                gas_left,
            });

            match op {
                Opcode::Stop => break,

                Opcode::Push1 | Opcode::Push2 => {
                    let mut val = [0u8; 32];
                    let data = &instr.operand;
                    let offset = 32 - data.len();
                    val[offset..].copy_from_slice(data);
                    push!(val);
                }

                Opcode::Pop => { pop!(); }

                Opcode::Dup1 => {
                    let top = *stack.last()
                        .ok_or(RuntimeError::StackUnderflow { pc: current_pc })?;
                    push!(top);
                }

                Opcode::Swap1 => {
                    let n = stack.len();
                    if n < 2 {
                        return Err(RuntimeError::StackUnderflow { pc: current_pc });
                    }
                    stack.swap(n - 1, n - 2);
                }

                Opcode::Add => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    push!(u128_to_u256(a.wrapping_add(b)));
                }

                Opcode::Sub => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    push!(u128_to_u256(a.wrapping_sub(b)));
                }

                Opcode::Mul => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    push!(u128_to_u256(a.wrapping_mul(b)));
                }

                Opcode::Div => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    if b == 0 {
                        push!([0u8; 32]);
                    } else {
                        push!(u128_to_u256(a / b));
                    }
                }

                Opcode::Mod => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    if b == 0 {
                        push!([0u8; 32]);
                    } else {
                        push!(u128_to_u256(a % b));
                    }
                }

                Opcode::Lt => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    push!(bool_to_u256(a < b));
                }

                Opcode::Gt => {
                    let a = u256_to_u128(pop!());
                    let b = u256_to_u128(pop!());
                    push!(bool_to_u256(a > b));
                }

                Opcode::Eq => {
                    let a = pop!();
                    let b = pop!();
                    push!(bool_to_u256(a == b));
                }

                Opcode::IsZero => {
                    let a = pop!();
                    push!(bool_to_u256(a == [0u8; 32]));
                }

                Opcode::And => {
                    let a = pop!();
                    let b = pop!();
                    let mut result = [0u8; 32];
                    for i in 0..32 { result[i] = a[i] & b[i]; }
                    push!(result);
                }

                Opcode::Or => {
                    let a = pop!();
                    let b = pop!();
                    let mut result = [0u8; 32];
                    for i in 0..32 { result[i] = a[i] | b[i]; }
                    push!(result);
                }

                Opcode::Xor => {
                    let a = pop!();
                    let b = pop!();
                    let mut result = [0u8; 32];
                    for i in 0..32 { result[i] = a[i] ^ b[i]; }
                    push!(result);
                }

                Opcode::Caller => {
                    let mut val = [0u8; 32];
                    val[12..].copy_from_slice(&ctx.caller);
                    push!(val);
                }

                Opcode::CallValue => {
                    push!(u128_to_u256(ctx.call_value));
                }

                Opcode::CallDataSize => {
                    push!(u128_to_u256(ctx.calldata.len() as u128));
                }

                Opcode::CallDataLoad => {
                    let offset = u256_to_u128(pop!()) as usize;
                    let mut val = [0u8; 32];
                    for i in 0..32 {
                        val[i] = ctx.calldata.get(offset + i).copied().unwrap_or(0);
                    }
                    push!(val);
                }

                Opcode::MStore => {
                    let offset = u256_to_u128(pop!()) as usize;
                    let value  = pop!();
                    consume_gas!(3); // memory expansion cost (simplified)
                    ensure_memory(&mut memory, offset + 32);
                    memory[offset..offset + 32].copy_from_slice(&value);
                }

                Opcode::MLoad => {
                    let offset = u256_to_u128(pop!()) as usize;
                    ensure_memory(&mut memory, offset + 32);
                    let mut val = [0u8; 32];
                    val.copy_from_slice(&memory[offset..offset + 32]);
                    push!(val);
                }

                Opcode::MSize => {
                    push!(u128_to_u256(memory.len() as u128));
                }

                Opcode::SLoad => {
                    let key = pop!();
                    let val = storage.get(&key).copied().unwrap_or([0u8; 32]);
                    push!(val);
                }

                Opcode::SStore => {
                    consume_gas!(17); // simplified cold storage cost
                    let key = pop!();
                    let val = pop!();
                    storage.insert(key, val);
                }

                Opcode::Jump => {
                    let target = u256_to_u128(pop!()) as usize;
                    // Find instruction index for this bytecode offset
                    let idx = instructions.iter().position(|i| i.pc == target)
                        .ok_or(RuntimeError::InvalidJumpDest { pc: current_pc, target })?;
                    if !program.is_valid_jumpdest(target) {
                        return Err(RuntimeError::InvalidJumpDest { pc: current_pc, target });
                    }
                    pc = idx;
                    continue;
                }

                Opcode::JumpI => {
                    let target    = u256_to_u128(pop!()) as usize;
                    let condition = pop!();
                    if condition != [0u8; 32] {
                        let idx = instructions.iter().position(|i| i.pc == target)
                            .ok_or(RuntimeError::InvalidJumpDest { pc: current_pc, target })?;
                        if !program.is_valid_jumpdest(target) {
                            return Err(RuntimeError::InvalidJumpDest { pc: current_pc, target });
                        }
                        pc = idx;
                        continue;
                    }
                }

                Opcode::JumpDest => { /* no-op — marker only */ }

                Opcode::Pc => {
                    push!(u128_to_u256(current_pc as u128));
                }

                Opcode::Sha3 => {
                    use sha2::{Sha256, Digest};
                    consume_gas!(30);
                    let offset = u256_to_u128(pop!()) as usize;
                    let len    = u256_to_u128(pop!()) as usize;
                    ensure_memory(&mut memory, offset + len);
                    let data = &memory[offset..offset + len];
                    let hash = Sha256::digest(data);
                    let mut val = [0u8; 32];
                    val.copy_from_slice(&hash);
                    push!(val);
                }

                Opcode::Log0 => {
                    let _offset = pop!();
                    let _len    = pop!();
                    logs.push(LogEntry { topics: vec![], data: vec![] });
                }

                Opcode::Log1 => {
                    let _offset = pop!();
                    let _len    = pop!();
                    let topic   = pop!();
                    logs.push(LogEntry { topics: vec![topic], data: vec![] });
                }

                Opcode::Log2 => {
                    let _offset = pop!();
                    let _len    = pop!();
                    let t1      = pop!();
                    let t2      = pop!();
                    logs.push(LogEntry { topics: vec![t1, t2], data: vec![] });
                }

                Opcode::Return => {
                    let offset = u256_to_u128(pop!()) as usize;
                    let len    = u256_to_u128(pop!()) as usize;
                    ensure_memory(&mut memory, offset + len);
                    let return_data = memory[offset..offset + len].to_vec();
                    return Ok(ExecutionResult {
                        return_data,
                        gas_used: self.gas_limit - gas_left,
                        storage,
                        logs,
                        trace,
                        stack_snapshot: stack,
                    });
                }

                Opcode::Revert => {
                    let offset = u256_to_u128(pop!()) as usize;
                    let len    = u256_to_u128(pop!()) as usize;
                    ensure_memory(&mut memory, offset + len);
                    let msg = String::from_utf8_lossy(&memory[offset..offset + len]).to_string();
                    return Err(RuntimeError::Revert { pc: current_pc, reason: msg });
                }

                // CTF_CALL — mô phỏng external call (không thực thi, chỉ emit trace)
                Opcode::CtfCall => {
                    consume_gas!(700); // simulated CALL gas
                    let _target_addr = pop!();
                    let _value       = pop!();
                    // Không thực hiện gì — đây là placeholder cho CTF demo reentrancy
                    // Học viên sẽ thấy call này trong trace để phân tích
                    logs.push(LogEntry {
                        topics: vec![],
                        data:   b"CTF_EXTERNAL_CALL".to_vec(),
                    });
                    push!([0u8; 32]); // return success = 0x00...01? để simplify: 0
                }
            }

            pc += 1;
        }

        Ok(ExecutionResult {
            return_data: vec![],
            gas_used:    self.gas_limit - gas_left,
            storage,
            logs,
            trace,
            stack_snapshot: stack,
        })
    }
}

// ─── helpers ────────────────────────────────────────────────────────────────

fn u256_to_u128(v: [u8; 32]) -> u128 {
    u128::from_be_bytes(v[16..].try_into().unwrap())
}

fn u128_to_u256(v: u128) -> [u8; 32] {
    let mut buf = [0u8; 32];
    buf[16..].copy_from_slice(&v.to_be_bytes());
    buf
}

fn bool_to_u256(v: bool) -> [u8; 32] {
    u128_to_u256(v as u128)
}

fn ensure_memory(memory: &mut Vec<u8>, needed: usize) {
    if memory.len() < needed {
        memory.resize(needed, 0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{bytecode::Program, context::ExecutionContext};

    #[test]
    fn add_two_numbers() {
        // PUSH1 10, PUSH1 20, ADD, STOP → stack top = 30
        let prog = Program::from_hex("600a601401").unwrap();
        let ctx  = ExecutionContext::default();
        let mut vm = Vm::new(100_000);
        let result = vm.execute(&prog, &ctx).unwrap();
        assert_eq!(u256_to_u128(result.stack_top().unwrap()), 30);
    }

    #[test]
    fn out_of_gas() {
        let prog = Program::from_hex("600a601401").unwrap();
        let ctx  = ExecutionContext::default();
        let mut vm = Vm::new(5); // quá ít gas
        assert!(vm.execute(&prog, &ctx).is_err());
    }

    #[test]
    fn sstore_sload() {
        // PUSH1 42 (value), PUSH1 1 (key), SSTORE, PUSH1 1 (key), SLOAD, STOP
        let prog = Program::from_hex("602a60015560015400").unwrap();
        let ctx  = ExecutionContext::default();
        let mut vm = Vm::new(1_000_000);
        let result = vm.execute(&prog, &ctx).unwrap();
        assert_eq!(u256_to_u128(result.stack_top().unwrap()), 42);
    }
}
