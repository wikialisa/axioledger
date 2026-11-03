// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ─── Interface ────────────────────────────────────────────────────────────────

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// ─── BrandSwiftBridgeV2 ────────────────────────────────────────────────────────
//
// Smart Contract nâng cấp từ BrandSwiftBridge.sol với:
//   • FX Rate Oracle: quy đổi ngoại tệ (USD/EUR/JPY/SGD/GBP) → YOUR_TOKEN (1 YOUR_TOKEN = 1 VND)
//   • Gas Fee Controller: Base Gas Fee cố định + Bridge Fee % (bps)
//   • Treasury Vault: phí gas/bridge chuyển về YOUR_TOKEN Treasury thay vì fee recipient
//   • Multi-currency OUTBOUND: user burn YOUR_TOKEN → request amount theo ngoại tệ
//
// Công thức quy đổi:
//   grossAXVN    = originalAmount × fxRate
//   gasFee       = baseGasFeeAXVN + (grossAXVN × bridgeFeeBps / 10000)
//   netAXVNMint  = grossAXVN − gasFee
//
// Deployed on: YOUR_TOKEN Enterprise App-Chain EVM (Hyperledger Besu)

contract BrandSwiftBridgeV2 {

    // ─── Storage ──────────────────────────────────────────────────────────────

    address public oracleRelayer;
    address public pendingRelayer;
    address public owner;
    address public treasuryVault;

    /// YOUR_TOKEN Token — 1 YOUR_TOKEN = 1 VND (18 decimals)
    IERC20Mintable public YOUR_TOKENToken;

    /// Phí bridge mặc định: 10 bps = 0.1%
    uint256 public bridgeFeeBps = 10;

    /// Phí gas cơ bản mặc định: 10,000 YOUR_TOKEN (10,000 VND)
    /// Có thể ghi đè bởi Relayer khi gọi settleInboundSwiftWithFX
    uint256 public defaultBaseGasFeeAXVN = 10_000 * 1e18;

    // ─── Structs ──────────────────────────────────────────────────────────────

    enum TxStatus { NONE, PENDING, SETTLED, FAILED, REFUNDED }

    struct SwiftRecord {
        bytes32 uetrHash;
        /// Ký hiệu ngoại tệ gốc: "USD", "EUR", "JPY", "SGD", "VND", ...
        string  originalCurrency;
        /// Số tiền ngoại tệ gốc (đơn vị nguyên, e.g. USD cents hoặc full unit)
        uint256 originalAmount;
        /// Tỷ giá quy đổi sang VND, ví dụ: 25450 (1 USD = 25,450 VND)
        uint256 fxRate;
        /// Tổng YOUR_TOKEN trước khi trừ phí: originalAmount × fxRate
        uint256 grossAXVNAmount;
        /// Phí gas + bridge (YOUR_TOKEN) chuyển về Treasury
        uint256 gasFeeAXVN;
        /// YOUR_TOKEN thực nhận sau trừ phí
        uint256 netAXVNAmount;
        address beneficiary;
        TxStatus status;
        uint256  settledAt;
    }

    mapping(bytes32 => SwiftRecord) public swiftRecords;

    /// Tổng YOUR_TOKEN đã mint inbound (theo lịch sử)
    uint256 public totalAXVNMinted;
    /// Tổng phí YOUR_TOKEN đã thu về Treasury
    uint256 public totalFeeCollected;

    // ─── Events ───────────────────────────────────────────────────────────────

    /// Phát ra khi inbound SWIFT được settle và YOUR_TOKEN được mint với FX conversion
    event SwiftInboundConverted(
        bytes32 indexed uetrHash,
        address indexed beneficiary,
        string  originalCurrency,
        uint256 originalAmount,
        uint256 fxRate,
        uint256 grossAXVNAmount,
        uint256 netAXVNAmount,
        uint256 gasFeeAXVN
    );

    /// Phát ra khi người dùng burn YOUR_TOKEN để yêu cầu outbound SWIFT (multi-currency)
    event SwiftOutboundRequestedV2(
        bytes32 indexed uetrHash,
        address indexed sender,
        string  receiverBic,
        string  targetCurrency,   // Tiền nhận: "USD", "EUR", ...
        uint256 AXVNAmountBurned, // YOUR_TOKEN đã burn
        uint256 estimatedFiatAmount // Ước tính fiat nhận
    );

    event BridgeFeeUpdated(uint256 oldBps, uint256 newBps);
    event DefaultGasFeeUpdated(uint256 oldFee, uint256 newFee);
    event TreasuryVaultUpdated(address oldVault, address newVault);
    event RelayerChanged(address indexed oldRelayer, address indexed newRelayer);

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyRelayer() {
        require(msg.sender == oracleRelayer, "YOUR_TOKEN: Unauthorized Relayer");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "YOUR_TOKEN: Only Owner");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    constructor(
        address _YOUR_TOKENToken,
        address _oracleRelayer,
        address _treasuryVault
    ) {
        require(_YOUR_TOKENToken     != address(0), "YOUR_TOKEN: zero token");
        require(_oracleRelayer != address(0), "YOUR_TOKEN: zero relayer");
        require(_treasuryVault != address(0), "YOUR_TOKEN: zero treasury");

        YOUR_TOKENToken      = IERC20Mintable(_YOUR_TOKENToken);
        oracleRelayer  = _oracleRelayer;
        treasuryVault  = _treasuryVault;
        owner          = msg.sender;
    }

    // ─── INBOUND: SWIFT Fiat Ngoại Tệ → Mint YOUR_TOKEN (1 YOUR_TOKEN = 1 VND) ─────────

    /**
     * @notice Xử lý SWIFT Inbound ngoại tệ → Quy đổi FX → Trừ Gas Fee → Mint YOUR_TOKEN.
     *
     * Được gọi bởi Oracle Relayer (swift-chain-bridge) sau khi:
     *   1. swift-gateway xác nhận nhận điện MT103/pacs.008 inbound.
     *   2. FX Oracle lấy tỷ giá thực từ SBV / Vietcombank / Chainlink Feed.
     *
     * @param uetr              UUID v4 UETR của điện SWIFT
     * @param originalCurrency  Ký hiệu ngoại tệ gốc ("USD", "EUR", "JPY", ...)
     * @param originalAmount    Số tiền ngoại tệ (đơn vị: full unit, không chia decimals)
     * @param fxRate            Tỷ giá quy đổi sang VND (ví dụ: 25450 cho USD/VND)
     * @param beneficiary       Địa chỉ EVM ví nhận YOUR_TOKEN token
     * @param baseGasFeeYOUR_TOKEN    Phí gas cơ bản mạng lưới (đơn vị: YOUR_TOKEN wei = 1e18)
     *                          Nếu = 0 → dùng defaultBaseGasFeeAXVN
     */
    function settleInboundSwiftWithFX(
        string  calldata uetr,
        string  calldata originalCurrency,
        uint256          originalAmount,
        uint256          fxRate,
        address          beneficiary,
        uint256          baseGasFeeAXVN
    ) external onlyRelayer {
        require(beneficiary   != address(0), "YOUR_TOKEN: zero beneficiary");
        require(originalAmount > 0,          "YOUR_TOKEN: zero amount");
        require(fxRate         > 0,          "YOUR_TOKEN: zero fx rate");

        bytes32 uetrHash = keccak256(abi.encodePacked(uetr));
        require(swiftRecords[uetrHash].status == TxStatus.NONE, "YOUR_TOKEN: UETR already processed");

        // 1. Tính Gross YOUR_TOKEN = originalAmount × fxRate × 1e18
        //    (YOUR_TOKEN có 18 decimals, fxRate là integer, originalAmount là full unit ngoại tệ)
        uint256 grossAXVN = originalAmount * fxRate * 1e18;

        // 2. Tính phí Bridge (basis points) + Gas cơ bản
        uint256 effectiveGasBase = baseGasFeeAXVN == 0 ? defaultBaseGasFeeAXVN : baseGasFeeAXVN;
        uint256 percentFee       = (grossAXVN * bridgeFeeBps) / 10_000;
        uint256 totalFee         = effectiveGasBase + percentFee;

        require(grossAXVN > totalFee, "YOUR_TOKEN: Amount too small to cover gas fee");

        uint256 netYOUR_TOKEN = grossYOUR_TOKEN - totalFee;

        // 3. Ghi record
        swiftRecords[uetrHash] = SwiftRecord({
            uetrHash:         uetrHash,
            originalCurrency: originalCurrency,
            originalAmount:   originalAmount,
            fxRate:           fxRate,
            grossYOUR_TOKENAmount:  grossYOUR_TOKEN,
            gasFeeYOUR_TOKEN:       totalFee,
            netYOUR_TOKENAmount:    netYOUR_TOKEN,
            beneficiary:      beneficiary,
            status:           TxStatus.SETTLED,
            settledAt:        block.timestamp
        });

        totalYOUR_TOKENMinted  += netYOUR_TOKEN;
        totalFeeCollected += totalFee;

        // 4. Mint YOUR_TOKEN: Net amount cho beneficiary, fee về Treasury Vault
        YOUR_TOKENToken.mint(beneficiary, netYOUR_TOKEN);
        YOUR_TOKENToken.mint(treasuryVault, totalFee);

        emit SwiftInboundConverted(
            uetrHash,
            beneficiary,
            originalCurrency,
            originalAmount,
            fxRate,
            grossYOUR_TOKEN,
            netYOUR_TOKEN,
            totalFee
        );
    }

    // ─── OUTBOUND V2: Burn YOUR_TOKEN → SWIFT Fiat Ngoại Tệ ───────────────────────

    /**
     * @notice Người dùng burn YOUR_TOKEN để yêu cầu chuyển tiền SWIFT bằng ngoại tệ.
     *         Relayer sẽ tính toán lại fxRate và bắn điện MT103.
     *
     * @param uetr              UETR do client tạo (UUID v4)
     * @param receiverBic       BIC ngân hàng nhận tiền
     * @param targetCurrency    Tiền tệ nhận: "USD", "EUR", "JPY", ...
     * @param YOUR_TOKENAmountToBurn  Số YOUR_TOKEN muốn burn (đơn vị: wei = 1e18)
     * @param estimatedFiatAmt  Ước tính fiat nhận (Relayer sẽ confirm lại)
     */
    function requestOutboundSwiftV2(
        string  calldata uetr,
        string  calldata receiverBic,
        string  calldata targetCurrency,
        uint256          AXVNAmountToBurn,
        uint256          estimatedFiatAmt
    ) external {
        require(AXVNAmountToBurn > 0,         "YOUR_TOKEN: zero burn amount");
        require(bytes(receiverBic).length >= 8, "YOUR_TOKEN: invalid BIC");

        bytes32 uetrHash = keccak256(abi.encodePacked(uetr));
        require(swiftRecords[uetrHash].status == TxStatus.NONE, "YOUR_TOKEN: duplicate UETR");

        // Burn YOUR_TOKEN từ msg.sender (yêu cầu approve trước)
        YOUR_TOKENToken.burnFrom(msg.sender, AXVNAmountToBurn);

        swiftRecords[uetrHash] = SwiftRecord({
            uetrHash:         uetrHash,
            originalCurrency: targetCurrency,
            originalAmount:   estimatedFiatAmt,
            fxRate:           0,        // Relayer sẽ fill sau khi confirm FX
            grossAXVNAmount:  AXVNAmountToBurn,
            gasFeeAXVN:       0,
            netAXVNAmount:    AXVNAmountToBurn,
            beneficiary:      msg.sender,
            status:           TxStatus.PENDING,
            settledAt:        0
        });

        emit SwiftOutboundRequestedV2(
            uetrHash,
            msg.sender,
            receiverBic,
            targetCurrency,
            AXVNAmountToBurn,
            estimatedFiatAmt
        );
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// Tính toán YOUR_TOKEN net trước khi settle (preview)
    function previewInboundConversion(
        uint256 originalAmount,
        uint256 fxRate,
        uint256 baseGasFeeAXVN
    ) external view returns (
        uint256 grossAXVN,
        uint256 gasFee,
        uint256 netAXVN
    ) {
        uint256 effectiveBase = baseGasFeeAXVN == 0 ? defaultBaseGasFeeAXVN : baseGasFeeAXVN;
        grossAXVN = originalAmount * fxRate * 1e18;
        gasFee    = effectiveBase + (grossAXVN * bridgeFeeBps) / 10_000;
        netAXVN   = grossAXVN > gasFee ? grossAXVN - gasFee : 0;
    }

    function getRecord(string calldata uetr) external view returns (SwiftRecord memory) {
        return swiftRecords[keccak256(abi.encodePacked(uetr))];
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    function setBridgeFee(uint256 newBps) external onlyOwner {
        require(newBps <= 500, "YOUR_TOKEN: max 5%");
        emit BridgeFeeUpdated(bridgeFeeBps, newBps);
        bridgeFeeBps = newBps;
    }

    function setDefaultGasFee(uint256 newFee) external onlyOwner {
        emit DefaultGasFeeUpdated(defaultBaseGasFeeAXVN, newFee);
        defaultBaseGasFeeAXVN = newFee;
    }

    function setTreasuryVault(address newVault) external onlyOwner {
        require(newVault != address(0), "YOUR_TOKEN: zero address");
        emit TreasuryVaultUpdated(treasuryVault, newVault);
        treasuryVault = newVault;
    }

    function proposeRelayer(address newRelayer) external onlyOwner {
        require(newRelayer != address(0), "YOUR_TOKEN: zero address");
        pendingRelayer = newRelayer;
    }

    function acceptRelayer() external {
        require(msg.sender == pendingRelayer, "YOUR_TOKEN: not pending relayer");
        emit RelayerChanged(oracleRelayer, pendingRelayer);
        oracleRelayer  = pendingRelayer;
        pendingRelayer = address(0);
    }
}
