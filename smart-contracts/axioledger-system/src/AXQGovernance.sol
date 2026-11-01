// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER ($AXQ) - DAO Governance Core
//
// Tri-partite governance model:
//   Legislative:  Quadratic Voting (votes = sqrt(tokens), snapshot-based)
//   Judicial:     Guardian Council (5 seats, 4/5 veto - Objection Window only)
//   Executive:    Time-Lock (7 days) + Emergency Escape Hatch
//
// Changelog v0.2.0:
//   Fix 1 (Critical) - Flash Loan resistance:
//     castVote() now uses IVotes.getPastVotes() at the proposal's snapshotBlock
//     (the block before propose() was called) instead of live balanceOf().
//     Borrowing tokens in the same block as the snapshot is impossible because
//     getPastVotes() only returns checkpoints from strictly prior blocks.
//
//   Fix 2 (High) - Time-lock enforcement:
//     Added `bool queued` to Proposal struct.  queue() sets it; execute()
//     now requires it.  A proposal cannot be executed without having been
//     explicitly queued first, guaranteeing the 7-day delay is observed.
//
//   Fix 3 (Medium) - Veto Objection Window:
//     vetoVote() is now restricted to the Objection Window:
//       block.timestamp in (voteEnd, executionTime)
//     Guardians cannot veto during active voting (separation of powers)
//     nor after the time-lock has fully elapsed (too late to block).
//
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AXQGovernance - AXIOLEDGER DAO Governance Core (v0.2.0)
/// @notice Quadratic voting (snapshot) + Guardian Council veto (Objection Window) + 7-day time-lock.
contract AXQGovernance is ReentrancyGuard {

    // -- Types ----------------------------------------------------------------

    enum ProposalState { Pending, Active, Vetoed, Queued, Executed, Cancelled, Defeated }

    struct Proposal {
        uint256 id;
        address proposer;
        string  description;
        bytes   callData;
        address target;
        uint256 value;
        uint64  voteStart;
        uint64  voteEnd;
        uint64  executionTime;   // voteEnd + TIME_LOCK_PERIOD
        uint256 snapshotBlock;   // [Fix 1] block at which voting power is read
        uint256 votesFor;        // quadratic-weighted
        uint256 votesAgainst;
        bool    executed;
        bool    vetoed;
        bool    queued;          // [Fix 2] set by queue(), required by execute()
    }

    // -- Constants ------------------------------------------------------------

    uint64  public constant VOTING_PERIOD      = 3 days;
    uint64  public constant TIME_LOCK_PERIOD   = 7 days;
    uint256 public constant PROPOSAL_THRESHOLD = 100_000e18;  // 100k $AXQ to propose
    // Quorum: 100k quadratic-weighted votes.
    // Requires sqrt(balance / 1e18) >= 100_000, i.e. holder with >= 10B AXQ
    // (achievable: rdTreasury holds 150B AXQ at genesis).
    uint256 public constant QUORUM_VOTES       = 100_000;
    uint8   public constant GUARDIAN_SEATS     = 5;
    uint8   public constant VETO_THRESHOLD     = 4;           // 4-of-5 guardians

    // -- State ----------------------------------------------------------------

    ERC20Votes public immutable AXQ_TOKEN;   // [Fix 1] typed as ERC20Votes (not IERC20)
    address    public treasury;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Guardian Council
    address[GUARDIAN_SEATS] public guardians;
    mapping(uint256 => mapping(address => bool)) public guardianVetoed;
    mapping(uint256 => uint8) public vetoCount;

    // -- Events ---------------------------------------------------------------

    event ProposalCreated(uint256 indexed id, address proposer, string description, uint256 snapshotBlock);
    event VoteCast(uint256 indexed id, address voter, bool support, uint256 weight);
    event ProposalVetoed(uint256 indexed id, address guardian, uint8 vetoCount);
    event ProposalQueued(uint256 indexed id, uint64 executionTime);
    event ProposalExecuted(uint256 indexed id);
    event ProposalCancelled(uint256 indexed id);

    // -- Errors ---------------------------------------------------------------

    error GOV_BelowThreshold();
    error GOV_NotActive();
    error GOV_AlreadyVoted();
    error GOV_NotQueued();
    error GOV_TimeLockNotExpired();
    error GOV_NotGuardian();
    error GOV_AlreadyVetoed();
    error GOV_ExecutionFailed();
    error GOV_ZeroAddress();
    error GOV_NotObjectionWindow(); // [Fix 3]

    // -- Constructor ----------------------------------------------------------

    constructor(
        address _axqToken,
        address _treasury,
        address[GUARDIAN_SEATS] memory _guardians
    ) {
        if (_axqToken  == address(0)) revert GOV_ZeroAddress();
        if (_treasury  == address(0)) revert GOV_ZeroAddress();

        AXQ_TOKEN = ERC20Votes(_axqToken);
        treasury  = _treasury;
        guardians = _guardians;
    }

    // -- Proposal lifecycle ---------------------------------------------------

    /// @notice Create a new governance proposal.
    /// @dev    [Fix 1] Records block.number - 1 as the voting-power snapshot.
    ///         No one can flash-loan tokens and vote in the same block because
    ///         getPastVotes() only reflects checkpoints from strictly past blocks.
    function propose(
        address target,
        uint256 value,
        bytes calldata callData,
        string calldata description
    ) external returns (uint256) {
        // [Fix 1] check proposer's past votes at the previous block
        uint256 snapshot = block.number - 1;
        uint256 proposerVotes = AXQ_TOKEN.getPastVotes(msg.sender, snapshot);
        if (proposerVotes < PROPOSAL_THRESHOLD) revert GOV_BelowThreshold();

        unchecked { proposalCount++; }
        uint256 id = proposalCount;

        proposals[id] = Proposal({
            id:            id,
            proposer:      msg.sender,
            description:   description,
            callData:      callData,
            target:        target,
            value:         value,
            voteStart:     uint64(block.timestamp),
            voteEnd:       uint64(block.timestamp) + VOTING_PERIOD,
            executionTime: uint64(block.timestamp) + VOTING_PERIOD + TIME_LOCK_PERIOD,
            snapshotBlock: snapshot,             // [Fix 1]
            votesFor:      0,
            votesAgainst:  0,
            executed:      false,
            vetoed:        false,
            queued:        false                 // [Fix 2]
        });

        emit ProposalCreated(id, msg.sender, description, snapshot);
        return id;
    }

    /// @notice Cast a quadratic-weighted vote.
    /// @dev    [Fix 1] Uses getPastVotes() at the proposal's snapshotBlock.
    ///         Flash loans cannot influence this because they resolve within
    ///         the same block and the snapshot is from a prior block.
    /// @param id      Proposal ID
    /// @param support true = for, false = against
    function castVote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        if (block.timestamp < p.voteStart || block.timestamp > p.voteEnd || p.vetoed)
            revert GOV_NotActive();
        if (hasVoted[id][msg.sender]) revert GOV_AlreadyVoted();

        hasVoted[id][msg.sender] = true;

        // [Fix 1] snapshot-based voting power - immune to flash loans
        uint256 pastVotes = AXQ_TOKEN.getPastVotes(msg.sender, p.snapshotBlock);
        // Quadratic weight: votes = sqrt(balance / 1e18) - integer sqrt
        uint256 weight    = _sqrt(pastVotes / 1e18);

        if (support) {
            p.votesFor     += weight;
        } else {
            p.votesAgainst += weight;
        }

        emit VoteCast(id, msg.sender, support, weight);
    }

    /// @notice Queue a passed proposal for time-locked execution.
    /// @dev    [Fix 2] Sets p.queued = true; execute() requires this flag.
    function queue(uint256 id) external {
        Proposal storage p = proposals[id];
        if (block.timestamp <= p.voteEnd)   revert GOV_NotActive();
        if (p.vetoed || p.executed)         revert GOV_NotQueued();
        if (p.votesFor <= p.votesAgainst)   revert GOV_NotQueued();
        if (p.votesFor < QUORUM_VOTES)      revert GOV_NotQueued();

        p.queued = true; // [Fix 2]

        emit ProposalQueued(id, p.executionTime);
    }

    /// @notice Execute a queued proposal after time-lock expires.
    /// @dev    [Fix 2] Requires p.queued == true - queue() must have been called.
    ///         This guarantees the 7-day TIME_LOCK_PERIOD is never bypassed.
    function execute(uint256 id) external payable nonReentrant {
        Proposal storage p = proposals[id];
        if (!p.queued)                          revert GOV_NotQueued();       // [Fix 2]
        if (block.timestamp < p.executionTime)  revert GOV_TimeLockNotExpired();
        if (p.executed || p.vetoed)             revert GOV_NotQueued();
        if (p.votesFor <= p.votesAgainst)       revert GOV_NotQueued();

        p.executed = true;

        (bool ok, ) = p.target.call{ value: p.value }(p.callData);
        if (!ok) revert GOV_ExecutionFailed();

        emit ProposalExecuted(id);
    }

    // -- Guardian Council -----------------------------------------------------

    /// @notice Guardian casts veto vote. 4-of-5 required to block proposal.
    /// @dev    [Fix 3] Restricted to the Objection Window:
    ///           after voteEnd (voting is closed) AND before executionTime
    ///           (time-lock has not elapsed yet).
    ///         This enforces separation of powers: Guardians cannot interfere
    ///         with active voting, and cannot revoke an already-executable proposal.
    function vetoVote(uint256 id) external {
        bool isGuardian = false;
        for (uint8 i = 0; i < GUARDIAN_SEATS; ) {
            if (guardians[i] == msg.sender) { isGuardian = true; break; }
            unchecked { i++; }
        }
        if (!isGuardian)                    revert GOV_NotGuardian();
        if (guardianVetoed[id][msg.sender]) revert GOV_AlreadyVetoed();

        Proposal storage p = proposals[id];

        // [Fix 3] Objection Window: strictly after voting ends, before time-lock elapses
        if (block.timestamp <= p.voteEnd || block.timestamp >= p.executionTime)
            revert GOV_NotObjectionWindow();

        guardianVetoed[id][msg.sender] = true;
        vetoCount[id]++;

        emit ProposalVetoed(id, msg.sender, vetoCount[id]);

        if (vetoCount[id] >= VETO_THRESHOLD) {
            p.vetoed = true;
        }
    }

    // -- View helpers ---------------------------------------------------------

    /// @notice Returns the key numeric/bool fields for a proposal.
    ///         Avoids ABI limitations with string/bytes in auto-generated getters.
    function proposalStatus(uint256 id) external view returns (
        uint256 votesFor,
        uint256 votesAgainst,
        uint64  voteEnd,
        uint64  executionTime,
        uint256 snapshotBlock,
        bool    executed,
        bool    vetoed,
        bool    queued
    ) {
        Proposal storage p = proposals[id];
        return (
            p.votesFor,
            p.votesAgainst,
            p.voteEnd,
            p.executionTime,
            p.snapshotBlock,
            p.executed,
            p.vetoed,
            p.queued
        );
    }

    // -- Emergency Escape Hatch -----------------------------------------------

    /// @notice Emergency withdrawal - requires 4-of-5 guardians to have signed off on proposal.
    /// @dev In production this would be a separate multi-sig - stub for now.
    function emergencyWithdraw(address token, address to, uint256 amount) external {
        // Requires all guardian vetoes to be used on a special ESCAPE_HATCH proposal
        // Implementation: Phase 3 DAO contracts
        revert("not implemented - Phase 3");
    }

    // -- Internal -------------------------------------------------------------

    /// @dev Integer square root (Babylonian method).
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
