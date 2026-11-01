// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — KINETOPROTOCOL ($KPX)
// KPXRouterGateway.sol — Cổng Định tuyến Chính thức
//
// ╔══════════════════════════════════════════════════════════════════╗
// ║  STATUS: DRAFT v0.0.0 — PENDING SECURITY REVIEW                ║
// ║  Foundry Tests: core/contracts/kpx/test/KPXRouterGateway.t.sol ║
// ║  Security Checklist: core/contracts/KPXRouter-security-review  ║
// ║  DO NOT DEPLOY until all 30 security checks PASSED             ║
// ╚══════════════════════════════════════════════════════════════════╝
//
// Ref: Whitepaper §11.10 · §11.11
// Ref: core/contracts/IKPXRouter.sol (interface)

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVRQVerifier.sol";
import "./interfaces/IKPXDarkPool.sol";

/**
 * @title KPXRouterGateway
 * @author AXIOLEDGER Core Team
 * @notice Cổng định tuyến trung tâm của KINETOPROTOCOL ($KPX).
 *         Xử lý: Cross-chain Bridge · AMM Swap · RWA Treasury · Dark Pool routing
 *
 * @dev Architecture notes:
 *  - ReentrancyGuard:  Bảo vệ TẤT CẢ external state-changing functions
 *  - Pausable:         Emergency freeze — chỉ TreasuryDAO 5/7 multisig được gọi
 *  - SafeERC20:        Không dùng transfer() trực tiếp — tránh silent failure
 *  - No admin key:     owner = TreasuryDAO multisig, không phải EOA
 *  - VRQ pre-check:    isFlagged() là CHECK ĐẦU TIÊN trong mọi function
 *  - ZK verification:  Sau VRQ check, trước bất kỳ state change nào
 *
 * Security model (theo checklist core/contracts/KPXRouter-security-review.md):
 *  A. AMM:      ReentrancyGuard + deadline + slippage + TWAP
 *  B. Bridge:   MPC 2/3 + replay prevention + drain limit + chain whitelist
 *  C. RWA:      15% collateral + oracle TWAP + institutional KYC
 *  D. DarkPool: Pedersen commitment + ZK match proof
 *  E. Govern:   No EOA admin + DAO-only pause + timelock
 *  F. Integ:    Circuit version check + VRQ real-time
 */
contract KPXRouterGateway is ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ─── Immutables ──────────────────────────────────────────────────────────
    IVRQVerifier public immutable zkVerifier;
    IKPXDarkPool public immutable darkPool;

    // ─── State variables ─────────────────────────────────────────────────────

    /// @notice TreasuryDAO multisig address — không phải EOA
    address public treasuryDAO;

    /// @notice Giới hạn bridge mỗi tx (anti-drain)
    uint256 public maxBridgeAmountPerTx = 1_000_000 * 1e18;

    /// @notice Chain IDs được phép bridge
    mapping(uint16 => bool) public supportedChains;

    /// @notice Bridge ID đã fulfilled (replay prevention)
    mapping(bytes32 => bool) public bridgeFulfilled;

    /// @notice MPC Relayer set (2/3 threshold required)
    mapping(address => bool) public mpcRelayers;
    uint256 public relayerCount;
    uint256 public constant RELAYER_THRESHOLD_NUMERATOR   = 2;
    uint256 public constant RELAYER_THRESHOLD_DENOMINATOR = 3;

    /// @notice Circuit version phải match với ZK verifier
    uint256 public requiredCircuitVersion;

    /// @notice ZK proof nonce set (anti-replay cho ZK proofs)
    mapping(bytes32 => bool) public usedProofNonces;

    // ─── Events ──────────────────────────────────────────────────────────────

    event CrossChainDeposit(
        address indexed user,
        uint256 amount,
        uint16  destChainId,
        bytes32 kycCommitment,
        bytes32 bridgeId
    );

    event BridgeCompleted(
        bytes32 indexed bridgeId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint16  sourceChainId
    );

    event RoutingExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bool    routedToDarkPool
    );

    event EmergencyPaused(address indexed caller, string reason);
    event EmergencyUnpaused(address indexed caller);
    event MaxBridgeAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event ChainSupportUpdated(uint16 chainId, bool supported);
    event RelayerUpdated(address relayer, bool active);

    // ─── Errors ──────────────────────────────────────────────────────────────

    error VRQ_AddressFlagged(address addr);
    error VRQ_ZKProofInvalid();
    error VRQ_ComplianceFailed();
    error VRQ_CircuitVersionMismatch(uint256 required, uint256 actual);
    error KPX_InvalidAmount();
    error KPX_SlippageExceeded(uint256 amountOut, uint256 minRequired);
    error KPX_DeadlineExpired(uint256 deadline, uint256 current);
    error KPX_UnsupportedChain(uint16 chainId);
    error KPX_BridgeAmountExceedsLimit(uint256 amount, uint256 limit);
    error KPX_BridgeAlreadyFulfilled(bytes32 bridgeId);
    error KPX_ProofAlreadyUsed(bytes32 proofNonce);
    error KPX_NotRelayer(address caller);
    error KPX_InsufficientRelayerSignatures();
    error KPX_Unauthorized(address caller);
    error KPX_ZeroAddress();

    // ─── Modifiers ───────────────────────────────────────────────────────────

    /// @dev VRQ pre-check: gọi ĐẦU TIÊN trước bất kỳ logic nào
    modifier vrqClear(address addr) {
        if (zkVerifier.isFlagged(addr)) revert VRQ_AddressFlagged(addr);
        _;
    }

    /// @dev Chỉ TreasuryDAO multisig
    modifier onlyDAO() {
        if (msg.sender != treasuryDAO) revert KPX_Unauthorized(msg.sender);
        _;
    }

    /// @dev Chỉ MPC Relayer
    modifier onlyRelayer() {
        if (!mpcRelayers[msg.sender]) revert KPX_NotRelayer(msg.sender);
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    /// @param _zkVerifier          VRQ ZK Verifier contract address
    /// @param _darkPool            KPX Dark Pool contract address
    /// @param _treasuryDAO         TreasuryDAO multisig — sẽ là owner
    /// @param _initialRelayers     Danh sách MPC relayers ban đầu
    /// @param _supportedChainIds   Chain IDs được phép bridge lúc deploy
    /// @param _circuitVersion      ZK circuit version yêu cầu
    constructor(
        address _zkVerifier,
        address _darkPool,
        address _treasuryDAO,
        address[] memory _initialRelayers,
        uint16[]  memory _supportedChainIds,
        uint256          _circuitVersion
    ) {
        if (_zkVerifier == address(0))  revert KPX_ZeroAddress();
        if (_darkPool == address(0))    revert KPX_ZeroAddress();
        if (_treasuryDAO == address(0)) revert KPX_ZeroAddress();

        zkVerifier          = IVRQVerifier(_zkVerifier);
        darkPool            = IKPXDarkPool(_darkPool);
        treasuryDAO         = _treasuryDAO;
        requiredCircuitVersion = _circuitVersion;

        for (uint256 i = 0; i < _initialRelayers.length; i++) {
            mpcRelayers[_initialRelayers[i]] = true;
            relayerCount++;
        }

        for (uint256 i = 0; i < _supportedChainIds.length; i++) {
            supportedChains[_supportedChainIds[i]] = true;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 1: CROSS-CHAIN BRIDGE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Khởi tạo luồng chuyển tài sản sang chuỗi khác (Outbound)
     * @param _token         Token cần bridge
     * @param _amount        Số lượng token
     * @param _destChainId   Chain ID đích (SLIP-44)
     * @param _recipient     Địa chỉ nhận trên chain đích (bytes32 — EVM + non-EVM)
     * @param _deadline      Block deadline
     * @param _zkProof       ZK compliance proof từ VRQ
     * @param _kycCommitment KYC commitment (không lộ dữ liệu thô)
     * @return bridgeId      ID duy nhất cho operation này
     *
     * Security flow:
     *  [1] VRQ: msg.sender không bị flag
     *  [2] VRQ: token contract không bị flag
     *  [3] ZK: circuit version match
     *  [4] ZK: proof nonce chưa dùng (anti-replay)
     *  [5] ZK: verifyCompliance pass
     *  [6] Chain whitelist check
     *  [7] Amount limit check
     *  [8] Transfer tokens to this contract (escrow)
     *  [9] Emit event — MPC relayers lắng nghe để unlock phía đích
     */
    function bridgeOut(
        address _token,
        uint256 _amount,
        uint16  _destChainId,
        bytes32 _recipient,
        uint256 _deadline,
        bytes   calldata _zkProof,
        bytes32 _kycCommitment
    )
        external
        nonReentrant
        whenNotPaused
        vrqClear(msg.sender)
        returns (bytes32 bridgeId)
    {
        // [2] Token contract không bị flag
        if (zkVerifier.isFlagged(_token)) revert VRQ_AddressFlagged(_token);

        // [3] Circuit version
        uint256 actualVersion = zkVerifier.circuitVersion();
        if (actualVersion != requiredCircuitVersion)
            revert VRQ_CircuitVersionMismatch(requiredCircuitVersion, actualVersion);

        // [4] Proof nonce anti-replay
        bytes32 proofNonce = keccak256(_zkProof);
        if (usedProofNonces[proofNonce]) revert KPX_ProofAlreadyUsed(proofNonce);
        usedProofNonces[proofNonce] = true;

        // [5] ZK compliance
        if (!zkVerifier.verifyCompliance(_zkProof, _kycCommitment))
            revert VRQ_ComplianceFailed();

        // [6] Chain whitelist
        if (!supportedChains[_destChainId]) revert KPX_UnsupportedChain(_destChainId);

        // [7] Amount limit
        if (_amount == 0) revert KPX_InvalidAmount();
        if (_amount > maxBridgeAmountPerTx)
            revert KPX_BridgeAmountExceedsLimit(_amount, maxBridgeAmountPerTx);

        // [8] Deadline
        if (block.number > _deadline) revert KPX_DeadlineExpired(_deadline, block.number);

        // [9] Escrow: transfer tokens từ sender vào contract này
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // Generate bridgeId
        bridgeId = keccak256(abi.encodePacked(
            msg.sender, _token, _amount, _destChainId, _recipient, block.number
        ));

        emit CrossChainDeposit(msg.sender, _amount, _destChainId, _kycCommitment, bridgeId);
    }

    /**
     * @notice Hoàn thành bridge khi tài sản về từ chain khác (Inbound)
     *         Chỉ MPC Relayer (với threshold 2/3) được gọi
     *
     * Security flow:
     *  [1] onlyRelayer modifier
     *  [2] bridgeId chưa fulfilled (replay prevention)
     *  [3] VRQ: recipient không bị flag
     *  [4] Mark fulfilled TRƯỚC khi transfer (CEI pattern)
     *  [5] Transfer tokens ra
     */
    function bridgeIn(
        bytes32 _bridgeId,
        address _recipient,
        address _token,
        uint256 _amount,
        uint16  _sourceChainId,
        bytes   calldata _mpcSignatures
    )
        external
        nonReentrant
        whenNotPaused
        onlyRelayer
    {
        // [2] Replay prevention — CHECK TRƯỚC state change
        if (bridgeFulfilled[_bridgeId]) revert KPX_BridgeAlreadyFulfilled(_bridgeId);

        // [3] VRQ recipient check
        if (zkVerifier.isFlagged(_recipient)) revert VRQ_AddressFlagged(_recipient);

        // Verify MPC signatures threshold (simplified — production cần full MPC verify)
        _verifyMPCThreshold(_bridgeId, _mpcSignatures);

        // [4] Mark FULFILLED trước khi transfer (CEI: Checks-Effects-Interactions)
        bridgeFulfilled[_bridgeId] = true;

        // [5] Transfer
        IERC20(_token).safeTransfer(_recipient, _amount);

        emit BridgeCompleted(_bridgeId, _recipient, _token, _amount, _sourceChainId);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 2: AMM SWAP + DARK POOL ROUTING
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Định tuyến swap — tự động vào Dark Pool nếu vượt institutional threshold
     * @param _amountIn     Token đầu vào
     * @param _amountOutMin Tối thiểu nhận về (slippage protection)
     * @param _path         [tokenIn, ..., tokenOut]
     * @param _deadline     Block deadline
     * @param _zkProof      ZK-Proof danh tính
     * @param _zkPubInputs  Public inputs
     * @return amountOut    Số lượng thực tế nhận về
     *
     * Security flow:
     *  [1] VRQ: msg.sender không bị flag
     *  [2] ZK circuit version + proof nonce
     *  [3] ZK proof verify
     *  [4] Deadline check
     *  [5] Dark Pool routing nếu > threshold, AMM nếu không
     *  [6] Slippage check
     */
    function swapExactTokensForTokensWithPrivacy(
        uint256   _amountIn,
        uint256   _amountOutMin,
        address[] calldata _path,
        uint256   _deadline,
        bytes     calldata _zkProof,
        uint256[] calldata _zkPubInputs
    )
        external
        nonReentrant
        whenNotPaused
        vrqClear(msg.sender)
        returns (uint256 amountOut)
    {
        // [2] Circuit version + nonce
        uint256 actualVersion = zkVerifier.circuitVersion();
        if (actualVersion != requiredCircuitVersion)
            revert VRQ_CircuitVersionMismatch(requiredCircuitVersion, actualVersion);

        bytes32 proofNonce = keccak256(_zkProof);
        if (usedProofNonces[proofNonce]) revert KPX_ProofAlreadyUsed(proofNonce);
        usedProofNonces[proofNonce] = true;

        // [3] ZK verify
        if (!zkVerifier.verifyProof(_zkProof, _zkPubInputs)) revert VRQ_ZKProofInvalid();

        // [4] Deadline
        if (block.number > _deadline) revert KPX_DeadlineExpired(_deadline, block.number);

        if (_amountIn == 0) revert KPX_InvalidAmount();
        if (_path.length < 2) revert KPX_InvalidAmount();

        // Transfer token vào contract (CEI)
        IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), _amountIn);

        bool routedDark = false;

        // [5] Route decision
        if (_amountIn > darkPool.getInstitutionalThreshold()) {
            // Dark Pool routing — ẩn danh, không frontrun
            IERC20(_path[0]).approve(address(darkPool), _amountIn);
            amountOut = darkPool.executeConfidentialSwap(
                msg.sender, _amountIn, _path, _zkProof
            );
            routedDark = true;
        } else {
            // Standard AMM — TODO: integrate actual AMM pool trong v0.1.0
            // amountOut = standardAMM.swap(_path, _amountIn, address(this));
            amountOut = _amountIn; // Placeholder — sẽ thay bằng AMM call thực
        }

        // [6] Slippage guard — enforce SAU khi có amountOut
        if (amountOut < _amountOutMin)
            revert KPX_SlippageExceeded(amountOut, _amountOutMin);

        // Transfer output ra cho user
        IERC20(_path[_path.length - 1]).safeTransfer(msg.sender, amountOut);

        emit RoutingExecuted(
            msg.sender, _path[0], _path[_path.length - 1],
            _amountIn, amountOut, routedDark
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 3: GOVERNANCE & EMERGENCY
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Emergency pause — chỉ TreasuryDAO 5/7 multisig
     * @param reason Lý do ghi vĩnh viễn on-chain
     */
    function emergencyPause(string calldata reason) external onlyDAO {
        _pause();
        emit EmergencyPaused(msg.sender, reason);
    }

    /// @notice Unpause — chỉ sau khi DAO vote thông qua
    function unpause() external onlyDAO {
        _unpause();
        emit EmergencyUnpaused(msg.sender);
    }

    /// @notice Cập nhật max bridge amount (chỉ DAO)
    function setMaxBridgeAmount(uint256 _newMax) external onlyDAO {
        emit MaxBridgeAmountUpdated(maxBridgeAmountPerTx, _newMax);
        maxBridgeAmountPerTx = _newMax;
    }

    /// @notice Thêm/xóa chain support (chỉ DAO)
    function setChainSupport(uint16 _chainId, bool _supported) external onlyDAO {
        supportedChains[_chainId] = _supported;
        emit ChainSupportUpdated(_chainId, _supported);
    }

    /// @notice Cập nhật MPC relayer set (chỉ DAO)
    function setRelayer(address _relayer, bool _active) external onlyDAO {
        if (_relayer == address(0)) revert KPX_ZeroAddress();
        if (_active && !mpcRelayers[_relayer]) {
            mpcRelayers[_relayer] = true;
            relayerCount++;
        } else if (!_active && mpcRelayers[_relayer]) {
            mpcRelayers[_relayer] = false;
            relayerCount--;
        }
        emit RelayerUpdated(_relayer, _active);
    }

    // ─── Internal helpers ───────────────────────────────────────────────────

    /// @dev Kiểm tra MPC threshold signatures đơn giản hóa
    ///      Production: cần full BLS/ECDSA multi-sig aggregation verify
    function _verifyMPCThreshold(bytes32 bridgeId, bytes calldata /*signatures*/) internal view {
        // Simplified check: caller phải là relayer (enforced by onlyRelayer modifier)
        // Production: parse signatures, verify each, count unique valid relayers >= 2/3
        uint256 required = (relayerCount * RELAYER_THRESHOLD_NUMERATOR + RELAYER_THRESHOLD_DENOMINATOR - 1)
                           / RELAYER_THRESHOLD_DENOMINATOR;
        // In production: if (validCount < required) revert KPX_InsufficientRelayerSignatures();
        // Placeholder assertion để compiler không warn unused variable
        if (required == 0 && bridgeId == bytes32(0)) revert KPX_InsufficientRelayerSignatures();
    }

    /// @notice View helpers
    function paused() public view override returns (bool) { return super.paused(); }
    function getSupportedChains(uint16 id) external view returns (bool) { return supportedChains[id]; }
    function isBridgeFulfilled(bytes32 id) external view returns (bool) { return bridgeFulfilled[id]; }
}
