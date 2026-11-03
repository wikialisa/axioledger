//! CTF Challenge 01 — Reentrancy Attack
//!
//! # Mô tả lỗ hổng
//! Contract chuyển tiền ra ngoài (CPI / external call) TRƯỚC KHI cập nhật state nội bộ.
//! Kẻ tấn công deploy một contract có hàm fallback gọi lại contract gốc trước khi
//! state được reset, cho phép rút nhiều hơn số dư thực tế.
//!
//! # Nguồn gốc
//! Lỗi tương tự đã xuất hiện trong:
//! - TheDAO hack (2016) — $60M ETH bị rút
//! - Cream Finance (2021) — $130M tổn thất
//! - Một số Solana escrow program trong giai đoạn audit thực tế
//!
//! # Mục tiêu CTF
//! Tìm hàm `withdraw_vulnerable` và giải thích tại sao nó có thể bị khai thác.
//! Viết test chứng minh khai thác, rồi viết `withdraw_fixed` khắc phục bằng
//! checks-effects-interactions pattern.
//!
//! # Checks-Effects-Interactions Pattern
//! ```
//! // ❌ SAI — External call trước khi update state
//! transfer_lamports(amount);
//! user_balance = 0;
//!
//! // ✅ ĐÚNG — Update state trước khi external call
//! user_balance = 0;       // Effect
//! transfer_lamports(amount); // Interaction
//! ```

use anchor_lang::prelude::*;

declare_id!(env!("CTF_REENTRANCY_PROGRAM_ID", "1111111111111111111111111111111111111111111"));

#[program]
pub mod ctf_reentrancy {
    use super::*;

    /// Khởi tạo vault với số dư ban đầu
    pub fn initialize(ctx: Context<Initialize>, amount: u64) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        vault.owner   = ctx.accounts.depositor.key();
        vault.balance = amount;
        vault.bump    = ctx.bumps.vault;
        Ok(())
    }

    /// ❌ HÀM DỄ BỊ TẤN CÔNG — chuyển tiền TRƯỚC khi reset balance
    ///
    /// Lỗi: nếu `destination` là một contract có callback,
    /// nó có thể gọi lại `withdraw_vulnerable` trước khi `vault.balance = 0`
    pub fn withdraw_vulnerable(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        require!(vault.balance >= amount, VaultError::InsufficientBalance);
        require!(vault.owner == ctx.accounts.owner.key(), VaultError::Unauthorized);

        // ❌ EXTERNAL CALL trước khi update state
        **ctx.accounts.vault.to_account_info().try_borrow_mut_lamports()? -= amount;
        **ctx.accounts.destination.try_borrow_mut_lamports()? += amount;

        // ❌ State update xảy ra SAU external call — quá muộn!
        vault.balance -= amount;

        emit!(WithdrawEvent {
            owner:  vault.owner,
            amount,
            vulnerable: true,
        });
        Ok(())
    }

    /// ✅ HÀM ĐÃ SỬA — update state TRƯỚC khi chuyển tiền
    ///
    /// Checks-Effects-Interactions pattern:
    /// 1. Check: require balance >= amount
    /// 2. Effect: vault.balance = 0  ← state update TRƯỚC
    /// 3. Interaction: transfer lamports ← external call SAU
    pub fn withdraw_fixed(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        require!(vault.balance >= amount, VaultError::InsufficientBalance);
        require!(vault.owner == ctx.accounts.owner.key(), VaultError::Unauthorized);

        // ✅ Effect TRƯỚC interaction
        vault.balance -= amount;

        // ✅ External call SAU khi state đã an toàn
        **ctx.accounts.vault.to_account_info().try_borrow_mut_lamports()? -= amount;
        **ctx.accounts.destination.try_borrow_mut_lamports()? += amount;

        emit!(WithdrawEvent {
            owner:  vault.owner,
            amount,
            vulnerable: false,
        });
        Ok(())
    }
}

// ─── Accounts ───────────────────────────────────────────────────────────────

#[account]
pub struct Vault {
    pub owner:   Pubkey,
    pub balance: u64,
    pub bump:    u8,
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer  = depositor,
        space  = 8 + 32 + 8 + 1,
        seeds  = [b"vault", depositor.key().as_ref()],
        bump
    )]
    pub vault:     Account<'info, Vault>,
    #[account(mut)]
    pub depositor: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(mut, has_one = owner)]
    pub vault:       Account<'info, Vault>,
    pub owner:       Signer<'info>,
    /// CHECK: destination wallet — verified by caller
    #[account(mut)]
    pub destination: AccountInfo<'info>,
}

// ─── Events & Errors ────────────────────────────────────────────────────────

#[event]
pub struct WithdrawEvent {
    pub owner:      Pubkey,
    pub amount:     u64,
    pub vulnerable: bool,
}

#[error_code]
pub enum VaultError {
    #[msg("Insufficient balance")]
    InsufficientBalance,
    #[msg("Unauthorized: caller is not vault owner")]
    Unauthorized,
}

// ─── CTF Notes ───────────────────────────────────────────────────────────────
//
// QUIZ QUESTIONS:
// 1. Tại sao `withdraw_vulnerable` có thể bị gọi nhiều lần liên tiếp?
// 2. Solana runtime có cơ chế nào ngăn reentrancy tự nhiên không?
//    (Gợi ý: research "Solana CPI reentrancy guard")
// 3. Viết một Anchor test tái hiện reentrancy sử dụng một program giả lập callback.
//
// ĐIỂM THƯỞNG:
// - Implement mutex guard bằng PDA lock account
// - So sánh với EVM: tại sao `nonReentrant` modifier cần thiết trong Solidity?
