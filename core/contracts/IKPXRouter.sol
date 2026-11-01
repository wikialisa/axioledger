// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — KINETOPROTOCOL ($KPX)
// IKPXRouter.sol — Cổng Định tuyến KPX
//
// ╔══════════════════════════════════════════════════════════════════╗
// ║  SECURITY REVIEW REQUIRED trước khi deploy lên Mainnet          ║
// ║  Status: DRAFT v0.0.0 — Pending Audit                           ║
// ║  Auditors: GL-LEGAL-COMP-01 + GL-ARCH-CORE-ENGINE               ║
// ╚══════════════════════════════════════════════════════════════════╝
//
// Ref: docs/Whitepaper AXIOLEDGER ($AXQ).md §11.10-11.11
// Ref: core/api/api-schema-v0.0.0.md /kpx/

pragma solidity ^0.8.24;

// ─── Interfaces ─────────────────────────────────────────────────────────────

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IZKVerifier {
    /// @notice Xác minh ZK-Proof từ VERACIPHERS ($VRQ)
    /// @param proof   ZK-SNARKs proof bytes (~284 bytes)
    /// @param pubInputs Public inputs cho circuit
    /// @return valid  True nếu proof hợp lệ
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata pubInputs
    ) external view returns (bool valid);
}

interface IVRQScanner {
    /// @notice Kiểm tra địa chỉ có trong blacklist VRQ Supply Chain Scanner
    /// @param addr Địa chỉ cần kiểm tra
    /// @return flagged True nếu địa chỉ bị đánh dấu độc hại
    function isFlagged(address addr) external view returns (bool flagged);

    /// @notice Kiểm tra transaction hash có bị detect là tấn công Bridge
    /// @param txHash Hash của transaction cần kiểm tra
    /// @return safe True nếu transaction an toàn
    function isTxSafe(bytes32 txHash) external view returns (bool safe);
}

interface ITreasuryDAO {
    /// @notice Kiểm tra proposal đã được DAO approve chưa
    function isApproved(bytes32 proposalId) external view returns (bool);
}

// ─── Events ─────────────────────────────────────────────────────────────────

interface IKPXRouterEvents {
    event SwapExecuted(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 slippageBps,      // Basis points (1 bps = 0.01%)
        bytes32 zkProofHash
    );

    event BridgeInitiated(
        bytes32 indexed bridgeId,
        address indexed sender,
        address tokenIn,
        uint256 amount,
        uint16  targetChainId,    // SLIP-44 chain ID
        bytes32 zkProofHash
    );

    event BridgeCompleted(
        bytes32 indexed bridgeId,
        address indexed recipient,
        address tokenOut,
        uint256 amountOut
    );

    event RWADeposit(
        address indexed depositor,
        bytes32 indexed rwaAssetId,
        uint256 axqCollateral,    // 15% AXQ collateral locked
        uint256 rwaTokensMinted
    );

    event DarkPoolOrderPlaced(
        bytes32 indexed orderId,
        bytes32 commitment,       // ZK commitment — hides amount & direction
        uint256 expiryBlock
    );

    event DarkPoolOrderFilled(
        bytes32 indexed orderId,
        bytes32 zkProofHash       // Proof of correct fill without revealing details
    );

    event SecurityCheckFailed(
        address indexed caller,
        string reason,
        bytes32 txHash
    );

    event EmergencyPaused(address indexed by, string reason);
    event EmergencyUnpaused(address indexed by, bytes32 daoProposalId);
}

// ─── Main Interface ──────────────────────────────────────────────────────────

/// @title IKPXRouter — KINETOPROTOCOL Gateway Interface
/// @notice Cổng định tuyến trung tâm của KPX:
///         AMM Swap · Cross-chain Bridge · RWA Treasury · Dark Pool
/// @dev Mọi hàm đều yêu cầu ZK-Proof hợp lệ từ VRQ + VRQ Scanner clearance
///      trước khi thực thi. Không có admin key — mọi thay đổi qua TreasuryDAO.
interface IKPXRouter is IKPXRouterEvents {

    // ═══════════════════════════════════════════════════════════════
    // SECTION 1: AMM SWAP — Định tuyến Chống Trượt Giá
    // ═══════════════════════════════════════════════════════════════

    /// @notice Tính toán output amount trước khi swap (read-only, no side effects)
    /// @param tokenIn   Địa chỉ token đầu vào
    /// @param tokenOut  Địa chỉ token đầu ra
    /// @param amountIn  Số lượng token đầu vào
    /// @return amountOut       Số lượng token đầu ra dự kiến
    /// @return priceImpactBps  Tác động giá tính bằng basis points
    /// @return routePath       Đường đi tối ưu qua các pools
    function quoteSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (
        uint256 amountOut,
        uint256 priceImpactBps,
        address[] memory routePath
    );

    /// @notice Thực thi swap với ZK-Proof bắt buộc
    /// @param tokenIn          Token đầu vào
    /// @param tokenOut         Token đầu ra
    /// @param amountIn         Số lượng token đầu vào
    /// @param minAmountOut     Số lượng tối thiểu chấp nhận (slippage protection)
    /// @param deadline         Block number deadline — revert nếu quá hạn
    /// @param zkProof          ZK-Proof từ VRQ xác thực danh tính người dùng
    /// @param zkPubInputs      Public inputs cho ZK circuit
    /// @return amountOut       Số lượng token thực tế nhận được
    /// @return actualSlipBps   Slippage thực tế xảy ra (basis points)
    ///
    /// @dev Security requirements:
    ///      [1] VRQ Scanner: caller và recipient không bị flag
    ///      [2] ZK-Proof valid từ IZKVerifier
    ///      [3] amountOut >= minAmountOut (slippage guard)
    ///      [4] block.number <= deadline
    ///      [5] Contract không bị paused
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bytes   calldata zkProof,
        uint256[] calldata zkPubInputs
    ) external returns (uint256 amountOut, uint256 actualSlipBps);

    /// @notice Thêm thanh khoản vào AMM Pool
    /// @param tokenA        Token A
    /// @param tokenB        Token B
    /// @param amountADesired Số lượng A muốn thêm
    /// @param amountBDesired Số lượng B muốn thêm
    /// @param amountAMin    Số lượng A tối thiểu
    /// @param amountBMin    Số lượng B tối thiểu
    /// @param to            Địa chỉ nhận LP tokens
    /// @param deadline      Block number deadline
    /// @return amountA      Số lượng A thực tế thêm vào
    /// @return amountB      Số lượng B thực tế thêm vào
    /// @return liquidity    LP tokens mint cho `to`
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Rút thanh khoản khỏi AMM Pool
    /// @param tokenA    Token A
    /// @param tokenB    Token B
    /// @param liquidity LP tokens muốn đốt
    /// @param amountAMin Số lượng A tối thiểu nhận về
    /// @param amountBMin Số lượng B tối thiểu nhận về
    /// @param to        Địa chỉ nhận tokens
    /// @param deadline  Block number deadline
    /// @return amountA  Token A nhận về
    /// @return amountB  Token B nhận về
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);


    // ═══════════════════════════════════════════════════════════════
    // SECTION 2: CROSS-CHAIN BRIDGE — Cầu nối Liên chuỗi
    // ═══════════════════════════════════════════════════════════════

    /// @notice Lấy trạng thái một Bridge operation
    enum BridgeStatus { PENDING, IN_FLIGHT, COMPLETED, FAILED, REFUNDED }

    /// @notice Bắt đầu bridge tài sản sang chain khác
    /// @param token         Token cần bridge
    /// @param amount        Số lượng
    /// @param targetChainId Chain ID đích (SLIP-44: 60=ETH, 501=SOL, 42161=ARB)
    /// @param recipient     Địa chỉ nhận trên chain đích
    /// @param deadline      Block deadline trên chain nguồn
    /// @param zkProof       ZK-Proof identity từ VRQ
    /// @param zkPubInputs   Public inputs
    /// @return bridgeId     ID duy nhất cho bridge operation này
    ///
    /// @dev Security requirements:
    ///      [1] VRQ Scanner: token contract không bị flag (không bridge token độc hại)
    ///      [2] ZK-Proof valid — danh tính người gửi được xác minh
    ///      [3] targetChainId nằm trong whitelist (ETH, ARB, SOL)
    ///      [4] amount <= maxBridgeAmountPerTx (anti-whale, anti-drain)
    ///      [5] MPC Relayers: ≥ 2/3 signatures trước khi unlock phía đích
    ///      [6] Không bridge khi contract paused
    function bridgeOut(
        address token,
        uint256 amount,
        uint16  targetChainId,
        bytes32 recipient,       // bytes32 để tương thích cả EVM và non-EVM (Solana)
        uint256 deadline,
        bytes   calldata zkProof,
        uint256[] calldata zkPubInputs
    ) external returns (bytes32 bridgeId);

    /// @notice Hoàn thành bridge khi tài sản về từ chain khác
    ///         Chỉ được gọi bởi MPC Relayer multisig (2/3 threshold)
    /// @param bridgeId      ID của bridge operation
    /// @param recipient     Địa chỉ nhận trên chain này
    /// @param token         Token cần unlock/mint
    /// @param amount        Số lượng
    /// @param sourceChainId Chain ID nguồn
    /// @param mpcSignatures Aggregated MPC signatures (≥ 2/3 relayers)
    ///
    /// @dev Security requirements:
    ///      [1] Chỉ địa chỉ trong mpcRelayerSet được gọi
    ///      [2] mpcSignatures hợp lệ và đạt threshold 2/3
    ///      [3] bridgeId chưa được fulfill (replay attack prevention)
    ///      [4] VRQ Scanner: recipient không bị flag
    function bridgeIn(
        bytes32 bridgeId,
        address recipient,
        address token,
        uint256 amount,
        uint16  sourceChainId,
        bytes   calldata mpcSignatures
    ) external;

    /// @notice Truy vấn trạng thái bridge operation
    function getBridgeStatus(bytes32 bridgeId)
        external view returns (BridgeStatus status, uint256 updatedAt);

    /// @notice Lấy danh sách chain IDs được phép bridge
    function getSupportedChains() external view returns (uint16[] memory chainIds);


    // ═══════════════════════════════════════════════════════════════
    // SECTION 3: RWA TREASURY — Tài sản Thế giới Thực
    // ═══════════════════════════════════════════════════════════════

    /// @notice Cấu trúc mô tả một RWA asset
    struct RWAAsset {
        bytes32 assetId;
        string  assetType;       // "BOND", "CERTIFICATE_OF_DEPOSIT", "GOVERNMENT_DEBT"
        uint256 faceValue;       // Giá trị danh nghĩa (USD, 18 decimals)
        uint256 maturityDate;    // Unix timestamp khi đáo hạn
        uint256 yieldRateBps;    // Lãi suất (basis points per year)
        address issuer;          // Địa chỉ tổ chức phát hành
        bytes32 legalDocHash;    // IPFS hash của tài liệu pháp lý
        bool    active;
    }

    /// @notice Gửi RWA vào Treasury — yêu cầu 15% AXQ collateral
    /// @param assetId       ID của RWA asset (được cấp bởi oracle off-chain)
    /// @param rwaAmount     Số lượng RWA tokens muốn mint
    /// @param axqCollateral AXQ collateral nộp vào (phải >= 15% faceValue)
    /// @param zkProof       ZK-Proof institutional identity
    /// @param zkPubInputs   Public inputs
    /// @return rwaTokens    Số lượng RWA tokens được mint
    ///
    /// @dev Security requirements:
    ///      [1] assetId phải được oracle KPX xác nhận hợp lệ
    ///      [2] axqCollateral >= rwaAmount * faceValuePerToken * 15 / 100
    ///      [3] ZK-Proof valid — chỉ institutional tier được phép
    ///      [4] Gọi VRQ KYC/AML: depositor phải pass institutional KYC
    function depositRWA(
        bytes32 assetId,
        uint256 rwaAmount,
        uint256 axqCollateral,
        bytes   calldata zkProof,
        uint256[] calldata zkPubInputs
    ) external returns (uint256 rwaTokens);

    /// @notice Rút RWA khỏi Treasury
    /// @param assetId   ID tài sản
    /// @param rwaTokens Số lượng RWA tokens muốn đốt để nhận lại AXQ collateral
    /// @return axqReturned AXQ collateral + accumulated yield trả về
    function withdrawRWA(
        bytes32 assetId,
        uint256 rwaTokens
    ) external returns (uint256 axqReturned);

    /// @notice Trigger RWA Yield Buyback — 10% yield → mua lại + đốt $AXQ
    ///         Chỉ được gọi bởi cron script hoặc DAO proposal
    /// @param assetId   ID tài sản để thu hoạch yield
    /// @return yieldHarvested  Tổng yield thu hoạch (AXQ)
    /// @return axqBurned       Lượng AXQ đã đốt (10% của yield)
    function harvestAndBuyback(bytes32 assetId)
        external returns (uint256 yieldHarvested, uint256 axqBurned);

    /// @notice Truy vấn thông tin RWA asset
    function getRWAAsset(bytes32 assetId) external view returns (RWAAsset memory);


    // ═══════════════════════════════════════════════════════════════
    // SECTION 4: DARK POOL — Hồ bơi Thanh khoản Ẩn
    // ═══════════════════════════════════════════════════════════════

    /// @notice Đặt lệnh ẩn vào Dark Pool
    ///         Commitment ẩn toàn bộ: token, số lượng, hướng giao dịch
    /// @param commitment    Pedersen commitment: C = r*G + v*H
    ///                      (ẩn giá trị v và randomness r)
    /// @param expiryBlocks  Lệnh tự huỷ sau bao nhiêu blocks
    /// @param zkProof       ZK-Proof institutional identity
    /// @param zkPubInputs   Public inputs
    /// @return orderId      ID duy nhất cho lệnh
    ///
    /// @dev Security requirements:
    ///      [1] Caller phải là institutional tier (ZK-Proof xác nhận)
    ///      [2] Commitment chưa tồn tại (anti-replay)
    ///      [3] expiryBlocks <= MAX_ORDER_EXPIRY (tránh lệnh "zombie")
    ///      [4] Minimum deposit để tránh spam: MIN_DARK_POOL_DEPOSIT AXQ
    function placeDarkPoolOrder(
        bytes32 commitment,
        uint256 expiryBlocks,
        bytes   calldata zkProof,
        uint256[] calldata zkPubInputs
    ) external payable returns (bytes32 orderId);

    /// @notice Matching engine thực thi khớp lệnh Dark Pool
    ///         Chỉ được gọi bởi KPX Matching Engine (off-chain MPC + ZK)
    /// @param orderIdA      Order của bên mua
    /// @param orderIdB      Order của bên bán
    /// @param zkMatchProof  ZK-Proof: 2 commitments khớp nhau, fill đúng giá
    ///                      mà không tiết lộ số lượng hay hướng
    /// @param pubInputs     Public inputs
    ///
    /// @dev Security requirements:
    ///      [1] Chỉ matchingEngine address được gọi hàm này
    ///      [2] zkMatchProof phải valid qua IZKVerifier
    ///      [3] Cả 2 orders chưa expired và chưa filled
    ///      [4] Không thể frontrun vì commitment ẩn
    function fillDarkPoolOrder(
        bytes32 orderIdA,
        bytes32 orderIdB,
        bytes   calldata zkMatchProof,
        uint256[] calldata pubInputs
    ) external;

    /// @notice Huỷ lệnh Dark Pool đã hết hạn — trả lại deposit
    /// @param orderId Order cần huỷ
    function cancelDarkPoolOrder(bytes32 orderId) external;


    // ═══════════════════════════════════════════════════════════════
    // SECTION 5: SECURITY & GOVERNANCE
    // ═══════════════════════════════════════════════════════════════

    /// @notice Truy vấn địa chỉ VRQ Scanner contract đang dùng
    function vrqScanner() external view returns (address);

    /// @notice Truy vấn địa chỉ ZK Verifier contract đang dùng
    function zkVerifier() external view returns (address);

    /// @notice Truy vấn trạng thái pause
    function paused() external view returns (bool);

    /// @notice Kiểm tra bridge amount limit
    function maxBridgeAmountPerTx() external view returns (uint256);

    /// @notice Dừng khẩn cấp toàn bộ router
    ///         Chỉ được gọi bởi TreasuryDAO emergency multisig (5/7)
    /// @param reason Lý do dừng khẩn cấp — ghi log vĩnh viễn on-chain
    function emergencyPause(string calldata reason) external;

    /// @notice Khôi phục hoạt động sau emergency pause
    ///         Yêu cầu TreasuryDAO governance proposal được approve
    /// @param daoProposalId ID của proposal đã được DAO bỏ phiếu thông qua
    function unpause(bytes32 daoProposalId) external;

    /// @notice Cập nhật VRQ Scanner address (chỉ qua DAO)
    function updateVRQScanner(address newScanner, bytes32 daoProposalId) external;

    /// @notice Cập nhật ZK Verifier address (chỉ qua DAO)
    function updateZKVerifier(address newVerifier, bytes32 daoProposalId) external;
}
