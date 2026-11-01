// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  KPXRouterGateway.t.sol — Foundry Test Suite                               ║
// ║  AXIOLEDGER — KINETOPROTOCOL ($KPX) Security Test                          ║
// ║                                                                              ║
// ║  Framework: Foundry (forge test)                                            ║
// ║  Run:       forge test --match-path test/KPXRouterGateway.t.sol -vvvv      ║
// ║  Fuzz:      forge test --fuzz-runs 10000 -vvvv                             ║
// ║                                                                              ║
// ║  Test categories:                                                            ║
// ║    T1. Deployment & Constructor                                              ║
// ║    T2. VRQ Security Pre-checks                                              ║
// ║    T3. *** REENTRANCY ATTACK TESTS *** (A1 Checklist)                      ║
// ║    T4. Bridge Security (B Checklist)                                        ║
// ║    T5. ZK-Proof Security                                                    ║
// ║    T6. Governance & Emergency                                               ║
// ║    T7. AMM Swap Security                                                    ║
// ║    T8. Fuzz Tests                                                           ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../KPXRouterGateway.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockVRQVerifier.sol";
import "./mocks/MockDarkPool.sol";
import "./mocks/ReentrancyAttacker.sol";

contract KPXRouterGatewayTest is Test {

    // ─── Contracts under test ────────────────────────────────────────────────
    KPXRouterGateway public router;
    MockVRQVerifier  public vrq;
    MockDarkPool     public darkPool;
    MockERC20        public tokenA;
    MockERC20        public tokenB;

    // ─── Test actors ─────────────────────────────────────────────────────────
    address public dao      = makeAddr("treasuryDAO");
    address public alice    = makeAddr("alice");       // User lương thiện
    address public bob      = makeAddr("bob");         // User lương thiện
    address public attacker = makeAddr("attacker");    // Kẻ tấn công EOA
    address public relayer1 = makeAddr("relayer1");
    address public relayer2 = makeAddr("relayer2");
    address public relayer3 = makeAddr("relayer3");

    // ─── Constants ───────────────────────────────────────────────────────────
    uint256 constant INITIAL_BALANCE  = 10_000_000 * 1e18;
    uint256 constant BRIDGE_AMOUNT    = 1_000 * 1e18;
    uint256 constant SWAP_AMOUNT      = 500 * 1e18;
    uint256 constant DARK_THRESHOLD   = 100_000 * 1e18;
    uint16  constant CHAIN_ETH        = 60;    // Ethereum
    uint16  constant CHAIN_ARB        = 42161; // Arbitrum
    uint16  constant CHAIN_SOL        = 501;   // Solana
    uint16  constant CHAIN_UNSUPPORTED = 9999;

    bytes   constant VALID_ZK_PROOF   = hex"deadbeef01020304";
    bytes32 constant KYC_COMMITMENT   = bytes32(uint256(0x12345678));
    uint256[] zbPubInputs;

    // ─── Setup ───────────────────────────────────────────────────────────────

    function setUp() public {
        // Deploy mocks
        vrq      = new MockVRQVerifier();
        darkPool = new MockDarkPool();
        tokenA   = new MockERC20("TokenA", "TKA");
        tokenB   = new MockERC20("TokenB", "TKB");

        // Setup supported chains
        uint16[] memory chains = new uint16[](3);
        chains[0] = CHAIN_ETH;
        chains[1] = CHAIN_ARB;
        chains[2] = CHAIN_SOL;

        // Setup relayers
        address[] memory relayers = new address[](3);
        relayers[0] = relayer1;
        relayers[1] = relayer2;
        relayers[2] = relayer3;

        // Deploy router với DAO = dao address
        vm.prank(dao);
        router = new KPXRouterGateway(
            address(vrq),
            address(darkPool),
            dao,
            relayers,
            chains,
            1 // circuit version
        );

        // Fund actors
        tokenA.mint(alice,    INITIAL_BALANCE);
        tokenA.mint(bob,      INITIAL_BALANCE);
        tokenA.mint(attacker, INITIAL_BALANCE);
        tokenB.mint(address(darkPool), INITIAL_BALANCE); // Dark pool có token để trả

        // Alice & Bob approve router
        vm.prank(alice);
        tokenA.approve(address(router), type(uint256).max);

        vm.prank(bob);
        tokenA.approve(address(router), type(uint256).max);

        // Default ZK proof inputs
        zbPubInputs = new uint256[](1);
        zbPubInputs[0] = 1;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T1. DEPLOYMENT & CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════

    function test_T1_deployment_correctState() public {
        assertEq(address(router.zkVerifier()),   address(vrq));
        assertEq(address(router.darkPool()),     address(darkPool));
        assertEq(router.treasuryDAO(),           dao);
        assertEq(router.relayerCount(),          3);
        assertFalse(router.paused());
        assertTrue(router.getSupportedChains(CHAIN_ETH));
        assertTrue(router.getSupportedChains(CHAIN_ARB));
        assertTrue(router.getSupportedChains(CHAIN_SOL));
        assertFalse(router.getSupportedChains(CHAIN_UNSUPPORTED));
        console.log("[PASS] T1.1 Deployment state correct");
    }

    function test_T1_deployment_revertOnZeroAddress() public {
        uint16[] memory chains = new uint16[](0);
        address[] memory relayers = new address[](0);

        vm.expectRevert(KPXRouterGateway.KPX_ZeroAddress.selector);
        new KPXRouterGateway(address(0), address(darkPool), dao, relayers, chains, 1);

        vm.expectRevert(KPXRouterGateway.KPX_ZeroAddress.selector);
        new KPXRouterGateway(address(vrq), address(0), dao, relayers, chains, 1);

        vm.expectRevert(KPXRouterGateway.KPX_ZeroAddress.selector);
        new KPXRouterGateway(address(vrq), address(darkPool), address(0), relayers, chains, 1);

        console.log("[PASS] T1.2 Zero address guard on constructor");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T2. VRQ SECURITY PRE-CHECKS
    // ═══════════════════════════════════════════════════════════════════════

    function test_T2_vrqFlaggedCallerBlockedOnBridge() public {
        // VRQ flags alice → bridge phải revert ngay lập tức
        vrq.setFlagged(alice, true);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.VRQ_AddressFlagged.selector, alice)
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T2.1 VRQ flagged caller blocked on bridgeOut");
    }

    function test_T2_vrqFlaggedTokenBlockedOnBridge() public {
        // VRQ flags tokenA contract → bridge phải revert
        vrq.setFlagged(address(tokenA), true);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.VRQ_AddressFlagged.selector, address(tokenA))
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T2.2 VRQ flagged token contract blocked on bridgeOut");
    }

    function test_T2_vrqFlaggedCallerBlockedOnSwap() public {
        vrq.setFlagged(alice, true);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.VRQ_AddressFlagged.selector, alice)
        );
        router.swapExactTokensForTokensWithPrivacy(
            SWAP_AMOUNT, SWAP_AMOUNT * 99 / 100,
            path, block.number + 100,
            VALID_ZK_PROOF, zbPubInputs
        );
        console.log("[PASS] T2.3 VRQ flagged caller blocked on swap");
    }

    function test_T2_vrqCheckIsFirstOperation() public {
        // Khi VRQ flag, không được xảy ra state change trước khi revert
        vrq.setFlagged(alice, true);
        uint256 balanceBefore = tokenA.balanceOf(alice);

        vm.prank(alice);
        vm.expectRevert();
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );

        // Không có token nào bị lấy đi
        assertEq(tokenA.balanceOf(alice), balanceBefore,
            "T2.4: Token balance changed before VRQ check — BUG!");
        console.log("[PASS] T2.4 VRQ check is first — no state change before revert");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T3. *** REENTRANCY ATTACK TESTS *** — CRITICAL
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice T3.1 — Reentrancy via bridgeOut → fallback → bridgeOut lại
    ///         Đây là kịch bản tấn công nguy hiểm nhất với bridge contracts
    function test_T3_reentrancy_bridgeOut_via_malicious_token() public {
        console.log("[TEST] T3.1 Reentrancy: bridgeOut via fallback");

        // Deploy attacker contract
        ReentrancyAttacker atkContract = new ReentrancyAttacker(
            address(router), address(tokenA)
        );

        // Fund attacker contract
        tokenA.mint(address(atkContract), INITIAL_BALANCE);

        // Approve token
        vm.prank(address(atkContract));
        tokenA.approve(address(router), type(uint256).max);

        // Encode reentrancy calldata — gọi lại bridgeOut
        bytes memory reentrantCall = abi.encodeWithSignature(
            "bridgeOut(address,uint256,uint16,bytes32,uint256,bytes,bytes32)",
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        atkContract.setAttackCalldata(reentrantCall);

        // Thực hiện tấn công — ReentrancyGuard PHẢI block reentrant call
        // Kỳ vọng: attackCount vẫn = 0 hoặc reentrant call revert
        vm.prank(address(atkContract));
        atkContract.attack(
            BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );

        // Kẻ tấn công chỉ bridge được 1 lần duy nhất (không reentered)
        // Nếu reenter thành công → double-spend → BUG NGHIÊM TRỌNG
        uint256 routerBalance = tokenA.balanceOf(address(router));
        assertEq(routerBalance, BRIDGE_AMOUNT,
            "T3.1 CRITICAL: Reentrancy succeeded! Router holds more than 1 bridge amount");
        console.log("[PASS] T3.1 ReentrancyGuard blocked bridgeOut reentrancy");
    }

    /// @notice T3.2 — Reentrancy via swap → Dark Pool callback → swap lại
    function test_T3_reentrancy_swap_via_darkpool() public {
        console.log("[TEST] T3.2 Reentrancy: swap via Dark Pool callback");

        // Set threshold thấp để route vào Dark Pool
        darkPool.setThreshold(SWAP_AMOUNT - 1);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Encode swap calldata để Dark Pool thử gọi lại
        bytes memory reentrantSwap = abi.encodeWithSignature(
            "swapExactTokensForTokensWithPrivacy(uint256,uint256,address[],uint256,bytes,uint256[])",
            SWAP_AMOUNT, 0, path, block.number + 100,
            VALID_ZK_PROOF, zbPubInputs
        );

        // Set Dark Pool để thử reenter
        darkPool.setShouldReenter(true, address(router), reentrantSwap);

        vm.prank(alice);
        // Không revert ở lớp swap — Dark Pool mock sẽ catch reentrancy
        // MockDarkPool.executeConfidentialSwap gọi router → bị block → mock emit fail event
        router.swapExactTokensForTokensWithPrivacy(
            SWAP_AMOUNT, 0, path,
            block.number + 100, VALID_ZK_PROOF, zbPubInputs
        );

        // Nếu reach đây → reentrancy đã bị block ở Mock (MockDarkPool.require(!success))
        console.log("[PASS] T3.2 ReentrancyGuard blocked swap reentrancy via Dark Pool");
    }

    /// @notice T3.3 — Reentrancy trực tiếp: bridgeIn → bridgeIn (double-spend)
    function test_T3_reentrancy_doubleSpend_bridgeIn() public {
        console.log("[TEST] T3.3 Reentrancy: Double-spend via bridgeIn");

        bytes32 bridgeId = keccak256("testBridgeId");

        // Fund router với tokens để bridge in
        tokenA.mint(address(router), BRIDGE_AMOUNT * 2);

        // First bridgeIn — phải thành công
        vm.prank(relayer1);
        router.bridgeIn(
            bridgeId, alice, address(tokenA), BRIDGE_AMOUNT,
            CHAIN_ETH, hex"00"
        );

        assertEq(tokenA.balanceOf(alice), INITIAL_BALANCE + BRIDGE_AMOUNT);

        // Second bridgeIn với cùng bridgeId — PHẢI REVERT (replay attack)
        vm.prank(relayer1);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.KPX_BridgeAlreadyFulfilled.selector, bridgeId
            )
        );
        router.bridgeIn(
            bridgeId, alice, address(tokenA), BRIDGE_AMOUNT,
            CHAIN_ETH, hex"00"
        );

        // Alice chỉ nhận được 1 lần, không 2 lần
        assertEq(tokenA.balanceOf(alice), INITIAL_BALANCE + BRIDGE_AMOUNT,
            "T3.3 CRITICAL: Double-spend succeeded!");
        console.log("[PASS] T3.3 Replay attack on bridgeIn blocked correctly");
    }

    /// @notice T3.4 — Proof replay attack: cùng ZK proof dùng 2 lần
    function test_T3_proofReplayAttack() public {
        console.log("[TEST] T3.4 ZK Proof replay attack");

        // First bridge với proof X
        vm.prank(alice);
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );

        // Second bridge với cùng proof X — PHẢI REVERT
        vm.prank(alice);
        bytes32 proofNonce = keccak256(VALID_ZK_PROOF);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.KPX_ProofAlreadyUsed.selector, proofNonce
            )
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT  // Same proof!
        );
        console.log("[PASS] T3.4 ZK proof replay attack blocked");
    }

    /// @notice T3.5 — Reentrancy guard state: nonReentrant lock đúng
    function test_T3_nonReentrantLockNotLeftLocked() public {
        console.log("[TEST] T3.5 nonReentrant lock released after normal call");

        // Call bridgeOut normally
        vm.prank(alice);
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );

        // After normal completion, lock phải được release
        // Gọi lần 2 với proof khác — phải succeed (không bị locked từ lần 1)
        bytes memory proof2 = hex"cafebabe";
        vm.prank(alice);
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            proof2, KYC_COMMITMENT
        );

        console.log("[PASS] T3.5 nonReentrant lock correctly released after normal execution");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T4. BRIDGE SECURITY
    // ═══════════════════════════════════════════════════════════════════════

    function test_T4_bridge_unsupportedChainReverts() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.KPX_UnsupportedChain.selector, CHAIN_UNSUPPORTED
            )
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_UNSUPPORTED,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T4.1 Unsupported chain reverts");
    }

    function test_T4_bridge_amountExceedsLimit() public {
        uint256 overLimit = router.maxBridgeAmountPerTx() + 1;
        tokenA.mint(alice, overLimit);
        vm.prank(alice);
        tokenA.approve(address(router), overLimit);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.KPX_BridgeAmountExceedsLimit.selector,
                overLimit, router.maxBridgeAmountPerTx()
            )
        );
        router.bridgeOut(
            address(tokenA), overLimit, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T4.2 Bridge drain protection — amount exceeds limit reverts");
    }

    function test_T4_bridge_deadlineExpired() public {
        vm.roll(1000); // Set current block to 1000

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.KPX_DeadlineExpired.selector, 999, 1000
            )
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), 999, // deadline < current block
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T4.3 Expired deadline reverts");
    }

    function test_T4_bridge_zeroAmountReverts() public {
        vm.prank(alice);
        vm.expectRevert(KPXRouterGateway.KPX_InvalidAmount.selector);
        router.bridgeOut(
            address(tokenA), 0, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T4.4 Zero amount reverts");
    }

    function test_T4_bridgeIn_onlyRelayerCanCall() public {
        bytes32 bridgeId = keccak256("bridge1");
        tokenA.mint(address(router), BRIDGE_AMOUNT);

        // Non-relayer (alice) cố gọi bridgeIn
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.KPX_NotRelayer.selector, alice)
        );
        router.bridgeIn(bridgeId, bob, address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH, hex"00");
        console.log("[PASS] T4.5 Non-relayer cannot call bridgeIn");
    }

    function test_T4_bridgeIn_flaggedRecipientBlocked() public {
        bytes32 bridgeId = keccak256("bridge2");
        tokenA.mint(address(router), BRIDGE_AMOUNT);
        vrq.setFlagged(bob, true);

        vm.prank(relayer1);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.VRQ_AddressFlagged.selector, bob)
        );
        router.bridgeIn(bridgeId, bob, address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH, hex"00");
        console.log("[PASS] T4.6 Flagged recipient blocked on bridgeIn");
    }

    function test_T4_bridge_complianceFailureReverts() public {
        vrq.setComplianceResult(false);

        vm.prank(alice);
        vm.expectRevert(KPXRouterGateway.VRQ_ComplianceFailed.selector);
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T4.7 Compliance failure reverts bridgeOut");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T5. ZK-PROOF SECURITY
    // ═══════════════════════════════════════════════════════════════════════

    function test_T5_circuitVersionMismatch() public {
        // Set VRQ verifier với circuit version khác
        vrq.setCircuitVersion(99);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.VRQ_CircuitVersionMismatch.selector, 1, 99
            )
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T5.1 Circuit version mismatch reverts");
    }

    function test_T5_invalidZKProofReverts() public {
        vrq.setProofResult(false);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(alice);
        vm.expectRevert(KPXRouterGateway.VRQ_ZKProofInvalid.selector);
        router.swapExactTokensForTokensWithPrivacy(
            SWAP_AMOUNT, 0, path,
            block.number + 100, VALID_ZK_PROOF, zbPubInputs
        );
        console.log("[PASS] T5.2 Invalid ZK proof reverts swap");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T6. GOVERNANCE & EMERGENCY
    // ═══════════════════════════════════════════════════════════════════════

    function test_T6_emergencyPause_onlyDAO() public {
        // Non-DAO cannot pause
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.KPX_Unauthorized.selector, alice)
        );
        router.emergencyPause("attack detected");

        // DAO can pause
        vm.prank(dao);
        router.emergencyPause("attack detected");
        assertTrue(router.paused());
        console.log("[PASS] T6.1 Emergency pause — only DAO");
    }

    function test_T6_pausedContractRejectsAllBridges() public {
        vm.prank(dao);
        router.emergencyPause("test pause");

        vm.prank(alice);
        vm.expectRevert("Pausable: paused");
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
        console.log("[PASS] T6.2 Paused contract rejects bridgeOut");
    }

    function test_T6_pausedContractRejectsAllSwaps() public {
        vm.prank(dao);
        router.emergencyPause("test pause");

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(alice);
        vm.expectRevert("Pausable: paused");
        router.swapExactTokensForTokensWithPrivacy(
            SWAP_AMOUNT, 0, path, block.number + 100, VALID_ZK_PROOF, zbPubInputs
        );
        console.log("[PASS] T6.3 Paused contract rejects swap");
    }

    function test_T6_unpause_onlyDAO() public {
        vm.prank(dao);
        router.emergencyPause("test");

        // Non-DAO cannot unpause
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.KPX_Unauthorized.selector, alice)
        );
        router.unpause();

        // DAO can unpause
        vm.prank(dao);
        router.unpause();
        assertFalse(router.paused());
        console.log("[PASS] T6.4 Unpause — only DAO");
    }

    function test_T6_setMaxBridgeAmount_onlyDAO() public {
        uint256 newMax = 2_000_000 * 1e18;

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.KPX_Unauthorized.selector, alice)
        );
        router.setMaxBridgeAmount(newMax);

        vm.prank(dao);
        router.setMaxBridgeAmount(newMax);
        assertEq(router.maxBridgeAmountPerTx(), newMax);
        console.log("[PASS] T6.5 setMaxBridgeAmount — only DAO");
    }

    function test_T6_addRelayer_onlyDAO() public {
        address newRelayer = makeAddr("newRelayer");

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.KPX_Unauthorized.selector, alice)
        );
        router.setRelayer(newRelayer, true);

        vm.prank(dao);
        router.setRelayer(newRelayer, true);
        assertEq(router.relayerCount(), 4);
        console.log("[PASS] T6.6 Add relayer — only DAO");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T7. AMM SWAP SECURITY
    // ═══════════════════════════════════════════════════════════════════════

    function test_T7_swap_slippageProtection() public {
        // Dark Pool trả về ít hơn minAmountOut
        darkPool.setThreshold(SWAP_AMOUNT - 1); // Route to dark pool

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256 highMinOut = SWAP_AMOUNT * 2; // Kỳ vọng gấp đôi — impossible

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                KPXRouterGateway.KPX_SlippageExceeded.selector,
                SWAP_AMOUNT, highMinOut  // darkpool trả SWAP_AMOUNT, min là highMinOut
            )
        );
        router.swapExactTokensForTokensWithPrivacy(
            SWAP_AMOUNT, highMinOut, path,
            block.number + 100, VALID_ZK_PROOF, zbPubInputs
        );
        console.log("[PASS] T7.1 Slippage protection reverts when amountOut < min");
    }

    function test_T7_swap_invalidPath() public {
        address[] memory path = new address[](1); // Path cần ít nhất 2 tokens
        path[0] = address(tokenA);

        vm.prank(alice);
        vm.expectRevert(KPXRouterGateway.KPX_InvalidAmount.selector);
        router.swapExactTokensForTokensWithPrivacy(
            SWAP_AMOUNT, 0, path, block.number + 100, VALID_ZK_PROOF, zbPubInputs
        );
        console.log("[PASS] T7.2 Invalid path length reverts");
    }

    function test_T7_swap_zeroAmountReverts() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.prank(alice);
        vm.expectRevert(KPXRouterGateway.KPX_InvalidAmount.selector);
        router.swapExactTokensForTokensWithPrivacy(
            0, 0, path, block.number + 100, VALID_ZK_PROOF, zbPubInputs
        );
        console.log("[PASS] T7.3 Zero amount swap reverts");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // T8. FUZZ TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Fuzz: amount ngẫu nhiên không bao giờ vượt limit
    function testFuzz_T8_bridgeAmountLimit(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount > router.maxBridgeAmountPerTx());

        tokenA.mint(alice, amount);
        vm.prank(alice);
        tokenA.approve(address(router), amount);

        vm.prank(alice);
        vm.expectRevert();
        router.bridgeOut(
            address(tokenA), amount, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
    }

    /// @notice Fuzz: chain ID không hợp lệ luôn revert
    function testFuzz_T8_unsupportedChainAlwaysReverts(uint16 chainId) public {
        vm.assume(chainId != CHAIN_ETH && chainId != CHAIN_ARB && chainId != CHAIN_SOL);

        vm.prank(alice);
        vm.expectRevert();
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, chainId,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
    }

    /// @notice Fuzz: bridgeId đã fulfilled luôn revert khi gọi lại
    function testFuzz_T8_bridgeIdReplayAlwaysReverts(bytes32 bridgeId) public {
        vm.assume(bridgeId != bytes32(0));
        tokenA.mint(address(router), BRIDGE_AMOUNT * 10);

        // First call
        vm.prank(relayer1);
        router.bridgeIn(bridgeId, alice, address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH, hex"00");

        // Replay attack
        vm.prank(relayer1);
        vm.expectRevert();
        router.bridgeIn(bridgeId, alice, address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH, hex"00");
    }

    /// @notice Fuzz: paused contract luôn revert mọi bridge
    function testFuzz_T8_pausedAlwaysReverts(uint256 amount, uint16 chainId) public {
        vm.assume(amount > 0 && amount <= router.maxBridgeAmountPerTx());
        vm.assume(chainId == CHAIN_ETH || chainId == CHAIN_ARB);

        vm.prank(dao);
        router.emergencyPause("fuzz test pause");

        tokenA.mint(alice, amount);
        vm.prank(alice);
        tokenA.approve(address(router), amount);

        vm.prank(alice);
        vm.expectRevert();
        router.bridgeOut(
            address(tokenA), amount, chainId,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
    }

    /// @notice Fuzz: VRQ flagged address luôn bị block
    function testFuzz_T8_flaggedAddressAlwaysBlocked(address malicious) public {
        vm.assume(malicious != address(0));
        vm.assume(malicious != alice); // Không flag alice trong test này

        vrq.setFlagged(malicious, true);
        tokenA.mint(malicious, BRIDGE_AMOUNT);
        vm.prank(malicious);
        tokenA.approve(address(router), BRIDGE_AMOUNT);

        vm.prank(malicious);
        vm.expectRevert(
            abi.encodeWithSelector(KPXRouterGateway.VRQ_AddressFlagged.selector, malicious)
        );
        router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HAPPY PATH — Verify normal operation works
    // ═══════════════════════════════════════════════════════════════════════

    function test_HP_bridgeOut_succeeds() public {
        uint256 balBefore = tokenA.balanceOf(alice);

        vm.prank(alice);
        bytes32 bridgeId = router.bridgeOut(
            address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH,
            bytes32(uint256(uint160(bob))), block.number + 100,
            VALID_ZK_PROOF, KYC_COMMITMENT
        );

        assertNotEq(bridgeId, bytes32(0));
        assertEq(tokenA.balanceOf(alice),          balBefore - BRIDGE_AMOUNT);
        assertEq(tokenA.balanceOf(address(router)), BRIDGE_AMOUNT);
        console.log("[PASS] HP.1 Normal bridgeOut succeeds");
    }

    function test_HP_bridgeIn_succeeds() public {
        bytes32 bridgeId = keccak256("happyBridge");
        tokenA.mint(address(router), BRIDGE_AMOUNT);
        uint256 balBefore = tokenA.balanceOf(bob);

        vm.prank(relayer1);
        router.bridgeIn(bridgeId, bob, address(tokenA), BRIDGE_AMOUNT, CHAIN_ETH, hex"00");

        assertEq(tokenA.balanceOf(bob), balBefore + BRIDGE_AMOUNT);
        assertTrue(router.isBridgeFulfilled(bridgeId));
        console.log("[PASS] HP.2 Normal bridgeIn succeeds");
    }
}
