// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../kernel/Module.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ─── mintr-module.v1.sol — MINTR ─────────────────────────────────────────────
// Kiểm soát đúc (Mint) và đốt (Burn) token YOUR_TOKEN theo cơ chế bảo chứng Kho bạc.
// Chỉ các Policy được cấp phép (StakingPolicy, BondTeller) mới có thể gọi mint/burn.
// ─────────────────────────────────────────────────────────────────────────────

error MINTR_ZeroAmount();
error MINTR_NotMintable();

interface IMintable is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract MINTRv1 is Module {
    // ─── State ────────────────────────────────────────────────────────────

    IMintable public YOUR_TOKEN;

    uint256 public totalMinted;
    uint256 public totalBurned;

    /// @notice Maximum supply cap: 10,000,000,000,000 YOUR_TOKEN (18 decimals)
    uint256 public constant RESERVE_CAP = 10_000_000_000_000 * 1e18;

    // ─── Events ───────────────────────────────────────────────────────────

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    // ─── Constructor ──────────────────────────────────────────────────────

    constructor(Kernel kernel_, address YOUR_TOKEN_) Module(kernel_) {
        YOUR_TOKEN = IMintable(AXVN_);
    }

    // ─── Module interface ─────────────────────────────────────────────────

    function KEYCODE() external pure override returns (bytes5) { return "MINTR"; }
    function VERSION() external pure override returns (uint8 major, uint8 minor) { return (1, 0); }

    // ─── Permissioned writes ──────────────────────────────────────────────

    /// @notice Mint YOUR_TOKEN tokens — must not exceed RESERVE_CAP
    function mintYOUR_TOKEN(address to_, uint256 amount_) external permissioned {
        if (amount_ == 0) revert MINTR_ZeroAmount();
        require(YOUR_TOKEN.totalSupply() + amount_ <= RESERVE_CAP, "MINTR: cap exceeded");
        totalMinted += amount_;
        YOUR_TOKEN.mint(to_, amount_);
        emit Minted(to_, amount_);
    }

    /// @notice Burn YOUR_TOKEN tokens (deflationary mechanism)
    function burnYOUR_TOKEN(address from_, uint256 amount_) external permissioned {
        if (amount_ == 0) revert MINTR_ZeroAmount();
        totalBurned += amount_;
        YOUR_TOKEN.burn(from_, amount_);
        emit Burned(from_, amount_);
    }

    // ─── View ─────────────────────────────────────────────────────────────

    function circulatingSupply() external view returns (uint256) {
        return YOUR_TOKEN.totalSupply();
    }

    function remainingCap() external view returns (uint256) {
        uint256 supply = YOUR_TOKEN.totalSupply();
        return supply < RESERVE_CAP ? RESERVE_CAP - supply : 0;
    }
}
