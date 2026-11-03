//! CTF Challenge 04 — Flash Loan Attack với Integer Overflow
//!
//! # Mô tả lỗ hổng
//! Flash loan protocol cho phép vay không có tài sản thế chấp miễn là hoàn trả
//! trong cùng một transaction. Lỗi phát sinh khi:
//! 1. Fee calculation bị overflow (u64 wrapping arithmetic)
//! 2. Repay check không chính xác do integer underflow
//! 3. Kết quả: vay 1_000_000 tokens, trả 0 tokens (overflow về 0)
//!
//! # Nguồn gốc
//! - Euler Finance (2023) — $197M tổn thất do donate + liquidation logic
//! - Safemoon (2023) — flash loan + fee manipulation
//! - Nhiều AMM fork sử dụng `+/-` thay vì `checked_add/checked_sub`
//!
//! # Mục tiêu CTF
//! Tìm dòng code gây overflow trong `repay_vulnerable` và sửa bằng
//! `checked_mul`, `checked_add`, `checked_sub`.

use anchor_lang::prelude::*;

declare_id!(env!("CTF_FLASH_LOAN_PROGRAM_ID", "1111111111111111111111111111111111111111114"));

/// Fee rate = 30 basis points (0.3%)
const FEE_BPS: u64 = 30;
const BPS_DENOM: u64 = 10_000;

#[program]
pub mod ctf_flash_loan {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, liquidity: u64) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        pool.total_liquidity     = liquidity;
        pool.outstanding_borrow  = 0;
        pool.total_fees_collected = 0;
        Ok(())
    }

    /// Bắt đầu flash loan — ghi nợ vào state
    pub fn flash_borrow(ctx: Context<FlashBorrow>, amount: u64) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        require!(pool.outstanding_borrow == 0, FlashLoanError::BorrowAlreadyOpen);
        require!(amount <= pool.total_liquidity, FlashLoanError::InsufficientLiquidity);

        pool.outstanding_borrow = amount;
        // Transfer tokens to borrower (simplified: update balance)
        pool.total_liquidity -= amount;

        emit!(BorrowEvent { borrower: ctx.accounts.borrower.key(), amount });
        Ok(())
    }

    /// ❌ DỄBỊ TẤN CÔNG — tính fee dùng wrapping arithmetic, không overflow check
    ///
    /// Khi amount = u64::MAX / FEE_BPS + 1, phép nhân overflow về 0 → fee = 0
    /// → borrower trả lại amount gốc nhưng fee = 0 (miễn phí!)
    pub fn flash_repay_vulnerable(ctx: Context<FlashRepay>, amount: u64) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        require!(pool.outstanding_borrow > 0, FlashLoanError::NoBorrowOpen);

        // ❌ Wrapping multiply — overflow possible on large amounts
        let fee = amount * FEE_BPS / BPS_DENOM;
        let required = amount + fee; // ❌ Cũng có thể overflow

        // Kiểm tra repay đủ không
        require!(amount >= pool.outstanding_borrow, FlashLoanError::InsufficientRepay);

        pool.total_liquidity      += required; // ❌ Có thể overflow
        pool.total_fees_collected += fee;
        pool.outstanding_borrow   = 0;

        emit!(RepayEvent {
            amount,
            fee,
            vulnerable: true,
        });
        Ok(())
    }

    /// ✅ ĐÃ SỬA — dùng checked arithmetic, panic/error khi overflow
    pub fn flash_repay_fixed(ctx: Context<FlashRepay>, amount: u64) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        require!(pool.outstanding_borrow > 0, FlashLoanError::NoBorrowOpen);

        // ✅ checked_mul + checked_div
        let fee = amount
            .checked_mul(FEE_BPS)
            .and_then(|v| v.checked_div(BPS_DENOM))
            .ok_or(FlashLoanError::MathOverflow)?;

        // ✅ checked_add
        let required = amount
            .checked_add(fee)
            .ok_or(FlashLoanError::MathOverflow)?;

        require!(amount >= pool.outstanding_borrow, FlashLoanError::InsufficientRepay);

        pool.total_liquidity = pool.total_liquidity
            .checked_add(required)
            .ok_or(FlashLoanError::MathOverflow)?;
        pool.total_fees_collected = pool.total_fees_collected
            .checked_add(fee)
            .ok_or(FlashLoanError::MathOverflow)?;
        pool.outstanding_borrow = 0;

        emit!(RepayEvent {
            amount,
            fee,
            vulnerable: false,
        });
        Ok(())
    }
}

// ─── Accounts ───────────────────────────────────────────────────────────────

#[account]
pub struct FlashPool {
    pub total_liquidity:      u64,
    pub outstanding_borrow:   u64,
    pub total_fees_collected: u64,
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = authority, space = 8 + 8 + 8 + 8)]
    pub pool:           Account<'info, FlashPool>,
    #[account(mut)]
    pub authority:      Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct FlashBorrow<'info> {
    #[account(mut)]
    pub pool:     Account<'info, FlashPool>,
    pub borrower: Signer<'info>,
}

#[derive(Accounts)]
pub struct FlashRepay<'info> {
    #[account(mut)]
    pub pool:     Account<'info, FlashPool>,
    pub borrower: Signer<'info>,
}

// ─── Events & Errors ────────────────────────────────────────────────────────

#[event]
pub struct BorrowEvent {
    pub borrower: Pubkey,
    pub amount:   u64,
}

#[event]
pub struct RepayEvent {
    pub amount:     u64,
    pub fee:        u64,
    pub vulnerable: bool,
}

#[error_code]
pub enum FlashLoanError {
    #[msg("Another borrow is already open")]
    BorrowAlreadyOpen,
    #[msg("No open borrow to repay")]
    NoBorrowOpen,
    #[msg("Insufficient liquidity")]
    InsufficientLiquidity,
    #[msg("Repay amount is less than borrowed")]
    InsufficientRepay,
    #[msg("Math overflow in fee calculation")]
    MathOverflow,
}

// ─── CTF Notes ───────────────────────────────────────────────────────────────
//
// EXPLOIT CALCULATION:
// Nếu amount = 614_891_469_123_651_720 (giá trị gây overflow với FEE_BPS=30):
//   amount * 30 = overflow về 0 (wrapping)
//   fee = 0 / 10_000 = 0
//   required = amount + 0 = amount (không cộng fee)
// → Borrower vay miễn phí hoàn toàn!
//
// QUIZ QUESTIONS:
// 1. Tìm giá trị nhỏ nhất của `amount` gây overflow u64 * 30.
// 2. Rust production build có `overflow-checks = true` không? Kiểm tra Cargo.toml.
// 3. Solana programs chạy trong BPF — overflow behavior có khác EVM không?
//
// BONUS: Implement `fee_with_saturating` và giải thích tại sao vẫn cần `checked`.
