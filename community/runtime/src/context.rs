//! Execution context — môi trường chạy VM (caller, value, storage, memory)

use std::collections::HashMap;

/// Địa chỉ 20-byte (EVM-compatible)
pub type Address = [u8; 20];

/// Slot storage (32-byte key → 32-byte value)
pub type Storage = HashMap<[u8; 32], [u8; 32]>;

/// Execution context được inject vào VM trước khi chạy
#[derive(Debug, Clone)]
pub struct ExecutionContext {
    /// Địa chỉ người gọi (msg.sender)
    pub caller:     Address,
    /// ETH gửi kèm (msg.value), tính bằng wei
    pub call_value: u128,
    /// calldata bytes
    pub calldata:   Vec<u8>,
    /// Storage state trước khi chạy (dùng để mô phỏng re-entrancy, state manipulation)
    pub storage:    Storage,
    /// Block number giả lập
    pub block_number: u64,
    /// Timestamp giả lập (unix seconds)
    pub timestamp:  u64,
}

impl Default for ExecutionContext {
    fn default() -> Self {
        Self {
            caller:       [0u8; 20],
            call_value:   0,
            calldata:     Vec::new(),
            storage:      HashMap::new(),
            block_number: 1,
            timestamp:    1_700_000_000,
        }
    }
}

impl ExecutionContext {
    pub fn with_caller(mut self, caller: Address) -> Self {
        self.caller = caller;
        self
    }
    pub fn with_value(mut self, value: u128) -> Self {
        self.call_value = value;
        self
    }
    pub fn with_calldata(mut self, data: Vec<u8>) -> Self {
        self.calldata = data;
        self
    }
    pub fn with_storage_slot(mut self, key: [u8; 32], value: [u8; 32]) -> Self {
        self.storage.insert(key, value);
        self
    }
}
