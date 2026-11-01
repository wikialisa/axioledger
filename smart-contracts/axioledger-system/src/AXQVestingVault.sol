// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER ($AXQ) - Linear Vesting Vault
//
// 4-year linear vesting with 1-year cliff.
// Designed for Core Team allocation (12% = 60B $AXQ).
//
// Timeline per beneficiary:
//   Month  0-12 : cliff - nothing claimable
//   Month 12-48 : linear unlock - 1/36 of remainder per month
//   Month  48+  : fully vested
//
// Features:
//   - Multiple independent beneficiaries
//   - DAO can add/revoke grants (unvested portion returns to treasury)
//   - Emergency pause (Guardian Council)
//   - Non-transferable (no secondary market for unvested tokens)
//
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AXQVestingVault - 4-year linear vesting with 1-year cliff
/// @notice Distributes Core Team $AXQ allocation over 48 months.
contract AXQVestingVault is Ownable2Step, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // -- Constants ------------------------------------------------------------

    uint64 public constant CLIFF_DURATION   = 365 days;       // 1 year
    uint64 public constant VESTING_DURATION = 3 * 365 days;   // 3 years post-cliff (total 4yr)

    // -- Types ----------------------------------------------------------------

    struct Grant {
        uint256 totalAmount;    // total tokens granted
        uint256 claimed;        // tokens already claimed
        uint64  startTime;      // vesting start (cliff begins here)
        bool    revoked;        // revoked by DAO
    }

    // -- State ----------------------------------------------------------------

    IERC20  public immutable AXQ_TOKEN;
    address public           treasury;    // revoked tokens return here

    mapping(address => Grant) public grants;
    address[] public          beneficiaries;

    uint256 public totalAllocated;  // sum of all active grant amounts

    // -- Events ---------------------------------------------------------------

    event GrantAdded(address indexed beneficiary, uint256 amount, uint64 startTime);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event GrantRevoked(address indexed beneficiary, uint256 unvestedReturned);
    event TreasuryUpdated(address newTreasury);

    // -- Errors ---------------------------------------------------------------

    error VEST_GrantExists();
    error VEST_NoGrant();
    error VEST_AlreadyRevoked();
    error VEST_NothingToClaim();
    error VEST_CliffNotReached();
    error VEST_ZeroAmount();
    error VEST_ZeroAddress();
    error VEST_InsufficientBalance();

    // -- Constructor ----------------------------------------------------------

    /// @param _axqToken  Deployed AXQ token address
    /// @param _treasury  Address to receive revoked unvested tokens
    /// @param _dao       DAO multisig - owns this contract
    constructor(address _axqToken, address _treasury, address _dao)
        Ownable(_dao)
    {
        if (_axqToken  == address(0)) revert VEST_ZeroAddress();
        if (_treasury  == address(0)) revert VEST_ZeroAddress();
        AXQ_TOKEN = IERC20(_axqToken);
        treasury  = _treasury;
    }

    // -- DAO: Grant Management ------------------------------------------------

    /// @notice Add a new vesting grant. DAO must have approved this contract to
    ///         transfer `amount` tokens beforehand, OR hold a sufficient balance.
    /// @param beneficiary  Recipient of the vested tokens
    /// @param amount       Total tokens to vest
    /// @param startTime    Vesting start timestamp (0 = now)
    function addGrant(address beneficiary, uint256 amount, uint64 startTime)
        external
        onlyOwner
    {
        if (beneficiary == address(0))         revert VEST_ZeroAddress();
        if (amount == 0)                        revert VEST_ZeroAmount();
        if (grants[beneficiary].totalAmount > 0 && !grants[beneficiary].revoked)
                                                revert VEST_GrantExists();

        uint64 start = startTime == 0 ? uint64(block.timestamp) : startTime;

        // Pull tokens into vault (DAO transfers from treasury allocation)
        uint256 balBefore = AXQ_TOKEN.balanceOf(address(this));
        AXQ_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = AXQ_TOKEN.balanceOf(address(this)) - balBefore;
        if (received < amount) revert VEST_InsufficientBalance();

        grants[beneficiary] = Grant({
            totalAmount: amount,
            claimed:     0,
            startTime:   start,
            revoked:     false
        });
        beneficiaries.push(beneficiary);
        totalAllocated += amount;

        emit GrantAdded(beneficiary, amount, start);
    }

    /// @notice Revoke a grant. Unvested tokens return to treasury; vested tokens
    ///         remain claimable by the beneficiary.
    function revokeGrant(address beneficiary) external onlyOwner {
        Grant storage g = grants[beneficiary];
        if (g.totalAmount == 0)  revert VEST_NoGrant();
        if (g.revoked)           revert VEST_AlreadyRevoked();

        uint256 vestedAmt    = _vestedAmount(g);
        uint256 unvested     = g.totalAmount - vestedAmt;

        g.revoked = true;
        totalAllocated -= unvested;

        // Send unvested portion back to treasury
        if (unvested > 0) {
            AXQ_TOKEN.safeTransfer(treasury, unvested);
        }

        emit GrantRevoked(beneficiary, unvested);
    }

    // -- Beneficiary: Claim ---------------------------------------------------

    /// @notice Claim all currently vested (and unclaimed) tokens.
    function claim() external nonReentrant whenNotPaused {
        Grant storage g = grants[msg.sender];
        if (g.totalAmount == 0) revert VEST_NoGrant();

        uint256 vestedAmt    = _vestedAmount(g);
        uint256 claimableAmt = vestedAmt - g.claimed;
        if (claimableAmt == 0) {
            if (block.timestamp < g.startTime + CLIFF_DURATION) revert VEST_CliffNotReached();
            revert VEST_NothingToClaim();
        }

        g.claimed += claimableAmt;
        AXQ_TOKEN.safeTransfer(msg.sender, claimableAmt);

        emit TokensClaimed(msg.sender, claimableAmt);
    }

    // -- View helpers ---------------------------------------------------------

    /// @notice How many tokens are currently claimable by `beneficiary`.
    function claimable(address beneficiary) external view returns (uint256) {
        Grant storage g = grants[beneficiary];
        if (g.totalAmount == 0 || g.revoked) return 0;
        uint256 vestedAmt = _vestedAmount(g);
        return vestedAmt > g.claimed ? vestedAmt - g.claimed : 0;
    }

    /// @notice Total vested amount (claimed + claimable) for `beneficiary`.
    function vested(address beneficiary) external view returns (uint256) {
        Grant storage g = grants[beneficiary];
        if (g.totalAmount == 0) return 0;
        return _vestedAmount(g);
    }

    /// @notice Seconds remaining until cliff for `beneficiary`.
    function cliffRemaining(address beneficiary) external view returns (uint256) {
        uint64 cliffEnd = grants[beneficiary].startTime + CLIFF_DURATION;
        if (block.timestamp >= cliffEnd) return 0;
        return cliffEnd - block.timestamp;
    }

    /// @notice Total number of beneficiaries ever added.
    function beneficiaryCount() external view returns (uint256) {
        return beneficiaries.length;
    }

    // -- DAO: Emergency controls ----------------------------------------------

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert VEST_ZeroAddress();
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    // -- Internal -------------------------------------------------------------

    /// @dev Linear vesting after cliff. Returns total tokens earned to date.
    function _vestedAmount(Grant storage g) internal view returns (uint256) {
        uint64 now_    = uint64(block.timestamp);
        uint64 cliff   = g.startTime + CLIFF_DURATION;
        uint64 endTime = g.startTime + CLIFF_DURATION + VESTING_DURATION;

        if (now_ < cliff)    return 0;              // before cliff
        if (now_ >= endTime) return g.totalAmount;  // fully vested

        // Linear: proportion of VESTING_DURATION elapsed since cliff
        uint256 elapsed = now_ - cliff;
        return (g.totalAmount * elapsed) / VESTING_DURATION;
    }
}
