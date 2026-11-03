//! CTF Challenge 02 — Oracle Price Manipulation
//!
//! # Mô tả lỗ hổng
//! Protocol dùng tỷ giá từ AMM on-chain (spot price) làm oracle.
//! Kẻ tấn công dùng flash loan để manipulate pool spot price trong một giao dịch,
//! thực hiện giao dịch có lợi, rồi repay flash loan — toàn bộ trong một tx.
//!
//! # Nguồn gốc audit thực tế
//! - Mango Markets (2022) — $114M tổn thất do oracle manipulation
//! - Beanstalk (2022) — $181M qua governance flash loan
//! - SWIFT-to-DeFi bridges: tỷ giá SBV lấy từ single source → điểm tấn công
//!
//! # Mục tiêu CTF
//! 1. Giải thích tại sao `get_spot_price` bị manipulate
//! 2. Implement `get_twap_price` — Time-Weighted Average Price (chống manipulation)
//! 3. So sánh TWAP vs Chainlink oracle trong bối cảnh SWIFT-on-chain bridge
//!
//! # Kiến thức cần có
//! - AMM x*y=k price formula
//! - Flash loan mechanics
//! - TWAP calculation (Uniswap v2 cumulative price)

use anchor_lang::prelude::*;

declare_id!(env!("CTF_ORACLE_PROGRAM_ID", "1111111111111111111111111111111111111111112"));

#[program]
pub mod ctf_oracle_manipulation {
    use super::*;

    /// Khởi tạo pool giả lập với reserve ban đầu
    pub fn initialize_pool(
        ctx:      Context<InitPool>,
        reserve_a: u64,
        reserve_b: u64,
    ) -> Result<()> {
        let pool = &mut ctx.accounts.pool;
        pool.reserve_a       = reserve_a;
        pool.reserve_b       = reserve_b;
        pool.last_update_slot = Clock::get()?.slot;
        pool.price_cumulative = 0;
        Ok(())
    }

    /// ❌ Lấy giá HIỆN TẠI từ pool — dễ bị manipulate bằng flash loan
    ///
    /// Spot price = reserve_b / reserve_a (tỷ giá tức thời)
    /// Vấn đề: giá có thể bị thay đổi trong cùng một transaction
    pub fn get_spot_price(ctx: Context<ReadPool>) -> Result<u64> {
        let pool = &ctx.accounts.pool;
        require!(pool.reserve_a > 0, OracleError::ZeroReserve);

        // ❌ Spot price — không an toàn khi dùng làm oracle
        let spot_price = pool.reserve_b
            .checked_div(pool.reserve_a)
            .ok_or(OracleError::MathOverflow)?;

        emit!(PriceEvent { price: spot_price, oracle_type: OracleType::Spot });
        Ok(spot_price)
    }

    /// ✅ TWAP — Time-Weighted Average Price (an toàn hơn)
    ///
    /// Tính trung bình giá theo thời gian từ `price_cumulative`.
    /// Kẻ tấn công phải duy trì giá thao túng qua NHIỀU slot — chi phí cực cao.
    pub fn get_twap_price(ctx: Context<ReadPool>) -> Result<u64> {
        let pool      = &ctx.accounts.pool;
        let clock     = Clock::get()?;
        let elapsed   = clock.slot.saturating_sub(pool.last_update_slot);

        require!(elapsed > 0, OracleError::InsufficientTwapWindow);
        require!(pool.price_cumulative > 0, OracleError::NoPriceHistory);

        // TWAP = cumulative_price / elapsed_slots
        let twap = pool.price_cumulative
            .checked_div(elapsed)
            .ok_or(OracleError::MathOverflow)?;

        emit!(PriceEvent { price: twap, oracle_type: OracleType::Twap });
        Ok(twap)
    }

    /// Cập nhật pool reserve (simulate swap — cập nhật price_cumulative)
    pub fn update_reserve(
        ctx:      Context<UpdatePool>,
        new_reserve_a: u64,
        new_reserve_b: u64,
    ) -> Result<()> {
        let pool  = &mut ctx.accounts.pool;
        let clock = Clock::get()?;

        // Accumulate spot price * elapsed_slots vào cumulative
        let elapsed = clock.slot.saturating_sub(pool.last_update_slot);
        if pool.reserve_a > 0 && elapsed > 0 {
            let spot = pool.reserve_b / pool.reserve_a;
            pool.price_cumulative = pool.price_cumulative
                .saturating_add(spot.saturating_mul(elapsed));
        }

        pool.reserve_a        = new_reserve_a;
        pool.reserve_b        = new_reserve_b;
        pool.last_update_slot = clock.slot;
        Ok(())
    }
}

// ─── Accounts ───────────────────────────────────────────────────────────────

#[account]
pub struct Pool {
    pub reserve_a:        u64,
    pub reserve_b:        u64,
    pub last_update_slot: u64,
    pub price_cumulative: u64,
}

#[derive(Accounts)]
pub struct InitPool<'info> {
    #[account(init, payer = authority, space = 8 + 8 + 8 + 8 + 8)]
    pub pool:      Account<'info, Pool>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ReadPool<'info> {
    pub pool: Account<'info, Pool>,
}

#[derive(Accounts)]
pub struct UpdatePool<'info> {
    #[account(mut)]
    pub pool:      Account<'info, Pool>,
    pub authority: Signer<'info>,
}

// ─── Events & Errors ────────────────────────────────────────────────────────

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub enum OracleType { Spot, Twap }

#[event]
pub struct PriceEvent {
    pub price:       u64,
    pub oracle_type: OracleType,
}

#[error_code]
pub enum OracleError {
    #[msg("Reserve cannot be zero")]
    ZeroReserve,
    #[msg("Math overflow")]
    MathOverflow,
    #[msg("Insufficient TWAP window — need more price history")]
    InsufficientTwapWindow,
    #[msg("No price history available")]
    NoPriceHistory,
}

// ─── CTF Notes ───────────────────────────────────────────────────────────────
//
// QUIZ QUESTIONS:
// 1. Vì sao một flash loan transaction có thể thay đổi spot price 10x?
// 2. TWAP cần ít nhất bao nhiêu slot để đủ an toàn? (Hint: Solana ~400ms/slot)
// 3. Trong context SWIFT-bridge: nếu tỷ giá USD/VND lấy từ on-chain AMM,
//    ai có thể kiếm lợi từ thao túng giá trước khi settlement?
//
// BONUS CHALLENGE:
// - Implement Chainlink-style push oracle với price staleness check
// - So sánh gas cost: TWAP accumulator vs external oracle call
