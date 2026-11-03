// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../kernel/Module.sol";
import "../modules/mintr-module.v1.sol";
import "../tokens/sAXVN-token.sol";
import "../tokens/gAXVN-token.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ─── staking-policy.sol — StakingPolicy ──────────────────────────────────────
// Xử lý khóa AXVN → nhận sAXVN/gAXVN và phân phối thưởng Rebase mỗi Epoch.
// ─────────────────────────────────────────────────────────────────────────────

using SafeERC20 for IERC20;

error Staking_InvalidAmount();
error Staking_NotEnoughStaked(address user, uint256 staked, uint256 requested);
error Staking_EpochNotReady(uint256 nextEpochTime);

contract StakingPolicy is Policy {
    // ─── Modules ──────────────────────────────────────────────────────────

    MINTRv1    public MINTR;
    SAXVNToken public sAXVN;
    GAXVNToken public gAXVN;
    IERC20     public AXVN;

    // ─── Rebase params ────────────────────────────────────────────────────

    uint256 public rebaseBps    = 100;  // 1% per epoch default
    uint256 public nextEpochTime;

    // ─── User positions ───────────────────────────────────────────────────

    mapping(address => uint256) public stakedAXVN;

    // ─── Events ───────────────────────────────────────────────────────────

    event Staked(address indexed user, uint256 AXVNIn, uint256 sAXVNOut);
    event Unstaked(address indexed user, uint256 sAXVNIn, uint256 AXVNOut);
    event Rebased(uint256 epoch, uint256 rebaseBps, uint256 newSupply);
    event RebaseBpsUpdated(uint256 prev, uint256 next);

    // ─── Constructor ──────────────────────────────────────────────────────

    constructor(
        Kernel kernel_,
        address AXVN_,
        address sAXVN_,
        address gAXVN_
    ) Policy(kernel_) {
        AXVN  = IERC20(AXVN_);
        sAXVN = SAXVNToken(sAXVN_);
        gAXVN = GAXVNToken(gAXVN_);
        nextEpochTime = block.timestamp + 8 hours;
    }

    // ─── Policy interface ─────────────────────────────────────────────────

    function configureDependencies()
        external
        override
        returns (bytes5[] memory deps)
    {
        deps    = new bytes5[](1);
        deps[0] = "MINTR";
        MINTR   = MINTRv1(getModuleAddress("MINTR"));
    }

    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory reqs)
    {
        reqs    = new Permissions[](2);
        reqs[0] = Permissions({ keycode: "MINTR", funcSelector: MINTRv1.mintAXVN.selector });
        reqs[1] = Permissions({ keycode: "MINTR", funcSelector: MINTRv1.burnAXVN.selector });
    }

    // ─── Core logic ───────────────────────────────────────────────────────

    /// @notice Stake AXVN → receive sAXVN 1:1
    function stake(uint256 amount_) external {
        if (amount_ == 0) revert Staking_InvalidAmount();
        AXVN.safeTransferFrom(msg.sender, address(this), amount_);
        stakedAXVN[msg.sender] += amount_;
        sAXVN.mint(msg.sender, amount_);
        emit Staked(msg.sender, amount_, amount_);
    }

    /// @notice Unstake sAXVN → receive AXVN
    function unstake(uint256 sAXVNAmount_) external {
        if (sAXVNAmount_ == 0) revert Staking_InvalidAmount();
        uint256 AXVNOut = sAXVNAmount_; // 1:1 pre-rebase (post-rebase gains embedded in sAXVN balance)
        if (stakedAXVN[msg.sender] < AXVNOut)
            revert Staking_NotEnoughStaked(msg.sender, stakedAXVN[msg.sender], AXVNOut);
        sAXVN.burn(msg.sender, sAXVNAmount_);
        stakedAXVN[msg.sender] -= AXVNOut;
        AXVN.safeTransfer(msg.sender, AXVNOut);
        emit Unstaked(msg.sender, sAXVNAmount_, AXVNOut);
    }

    /// @notice Wrap sAXVN → gAXVN (1:1 by index value)
    function wrap(uint256 amount_) external {
        if (amount_ == 0) revert Staking_InvalidAmount();
        sAXVN.burn(msg.sender, amount_);
        gAXVN.mint(msg.sender, amount_);
    }

    /// @notice Unwrap gAXVN → sAXVN (1:1)
    function unwrap(uint256 amount_) external {
        if (amount_ == 0) revert Staking_InvalidAmount();
        gAXVN.burn(msg.sender, amount_);
        sAXVN.mint(msg.sender, amount_);
    }

    /// @notice Trigger epoch rebase — distributes yield to all sAXVN holders
    function triggerRebase() external {
        if (block.timestamp < nextEpochTime)
            revert Staking_EpochNotReady(nextEpochTime);
        uint256 newSupply = sAXVN.rebase(rebaseBps);
        nextEpochTime = block.timestamp + 8 hours;
        emit Rebased(sAXVN.epoch(), rebaseBps, newSupply);
    }

    /// @notice Update rebase rate (guarded — only Kernel executor via role)
    function setRebaseBps(uint256 bps_) external {
        require(
            kernel.isPolicyActive(address(this)),
            "Staking: not active"
        );
        emit RebaseBpsUpdated(rebaseBps, bps_);
        rebaseBps = bps_;
    }
}
