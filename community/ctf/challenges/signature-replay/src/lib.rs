//! CTF Challenge 05 — Signature Replay Attack
//!
//! # Mô tả lỗ hổng
//! Protocol verify chữ ký off-chain (Meta-transaction / Permit pattern),
//! nhưng không lưu nonce → cùng một chữ ký có thể được dùng lại nhiều lần.
//!
//! # Nguồn gốc audit thực tế
//! - ERC-2612 `permit()` implementations không track nonce properly
//! - SWIFT message authentication: nếu LAU header không có timestamp/nonce,
//!   một message có thể được relay lại nhiều lần → double payment
//! - Bridge contracts: signed withdrawal message bị replay trên chain khác
//!
//! # Mục tiêu CTF
//! 1. Giải thích tại sao `execute_vulnerable` chấp nhận replay
//! 2. Implement nonce tracking trong `execute_fixed`
//! 3. Liên kết với SWIFT LAU (Local Authentication): nonce trong ISO 20022
//!
//! # Cấu trúc message an toàn (EIP-712 style)
//! ```
//! struct TransferMessage {
//!     from:    Pubkey,
//!     to:      Pubkey,
//!     amount:  u64,
//!     nonce:   u64,     ← PHẢI CÓ — ngăn replay
//!     expiry:  i64,     ← PHẢI CÓ — ngăn stale message
//! }
//! ```

use anchor_lang::prelude::*;
use sha2::{Sha256, Digest};

declare_id!(env!("CTF_SIGNATURE_REPLAY_PROGRAM_ID", "1111111111111111111111111111111111111111115"));

#[program]
pub mod ctf_signature_replay {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let state = &mut ctx.accounts.state;
        state.total_transferred = 0;
        state.authority = ctx.accounts.authority.key();
        Ok(())
    }

    /// ❌ DỄBỊ REPLAY — chỉ verify signature content, không check nonce
    ///
    /// Attacker có thể lưu một signed message hợp lệ và gửi lại nhiều lần
    pub fn execute_vulnerable(
        ctx:       Context<Execute>,
        amount:    u64,
        recipient: Pubkey,
        signature_hash: [u8; 32],  // simplified: sha256(amount || recipient)
    ) -> Result<()> {
        // ❌ Chỉ verify hash content — không có nonce, không có expiry
        let mut hasher = Sha256::new();
        hasher.update(amount.to_le_bytes());
        hasher.update(recipient.to_bytes());
        let expected: [u8; 32] = hasher.finalize().into();

        require!(signature_hash == expected, ReplayError::InvalidSignature);

        // Transfer amount (simplified)
        ctx.accounts.state.total_transferred += amount;

        emit!(TransferEvent {
            recipient,
            amount,
            nonce:      0, // ❌ không có nonce
            vulnerable: true,
        });
        Ok(())
    }

    /// ✅ ĐÃ SỬA — nonce + expiry + nonce invalidation sau khi dùng
    pub fn execute_fixed(
        ctx:       Context<Execute>,
        amount:    u64,
        recipient: Pubkey,
        nonce:     u64,
        expiry:    i64,
        signature_hash: [u8; 32],
    ) -> Result<()> {
        let state = &mut ctx.accounts.state;
        let clock = Clock::get()?;

        // ✅ Kiểm tra expiry
        require!(clock.unix_timestamp <= expiry, ReplayError::MessageExpired);

        // ✅ Kiểm tra nonce chưa được dùng (monotonic nonce)
        require!(nonce == state.next_nonce, ReplayError::InvalidNonce);

        // ✅ Verify signature (bao gồm nonce và expiry)
        let mut hasher = Sha256::new();
        hasher.update(amount.to_le_bytes());
        hasher.update(recipient.to_bytes());
        hasher.update(nonce.to_le_bytes());
        hasher.update(expiry.to_le_bytes());
        let expected: [u8; 32] = hasher.finalize().into();

        require!(signature_hash == expected, ReplayError::InvalidSignature);

        // ✅ Invalidate nonce — không thể replay
        state.next_nonce += 1;
        state.total_transferred = state.total_transferred
            .checked_add(amount)
            .ok_or(ReplayError::MathOverflow)?;

        emit!(TransferEvent {
            recipient,
            amount,
            nonce,
            vulnerable: false,
        });
        Ok(())
    }
}

// ─── Accounts ───────────────────────────────────────────────────────────────

#[account]
pub struct ProtocolState {
    pub authority:         Pubkey,
    pub total_transferred: u64,
    pub next_nonce:        u64,
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = authority, space = 8 + 32 + 8 + 8)]
    pub state:          Account<'info, ProtocolState>,
    #[account(mut)]
    pub authority:      Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Execute<'info> {
    #[account(mut)]
    pub state: Account<'info, ProtocolState>,
    pub authority: Signer<'info>,
}

// ─── Events & Errors ────────────────────────────────────────────────────────

#[event]
pub struct TransferEvent {
    pub recipient:  Pubkey,
    pub amount:     u64,
    pub nonce:      u64,
    pub vulnerable: bool,
}

#[error_code]
pub enum ReplayError {
    #[msg("Invalid signature hash")]
    InvalidSignature,
    #[msg("Message has expired")]
    MessageExpired,
    #[msg("Invalid nonce — already used or out of order")]
    InvalidNonce,
    #[msg("Math overflow")]
    MathOverflow,
}

// ─── CTF Notes ───────────────────────────────────────────────────────────────
//
// QUIZ QUESTIONS:
// 1. Nếu Alice ký một message "transfer 100 USDC to Bob" và không có nonce,
//    Bob có thể làm gì với chữ ký đó? Ai có thể relay message này?
//
// 2. SWIFT ISO 20022 pacs.008 có trường nào ngăn replay?
//    (Gợi ý: xem packages/swift-adapter/src/iso20022/)
//
// 3. Triển khai nonce kiểu bitmap thay vì monotonic counter —
//    ưu điểm và nhược điểm là gì?
//
// THỰC TẾ: Cầu nối SWIFT↔Blockchain
// Mỗi MT103 message phải có UETR (Unique End-to-End Transaction Reference)
// được lưu on-chain để ngăn double settlement.
// programs/swift-bridge sử dụng pattern này — xem src/lib.rs.
