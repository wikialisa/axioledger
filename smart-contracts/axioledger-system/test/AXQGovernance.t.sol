// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/AXQToken.sol";
import "../src/AXQGovernance.sol";

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// @dev A minimal contract that accepts ETH and can be used as a call target.
contract MockTarget {
    uint256 public callCount;
    function increment() external payable { callCount++; }
}

/// @dev Helper that sets up a standard proposal, passes votes, and queues it.
///      Returns (proposalId).
contract GovernanceTestBase is Test {

    AXQToken      internal token;
    AXQGovernance internal gov;
    MockTarget    internal target;

    address internal dao       = makeAddr("dao");
    address internal treasury  = makeAddr("treasury");
    address internal voter1    = makeAddr("voter1");
    address internal voter2    = makeAddr("voter2");
    address internal attacker  = makeAddr("attacker");

    address[5] internal guardians;

    function setUp() public virtual {
        address g0 = makeAddr("g0");
        address g1 = makeAddr("g1");
        address g2 = makeAddr("g2");
        address g3 = makeAddr("g3");
        address g4 = makeAddr("g4");
        guardians  = [g0, g1, g2, g3, g4];

        // Deploy token — dao is owner
        token = new AXQToken(
            treasury, treasury, treasury, treasury, treasury, treasury, dao
        );

        // Allocate supply
        vm.prank(dao);
        token.genesisAllocate();

        // Deploy governance
        gov = new AXQGovernance(address(token), treasury, guardians);

        target = new MockTarget();

        // Give voter1 tokens and delegate to self so checkpoints are recorded.
        // voter1 needs sqrt(balance/1e18) >= QUORUM_VOTES (100_000):
        //   balance/1e18 >= 100_000^2 = 10_000_000_000 (10B tokens) — within 500B supply.
        vm.startPrank(treasury);
        token.transfer(voter1, 10_000_000_000e18);  // 10B AXQ → √10B = 100_000 votes (= quorum)
        token.transfer(voter2,  1_000_000_000e18);  //  1B AXQ
        vm.stopPrank();

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        // attacker gets nothing at this point
    }

    /// @dev Mine one block so getPastVotes can see the delegation checkpoints.
    function _mineBlock() internal {
        vm.roll(block.number + 1);
    }

    /// @dev Build a standard passing proposal (after mineBlock).
    function _createProposal() internal returns (uint256 id) {
        _mineBlock();
        vm.prank(voter1);
        id = gov.propose(
            address(target),
            0,
            abi.encodeWithSelector(MockTarget.increment.selector),
            "Test proposal"
        );
    }

    /// @dev Cast a FOR vote from voter1 (who has enough quadratic votes).
    function _passProposal(uint256 id) internal {
        vm.prank(voter1);
        gov.castVote(id, true);
    }

    /// @dev Warp past voteEnd and queue.
    function _queueProposal(uint256 id) internal {
        vm.warp(block.timestamp + 3 days + 1);
        gov.queue(id);
    }

    /// @dev Warp to executionTime and execute.
    function _executeProposal(uint256 id) internal {
        vm.warp(block.timestamp + 7 days + 1);
        gov.execute(id);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AXQToken Tests
// ═══════════════════════════════════════════════════════════════════════════════

contract AXQTokenTest is GovernanceTestBase {

    // ── Genesis allocation ────────────────────────────────────────────────────

    function test_genesisAllocate_totalSupply() public view {
        assertEq(token.totalSupply(), 500_000_000_000e18);
    }

    function test_genesisAllocate_cannotCallTwice() public {
        vm.prank(dao);
        vm.expectRevert(AXQToken.AXQ_AlreadyMinted.selector);
        token.genesisAllocate();
    }

    function test_genesisAllocate_zeroAddressReverts() public {
        vm.expectRevert(AXQToken.AXQ_ZeroAddress.selector);
        new AXQToken(
            address(0), treasury, treasury, treasury, treasury, treasury, dao
        );
    }

    // ── ERC20Votes — Fix 1 ────────────────────────────────────────────────────

    function test_votes_delegateAndCheckpoint() public view {
        // voter1 delegated to themselves in setUp — checkpoint must exist
        uint256 votes = token.getVotes(voter1);
        assertGt(votes, 0, "voter1 should have votes after delegation");
    }

    function test_votes_getPastVotes_requiresPastBlock() public {
        _mineBlock();
        uint256 snapshot = block.number - 1;
        uint256 past = token.getPastVotes(voter1, snapshot);
        assertGt(past, 0, "getPastVotes should return non-zero for past block");
    }

    function test_votes_noCheckpointWithoutDelegate() public {
        // attacker never called delegate — no checkpoint
        uint256 votes = token.getVotes(attacker);
        assertEq(votes, 0);
    }

    function test_votes_burnReducesCheckpoint() public {
        uint256 before = token.getVotes(voter1);
        vm.prank(voter1);
        token.burn(1_000e18);
        assertEq(token.getVotes(voter1), before - 1_000e18);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AXQGovernance — Fix 1: Flash Loan resistance
// ═══════════════════════════════════════════════════════════════════════════════

contract GovernanceFlashLoanTest is GovernanceTestBase {

    /// @dev Simulates the flash loan attack:
    ///      Attacker borrows tokens IN THE SAME BLOCK as the proposal snapshot,
    ///      then tries to vote. Because getPastVotes() reads block.number-1 and
    ///      the attacker never held tokens in any prior block, weight == 0.
    function test_flashLoan_sameBlockTokensGiveZeroVotes() public {
        // Mine to block N so propose() uses snapshot = N-1
        _mineBlock(); // block N

        // Attacker "borrows" tokens at block N (same block as snapshot)
        vm.startPrank(treasury);
        token.transfer(attacker, 100_000_000e18); // huge bag
        vm.stopPrank();
        vm.prank(attacker);
        token.delegate(attacker);

        // Create proposal — snapshot = block.number - 1 = N-1
        // Attacker had ZERO tokens at block N-1
        vm.prank(voter1);
        uint256 id = gov.propose(
            address(target), 0,
            abi.encodeWithSelector(MockTarget.increment.selector),
            "Flash loan test"
        );

        // Attacker attempts to vote — their snapshot votes = 0
        vm.prank(attacker);
        gov.castVote(id, true);

        assertEq(_votesFor(id), 0, "Flash loan attack: attacker votes must be zero");
    }

    /// @dev Tokens received BEFORE the snapshot block DO count.
    function test_flashLoan_priorBlockTokensCountNormally() public {
        // Give attacker tokens and mine a block so checkpoint is in the past
        vm.prank(treasury);
        token.transfer(attacker, 1_000_000e18);
        vm.prank(attacker);
        token.delegate(attacker);

        _mineBlock(); // checkpoint is now in a past block

        // Create proposal — snapshot = current block - 1 (attacker has past votes)
        vm.prank(voter1);
        uint256 id = gov.propose(
            address(target), 0,
            abi.encodeWithSelector(MockTarget.increment.selector),
            "Prior block test"
        );

        vm.prank(attacker);
        gov.castVote(id, true);

        assertGt(_votesFor(id), 0, "Prior-block tokens should produce positive vote weight");
    }

    /// @dev Read votesFor via proposalStatus() helper.
    function _votesFor(uint256 id) internal view returns (uint256 vf) {
        (vf, , , , , , , ) = gov.proposalStatus(id);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AXQGovernance — Fix 2: Time-lock enforcement via queued flag
// ═══════════════════════════════════════════════════════════════════════════════

contract GovernanceTimeLockTest is GovernanceTestBase {

    /// @dev execute() without queue() must revert with GOV_NotQueued.
    function test_execute_withoutQueue_reverts() public {
        uint256 id = _createProposal();
        _passProposal(id);

        // Warp past both voteEnd and executionTime — skip queue()
        vm.warp(block.timestamp + 10 days + 1);

        vm.expectRevert(AXQGovernance.GOV_NotQueued.selector);
        gov.execute(id);
    }

    /// @dev execute() before time-lock expires must revert.
    function test_execute_beforeTimeLock_reverts() public {
        uint256 id = _createProposal();
        _passProposal(id);
        _queueProposal(id);

        // Still inside the 7-day window
        vm.expectRevert(AXQGovernance.GOV_TimeLockNotExpired.selector);
        gov.execute(id);
    }

    /// @dev Full happy path: propose → vote → queue → warp → execute.
    function test_execute_happyPath() public {
        uint256 id = _createProposal();
        _passProposal(id);
        _queueProposal(id);
        _executeProposal(id);

        ( , , , , , bool executed, , ) = gov.proposalStatus(id);
        assertTrue(executed, "Proposal must be marked executed");
        assertEq(target.callCount(), 1, "Target must have been called once");
    }

    /// @dev Cannot execute twice.
    function test_execute_cannotExecuteTwice() public {
        uint256 id = _createProposal();
        _passProposal(id);
        _queueProposal(id);
        _executeProposal(id);

        vm.expectRevert(AXQGovernance.GOV_NotQueued.selector);
        gov.execute(id);
    }

    /// @dev queue() sets the queued flag.
    function test_queue_setsFlag() public {
        uint256 id = _createProposal();
        _passProposal(id);

        ( , , , , , , , bool queuedBefore) = gov.proposalStatus(id);
        assertFalse(queuedBefore);
        _queueProposal(id);
        ( , , , , , , , bool queuedAfter) = gov.proposalStatus(id);
        assertTrue(queuedAfter);
    }

    /// @dev queue() cannot be called before voteEnd.
    function test_queue_beforeVoteEnd_reverts() public {
        uint256 id = _createProposal();
        _passProposal(id);

        vm.expectRevert(AXQGovernance.GOV_NotActive.selector);
        gov.queue(id);
    }

    /// @dev Defeated proposal (insufficient votes) cannot be queued.
    function test_queue_insufficientVotes_reverts() public {
        uint256 id = _createProposal();
        // Do NOT vote — votesFor stays 0

        vm.warp(block.timestamp + 3 days + 1);
        vm.expectRevert(AXQGovernance.GOV_NotQueued.selector);
        gov.queue(id);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AXQGovernance — Fix 3: Veto Objection Window
// ═══════════════════════════════════════════════════════════════════════════════

contract GovernanceVetoWindowTest is GovernanceTestBase {

    /// @dev Veto during active voting must revert.
    function test_veto_duringVoting_reverts() public {
        uint256 id = _createProposal();
        // Still inside voting period

        vm.prank(guardians[0]);
        vm.expectRevert(AXQGovernance.GOV_NotObjectionWindow.selector);
        gov.vetoVote(id);
    }

    /// @dev Veto after time-lock has elapsed (proposal executable) must revert.
    function test_veto_afterTimeLock_reverts() public {
        uint256 id = _createProposal();
        _passProposal(id);
        _queueProposal(id);
        // Warp past executionTime
        vm.warp(block.timestamp + 7 days + 1);

        vm.prank(guardians[0]);
        vm.expectRevert(AXQGovernance.GOV_NotObjectionWindow.selector);
        gov.vetoVote(id);
    }

    /// @dev Veto inside the Objection Window (after voteEnd, before executionTime) succeeds.
    function test_veto_inObjectionWindow_succeeds() public {
        uint256 id = _createProposal();
        _passProposal(id);

        // Warp to middle of objection window: after voteEnd, before executionTime
        vm.warp(block.timestamp + 3 days + 1); // past voteEnd, still inside TIME_LOCK

        vm.prank(guardians[0]);
        gov.vetoVote(id);

        assertEq(gov.vetoCount(id), 1);
    }

    /// @dev 4-of-5 veto blocks the proposal.
    function test_veto_fourOfFiveBlocks() public {
        uint256 id = _createProposal();
        _passProposal(id);

        // Enter objection window
        vm.warp(block.timestamp + 3 days + 1);

        for (uint256 i = 0; i < 4; i++) {
            vm.prank(guardians[i]);
            gov.vetoVote(id);
        }

        ( , , , , , , bool vetoed4, ) = gov.proposalStatus(id);
        assertTrue(vetoed4, "Proposal must be vetoed after 4/5 guardians");
    }

    /// @dev 3 veto votes are not sufficient to block.
    function test_veto_threeOfFiveNotSufficient() public {
        uint256 id = _createProposal();
        _passProposal(id);

        vm.warp(block.timestamp + 3 days + 1);

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(guardians[i]);
            gov.vetoVote(id);
        }

        ( , , , , , , bool vetoed3, ) = gov.proposalStatus(id);
        assertFalse(vetoed3, "3/5 vetoes must not block proposal");
    }

    /// @dev Non-guardian cannot veto.
    function test_veto_nonGuardian_reverts() public {
        uint256 id = _createProposal();
        _passProposal(id);
        vm.warp(block.timestamp + 3 days + 1);

        vm.prank(attacker);
        vm.expectRevert(AXQGovernance.GOV_NotGuardian.selector);
        gov.vetoVote(id);
    }

    /// @dev Same guardian cannot veto twice.
    function test_veto_duplicateVeto_reverts() public {
        uint256 id = _createProposal();
        _passProposal(id);
        vm.warp(block.timestamp + 3 days + 1);

        vm.startPrank(guardians[0]);
        gov.vetoVote(id);
        vm.expectRevert(AXQGovernance.GOV_AlreadyVetoed.selector);
        gov.vetoVote(id);
        vm.stopPrank();
    }

    /// @dev Vetoed proposal cannot be executed.
    function test_veto_blocksExecution() public {
        uint256 id = _createProposal();
        _passProposal(id);

        // Enter objection window and veto
        vm.warp(block.timestamp + 3 days + 1);
        for (uint256 i = 0; i < 4; i++) {
            vm.prank(guardians[i]);
            gov.vetoVote(id);
        }

        // Queue fails on vetoed proposal
        vm.expectRevert(AXQGovernance.GOV_NotQueued.selector);
        gov.queue(id);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AXQGovernance — Additional edge cases
// ═══════════════════════════════════════════════════════════════════════════════

contract GovernanceEdgeCaseTest is GovernanceTestBase {

    /// @dev Proposer below threshold is rejected.
    function test_propose_belowThreshold_reverts() public {
        _mineBlock();
        // attacker has 0 tokens and 0 past votes
        vm.prank(attacker);
        vm.expectRevert(AXQGovernance.GOV_BelowThreshold.selector);
        gov.propose(address(target), 0, "", "Low-balance proposal");
    }

    /// @dev Voter cannot vote twice.
    function test_castVote_doubleVote_reverts() public {
        uint256 id = _createProposal();
        vm.prank(voter1);
        gov.castVote(id, true);

        vm.prank(voter1);
        vm.expectRevert(AXQGovernance.GOV_AlreadyVoted.selector);
        gov.castVote(id, true);
    }

    /// @dev Cannot vote after voteEnd.
    function test_castVote_afterDeadline_reverts() public {
        uint256 id = _createProposal();
        vm.warp(block.timestamp + 3 days + 1);

        vm.prank(voter1);
        vm.expectRevert(AXQGovernance.GOV_NotActive.selector);
        gov.castVote(id, true);
    }

    /// @dev Against votes correctly reduce net result.
    function test_castVote_againstReducesResult() public {
        // Give voter2 enough tokens to outweigh voter1 (who has 10B + 1B already)
        vm.prank(treasury);
        token.transfer(voter2, 20_000_000_000e18); // 20B extra → voter2 total > voter1
        vm.prank(voter2);
        token.delegate(voter2);
        _mineBlock();

        uint256 id = _createProposal();
        vm.prank(voter1); gov.castVote(id, true);
        vm.prank(voter2); gov.castVote(id, false);

        // voter2 has more tokens → more quadratic weight → votesAgainst > votesFor
        (uint256 vFor2, uint256 vAgainst2, , , , , , ) = gov.proposalStatus(id);
        assertTrue(
            vAgainst2 >= vFor2,
            "Larger holder against should dominate"
        );
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Fuzz Tests
// ═══════════════════════════════════════════════════════════════════════════════

contract GovernanceFuzzTest is GovernanceTestBase {

    /// @dev sqrt is monotonically non-decreasing and never overflows.
    ///      Tests the internal _sqrt by observing voting weight.
    function testFuzz_sqrt_voteWeightMonotonic(uint96 amount1, uint96 amount2) public {
        // Bound to reasonable ranges (both above zero, max ~79 billion tokens)
        vm.assume(amount1 > 1e18 && amount2 > 1e18);
        vm.assume(uint256(amount1) + uint256(amount2) < 79_000_000_000e18);

        address rich   = makeAddr("rich");
        address poor   = makeAddr("poor");
        address winner = amount1 >= amount2 ? rich : poor;

        vm.startPrank(treasury);
        token.transfer(rich, amount1);
        token.transfer(poor, amount2);
        vm.stopPrank();

        vm.prank(rich);  token.delegate(rich);
        vm.prank(poor);  token.delegate(poor);
        _mineBlock();

        vm.prank(voter1);
        uint256 id = gov.propose(address(target), 0,
            abi.encodeWithSelector(MockTarget.increment.selector), "fuzz");

        vm.prank(rich);  gov.castVote(id, true);
        vm.prank(poor);  gov.castVote(id, false);

        (uint256 vFor, uint256 vAgainst, , , , , , ) = gov.proposalStatus(id);

        if (amount1 > amount2) {
            assertGe(vFor, vAgainst, "Higher balance => higher quadratic votes");
        } else if (amount2 > amount1) {
            assertGe(vAgainst, vFor, "Higher balance => higher quadratic votes");
        }
    }

    /// @dev execute() always requires the queued flag regardless of time.
    function testFuzz_execute_alwaysRequiresQueuedFlag(uint64 timeWarp) public {
        // Warp to well past executionTime
        vm.assume(timeWarp > 10 days && timeWarp < 3650 days);

        uint256 id = _createProposal();
        _passProposal(id);
        // Intentionally skip queue()

        vm.warp(block.timestamp + timeWarp);

        vm.expectRevert(AXQGovernance.GOV_NotQueued.selector);
        gov.execute(id);
    }

    /// @dev Veto during active voting always reverts regardless of guardian index.
    function testFuzz_veto_duringVotingAlwaysReverts(uint8 guardianIdx) public {
        vm.assume(guardianIdx < 5);
        uint256 id = _createProposal();

        vm.prank(guardians[guardianIdx]);
        vm.expectRevert(AXQGovernance.GOV_NotObjectionWindow.selector);
        gov.vetoVote(id);
    }

    /// @dev Flash loan simulation: tokens received at snapshot block give 0 votes.
    function testFuzz_flashLoan_noVotingPowerInSameBlock(uint96 loanAmount) public {
        vm.assume(loanAmount > 1e18 && uint256(loanAmount) < 50_000_000_000e18);

        _mineBlock(); // block N — snapshot will be N-1

        // Attacker gets tokens at block N (same as snapshot block)
        vm.prank(treasury);
        token.transfer(attacker, loanAmount);
        vm.prank(attacker);
        token.delegate(attacker);

        vm.prank(voter1);
        uint256 id = gov.propose(address(target), 0,
            abi.encodeWithSelector(MockTarget.increment.selector), "fl fuzz");

        vm.prank(attacker);
        gov.castVote(id, true);

        (uint256 flVotesFor, , , , , , , ) = gov.proposalStatus(id);
        assertEq(flVotesFor, 0,
            "Snapshot-block tokens must never produce voting weight");
    }
}
