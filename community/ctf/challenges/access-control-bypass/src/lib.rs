//! CTF Challenge 03 — Access Control Bypass
//!
//! # Mô tả lỗ hổng
//! Hàm admin chỉ kiểm tra `authority.key()` khớp với stored admin,
//! nhưng không yêu cầu `authority` phải ký giao dịch (`Signer`).
//! Kết quả: bất kỳ ai cũng có thể truyền địa chỉ admin vào và thực thi hàm admin.
//!
//! # Nguồn gốc audit thực tế
//! - Wormhole (2022) — $320M tổn thất do missing signer check
//! - Solana ecosystem có nhiều program thiếu `Signer` constraint
//! - Trong compliance module: ai cũng có thể set KYC_APPROVED nếu thiếu check
//!
//! # Pattern lỗi (Solana-specific)
//! ```rust
//! // ❌ SAI — AccountInfo không enforce signature
//! #[account(mut)]
//! pub authority: AccountInfo<'info>,  // chỉ cần pass đúng pubkey là qua!
//!
//! // ✅ ĐÚNG — Signer macro enforce signature
//! pub authority: Signer<'info>,       // tx phải được ký bởi authority
//! ```

use anchor_lang::prelude::*;

declare_id!(env!("CTF_ACCESS_CONTROL_PROGRAM_ID", "1111111111111111111111111111111111111111113"));

#[program]
pub mod ctf_access_control {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, admin: Pubkey) -> Result<()> {
        let registry = &mut ctx.accounts.registry;
        registry.admin         = admin;
        registry.kyc_threshold = 1_000_000; // 1 USDC tối đa không cần KYC
        registry.paused        = false;
        Ok(())
    }

    /// ❌ HÀM DỄ BỊ BYPASS — authority chỉ là AccountInfo, không phải Signer
    ///
    /// Bất kỳ ai biết địa chỉ admin đều có thể gọi hàm này mà không cần private key.
    pub fn set_kyc_threshold_vulnerable(
        ctx:       Context<AdminActionVulnerable>,
        threshold: u64,
    ) -> Result<()> {
        let registry = &mut ctx.accounts.registry;
        // Kiểm tra key đúng — nhưng KHÔNG verify signature!
        require!(
            ctx.accounts.authority.key() == registry.admin,
            AccessError::Unauthorized
        );
        registry.kyc_threshold = threshold;

        emit!(AdminAction {
            action:     "set_kyc_threshold".to_string(),
            value:      threshold,
            vulnerable: true,
        });
        Ok(())
    }

    /// ✅ HÀM ĐÃ SỬA — authority là Signer<'info> → runtime verify signature
    pub fn set_kyc_threshold_fixed(
        ctx:       Context<AdminActionFixed>,
        threshold: u64,
    ) -> Result<()> {
        let registry = &mut ctx.accounts.registry;
        require!(
            ctx.accounts.authority.key() == registry.admin,
            AccessError::Unauthorized
        );
        registry.kyc_threshold = threshold;

        emit!(AdminAction {
            action:     "set_kyc_threshold".to_string(),
            value:      threshold,
            vulnerable: false,
        });
        Ok(())
    }

    /// ❌ Tương tự — pause protocol mà không cần ký
    pub fn pause_protocol_vulnerable(ctx: Context<AdminActionVulnerable>) -> Result<()> {
        let registry = &mut ctx.accounts.registry;
        require!(ctx.accounts.authority.key() == registry.admin, AccessError::Unauthorized);
        registry.paused = true;

        emit!(AdminAction {
            action:     "pause_protocol".to_string(),
            value:      1,
            vulnerable: true,
        });
        Ok(())
    }

    /// ✅ Đã sửa
    pub fn pause_protocol_fixed(ctx: Context<AdminActionFixed>) -> Result<()> {
        let registry = &mut ctx.accounts.registry;
        require!(ctx.accounts.authority.key() == registry.admin, AccessError::Unauthorized);
        registry.paused = true;

        emit!(AdminAction {
            action:     "pause_protocol".to_string(),
            value:      1,
            vulnerable: false,
        });
        Ok(())
    }
}

// ─── Accounts ───────────────────────────────────────────────────────────────

#[account]
pub struct Registry {
    pub admin:         Pubkey,
    pub kyc_threshold: u64,
    pub paused:        bool,
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = payer, space = 8 + 32 + 8 + 1)]
    pub registry:       Account<'info, Registry>,
    #[account(mut)]
    pub payer:          Signer<'info>,
    pub system_program: Program<'info, System>,
}

/// ❌ VULNERABLE — authority không phải Signer
#[derive(Accounts)]
pub struct AdminActionVulnerable<'info> {
    #[account(mut)]
    pub registry: Account<'info, Registry>,
    /// CHECK: ❌ Chỉ là AccountInfo — không enforce signature!
    pub authority: AccountInfo<'info>,
}

/// ✅ FIXED — authority phải ký giao dịch
#[derive(Accounts)]
pub struct AdminActionFixed<'info> {
    #[account(mut)]
    pub registry: Account<'info, Registry>,
    /// ✅ Signer — runtime enforces signature verification
    pub authority: Signer<'info>,
}

// ─── Events & Errors ────────────────────────────────────────────────────────

#[event]
pub struct AdminAction {
    pub action:     String,
    pub value:      u64,
    pub vulnerable: bool,
}

#[error_code]
pub enum AccessError {
    #[msg("Unauthorized: caller is not admin")]
    Unauthorized,
    #[msg("Protocol is paused")]
    ProtocolPaused,
}

// ─── CTF Notes ───────────────────────────────────────────────────────────────
//
// QUIZ QUESTIONS:
// 1. Sự khác nhau giữa `AccountInfo` và `Signer` trong Anchor là gì?
// 2. Tại sao Wormhole mất $320M từ lỗi này? Research và giải thích.
// 3. Trong `AdminActionVulnerable`, một attacker cần làm gì để bypass?
//    (Hint: họ chỉ cần biết admin pubkey và truyền vào như AccountInfo)
//
// THÁCH THỨC BỔ SUNG:
// - Implement role-based access với PDA roles account (như ROLES module trong Bophades)
// - Thêm multi-sig: require 2/3 signers cho admin operations
