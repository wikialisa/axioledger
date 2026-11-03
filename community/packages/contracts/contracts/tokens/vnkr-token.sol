// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ─── YOUR_TOKEN-token.sol — YOUR_TOKEN ───────────────────────────────────────────────────
// YOUR_TOKEN Reserve Currency (ERC-20).
// Bảo chứng tài sản — cung tối đa điều tiết bởi MINTRv1 và Bể dự trữ Kho bạc.
// Chỉ địa chỉ được giao quyền mintAuthority (MINTRv1) mới được mint/burn.
// ─────────────────────────────────────────────────────────────────────────────

error AXVN_NotAuthorized(address caller);

contract YOUR_TOKENToken is ERC20, Ownable {
    // ─── State ────────────────────────────────────────────────────────────

    address public mintAuthority;

    // ─── Events ───────────────────────────────────────────────────────────

    event MintAuthorityUpdated(address indexed prev, address indexed next);

    // ─── Constructor ──────────────────────────────────────────────────────

    constructor(address admin_)
        ERC20("YOUR_TOKEN Reserve Token", "YOUR_TOKEN")
        Ownable(admin_)
    {}

    // ─── Authority management ─────────────────────────────────────────────

    /// @notice Transfer mint/burn authority to MINTRv1 module after deploy
    function setMintAuthority(address authority_) external onlyOwner {
        emit MintAuthorityUpdated(mintAuthority, authority_);
        mintAuthority = authority_;
    }

    // ─── Mint / Burn ──────────────────────────────────────────────────────

    modifier onlyMintAuthority() {
        if (msg.sender != mintAuthority) revert AXVN_NotAuthorized(msg.sender);
        _;
    }

    /// @notice Mint YOUR_TOKEN — callable only by MINTRv1
    function mint(address to_, uint256 amount_) external onlyMintAuthority {
        _mint(to_, amount_);
    }

    /// @notice Burn YOUR_TOKEN — callable only by MINTRv1 (deflationary burn)
    function burn(address from_, uint256 amount_) external onlyMintAuthority {
        _burn(from_, amount_);
    }

    // ─── Standard helpers ─────────────────────────────────────────────────

    function decimals() public pure override returns (uint8) { return 18; }
}
