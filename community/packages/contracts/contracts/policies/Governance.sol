// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../kernel/Module.sol";
import "../modules/ROLES/ROLES.v1.sol";
import "../tokens/sYOUR_TOKENToken.sol";
import "../tokens/gYOUR_TOKENToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ─── Governance.sol — Wrap sAXVN → gAXVN (Index Multiplier) ─────────────────
// Wrap sAXVN thành gAXVN có chỉ số nhân (Index) để biểu quyết DAO,
// giao dịch Cross-Chain và thế chấp tín chấp tại các L2/Sidechain.
// ─────────────────────────────────────────────────────────────────────────────

using SafeERC20 for IERC20;

error Governance_ZeroAmount();
error Governance_InvalidIndex();

contract Governance is Policy {
    // ─── Modules ──────────────────────────────────────────────────────────

    ROLESv1    public ROLES;
    SYOUR_TOKENToken public sAXVN;
    GYOUR_TOKENToken public gAXVN;

    // ─── Index (gAXVN index multiplier — tăng theo mỗi Epoch rebase) ────
    /// @notice Index = tổng tích lũy rebase — 1 gAXVN = index × sAXVN (18 dec)
    uint256 public index = 1e18;

    // ─── Events ───────────────────────────────────────────────────────────

    event Wrapped(address indexed user, uint256 sAXVNIn, uint256 gAXVNOut);
    event Unwrapped(address indexed user, uint256 gAXVNIn, uint256 sAXVNOut);
    event IndexUpdated(uint256 prevIndex, uint256 newIndex);

    // ─── Constructor ──────────────────────────────────────────────────────

    constructor(Kernel kernel_, address sAXVN_, address gAXVN_) Policy(kernel_) {
        sAXVN = SYOUR_TOKENToken(sAXVN_);
        gAXVN = GYOUR_TOKENToken(gAXVN_);
    }

    // ─── Policy interface ─────────────────────────────────────────────────

    function configureDependencies() external override returns (bytes5[] memory deps) {
        deps    = new bytes5[](1);
        deps[0] = "ROLES";
        ROLES   = ROLESv1(getModuleAddress("ROLES"));
    }

    function requestPermissions() external view override returns (Permissions[] memory reqs) {
        reqs = new Permissions[](0);
    }

    // ─── Wrap / Unwrap ────────────────────────────────────────────────────

    /// @notice Wrap sAXVN → gAXVN theo index hiện tại
    /// gAXVNOut = sAXVNIn × 1e18 / index
    function wrap(uint256 sAXVNAmount_) external returns (uint256 gAXVNOut) {
        if (sAXVNAmount_ == 0) revert Governance_ZeroAmount();
        if (index == 0) revert Governance_InvalidIndex();
        gAXVNOut = (sAXVNAmount_ * 1e18) / index;
        sAXVN.burn(msg.sender, sAXVNAmount_);
        gAXVN.mint(msg.sender, gAXVNOut);
        emit Wrapped(msg.sender, sAXVNAmount_, gAXVNOut);
    }

    /// @notice Unwrap gAXVN → sAXVN theo index hiện tại
    /// sAXVNOut = gAXVNIn × index / 1e18
    function unwrap(uint256 gAXVNAmount_) external returns (uint256 sAXVNOut) {
        if (gAXVNAmount_ == 0) revert Governance_ZeroAmount();
        sAXVNOut = (gAXVNAmount_ * index) / 1e18;
        gAXVN.burn(msg.sender, gAXVNAmount_);
        sAXVN.mint(msg.sender, sAXVNOut);
        emit Unwrapped(msg.sender, gAXVNAmount_, sAXVNOut);
    }

    /// @notice Cập nhật index sau mỗi Epoch rebase (gọi bởi StakingPolicy)
    function updateIndex(uint256 newIndex_) external {
        require(kernel.isPolicyActive(address(this)), "Governance: not active");
        if (newIndex_ == 0) revert Governance_InvalidIndex();
        emit IndexUpdated(index, newIndex_);
        index = newIndex_;
    }

    // ─── View helpers ─────────────────────────────────────────────────────

    /// @notice Quy đổi sAXVN → gAXVN theo index
    function toGAXVN(uint256 sAXVNAmount_) external view returns (uint256) {
        return (sAXVNAmount_ * 1e18) / index;
    }

    /// @notice Quy đổi gAXVN → sAXVN theo index
    function toSAXVN(uint256 gAXVNAmount_) external view returns (uint256) {
        return (gAXVNAmount_ * index) / 1e18;
    }
}
