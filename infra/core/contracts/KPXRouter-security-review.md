# KPX Router Gateway — Security Review Checklist

> **File:** `core/contracts/KPXRouter-security-review.md`  
> **Contract:** `IKPXRouter.sol` — Cổng Định tuyến KINETOPROTOCOL  
> **Status:** 🔴 PENDING AUDIT — **KHÔNG deploy trước khi hoàn thành checklist này**  
> **Reviewers:** `GL-LEGAL-COMP-01` + `GL-ARCH-CORE-ENGINE` + External Auditor  
> **Ref:** Whitepaper §11.10 · §11.11

---

## A. AMM SWAP SECURITY

| # | Kiểm tra | Mô tả | Status |
|---|---|---|---|
| A1 | **Reentrancy Guard** | `swap()` phải có `nonReentrant` modifier. Kiểm tra callback vào attacker contract không gây re-enter | 🔴 Chưa kiểm tra |
| A2 | **Slippage Protection** | `amountOut >= minAmountOut` được enforce TRƯỚC khi transfer. Không sau. | 🔴 Chưa kiểm tra |
| A3 | **Deadline Enforcement** | `block.number <= deadline` check đầu tiên trong hàm, trước mọi state change | 🔴 Chưa kiểm tra |
| A4 | **Price Manipulation** | Pool price phải dùng TWAP (time-weighted) không phải spot price. Kiểm tra flash loan attack vector | 🔴 Chưa kiểm tra |
| A5 | **Integer Overflow** | Dùng Solidity 0.8.x built-in overflow check hoặc SafeMath cho tất cả phép tính amount | 🔴 Chưa kiểm tra |
| A6 | **Token Approval Race** | Không dùng `approve(spender, amount)` trực tiếp — dùng `safeIncreaseAllowance` | 🔴 Chưa kiểm tra |
| A7 | **ZK Proof Freshness** | zkProof phải có nonce/timestamp để tránh replay attack qua ZK verification | 🔴 Chưa kiểm tra |
| A8 | **VRQ Pre-check** | `isFlagged(msg.sender)` phải là check ĐẦU TIÊN — trước ZK verify, trước state read | 🔴 Chưa kiểm tra |

## B. CROSS-CHAIN BRIDGE SECURITY

| # | Kiểm tra | Mô tả | Status |
|---|---|---|---|
| B1 | **Double Spend Prevention** | `bridgeId` phải được đánh dấu `fulfilled` NGAY LẬP TỨC khi `bridgeIn()` thành công. Mapping `bytes32 => bool fulfilled` | 🔴 Chưa kiểm tra |
| B2 | **MPC Threshold Validation** | Verify đủ 2/3 MPC signatures độc lập. Không chấp nhận signature giống nhau 2 lần (anti-duplicate) | 🔴 Chưa kiểm tra |
| B3 | **Bridge Drain Protection** | `amount <= maxBridgeAmountPerTx`. Giới hạn tổng bridge trong 24h qua sliding window | 🔴 Chưa kiểm tra |
| B4 | **Chain Whitelist** | `targetChainId` phải nằm trong `supportedChains[]`. Revert ngay nếu không có | 🔴 Chưa kiểm tra |
| B5 | **Relayer Impersonation** | `bridgeIn()` chỉ được gọi từ địa chỉ trong `mpcRelayerSet`. Kiểm tra `EnumerableSet.contains()` | 🔴 Chưa kiểm tra |
| B6 | **Token Malicious Check** | `isFlagged(token)` phải được gọi trước khi bridge — ngăn bridge token độc hại/scam | 🔴 Chưa kiểm tra |
| B7 | **Deadline Cross-chain** | Deadline phải tính đến block time khác nhau giữa các chains. Dùng timestamp thay block number cho cross-chain | 🔴 Chưa kiểm tra |
| B8 | **Finality Risk** | Đợi đủ block confirmations trước khi unlock (ETH: 12 blocks, SOL: 32 slots, ARB: L1 finality) | 🔴 Chưa kiểm tra |

## C. RWA TREASURY SECURITY

| # | Kiểm tra | Mô tả | Status |
|---|---|---|---|
| C1 | **Collateral Ratio Check** | `axqCollateral >= rwaAmount * faceValuePerToken * 15 / 100`. Dùng oracle giá AXQ/USD tại thời điểm deposit | 🔴 Chưa kiểm tra |
| C2 | **Oracle Manipulation** | Oracle giá AXQ phải là TWAP >= 30 phút. Không dùng spot price — dễ bị flash loan manipulate | 🔴 Chưa kiểm tra |
| C3 | **Asset Verification** | `assetId` phải được multi-sig oracle (3/5) xác nhận trước khi `depositRWA()` chấp nhận | 🔴 Chưa kiểm tra |
| C4 | **Institutional KYC Gate** | ZK-Proof phải verify `identity_tier == "enterprise_validator"` — không phải retail user | 🔴 Chưa kiểm tra |
| C5 | **Yield Calculation** | `harvestAndBuyback()` tính yield chính xác theo `yieldRateBps * timeElapsed`. Kiểm tra rounding attack | 🔴 Chưa kiểm tra |
| C6 | **Maturity Enforcement** | Không cho withdraw trước `maturityDate` (hoặc có penalty fee nếu cho phép early withdraw) | 🔴 Chưa kiểm tra |
| C7 | **Buyback Slippage** | Khi buyback AXQ trên thị trường, phải có slippage limit để tránh bị frontrun | 🔴 Chưa kiểm tra |

## D. DARK POOL SECURITY

| # | Kiểm tra | Mô tả | Status |
|---|---|---|---|
| D1 | **Commitment Uniqueness** | `commitment` phải là unique. Mapping `bytes32 => bool exists` — revert nếu trùng | 🔴 Chưa kiểm tra |
| D2 | **Pedersen Binding** | Verify commitment scheme binding: không thể mở commitment với 2 giá trị khác nhau | 🔴 Chưa kiểm tra |
| D3 | **Expiry Enforcement** | `fillDarkPoolOrder()` revert nếu `block.number > order.expiryBlock` | 🔴 Chưa kiểm tra |
| D4 | **Matching Engine Auth** | `fillDarkPoolOrder()` chỉ địa chỉ `matchingEngine` được gọi. Multi-sig matching engine | 🔴 Chưa kiểm tra |
| D5 | **Frontrunning Prevention** | Commitment ẩn hoàn toàn. Verify ZK Match Proof không tiết lộ thông tin qua event logs | 🔴 Chưa kiểm tra |
| D6 | **Cancel Auth** | `cancelDarkPoolOrder()` chỉ order owner được gọi. Hoặc ai cũng gọi được nếu đã expired | 🔴 Chưa kiểm tra |
| D7 | **Spam Prevention** | `MIN_DARK_POOL_DEPOSIT` đủ lớn để tránh commitment spam làm đầy storage | 🔴 Chưa kiểm tra |

## E. GOVERNANCE & EMERGENCY

| # | Kiểm tra | Mô tả | Status |
|---|---|---|---|
| E1 | **No Admin Key** | Không có `owner` hay `admin` address có thể unilaterally pause/drain. Mọi action qua TreasuryDAO | 🔴 Chưa kiểm tra |
| E2 | **Emergency Pause Auth** | `emergencyPause()` chỉ TreasuryDAO multisig 5/7 — không phải deployer | 🔴 Chưa kiểm tra |
| E3 | **Unpause Governance** | `unpause()` cần `daoProposalId` đã được `ITreasuryDAO.isApproved()` xác nhận | 🔴 Chưa kiểm tra |
| E4 | **Scanner Update Lock** | `updateVRQScanner()` chỉ qua DAO vote. Timelock 48h sau DAO approval trước khi effective | 🔴 Chưa kiểm tra |
| E5 | **Upgrade Pattern** | Contract có upgradeable proxy không? Nếu có: proxy admin phải là TreasuryDAO, không phải EOA | 🔴 Chưa kiểm tra |
| E6 | **Event Completeness** | Tất cả state-changing functions đều emit event. Không có "silent state change" | 🔴 Chưa kiểm tra |

## F. INTEGRATION (VRQ + ZK-OBFT)

| # | Kiểm tra | Mô tả | Status |
|---|---|---|---|
| F1 | **ZK Circuit Version** | `IZKVerifier` phải verify đúng circuit version. Cần có `circuitVersion` check để tránh proof từ circuit cũ | 🔴 Chưa kiểm tra |
| F2 | **VRQ Blacklist Lag** | Nếu VRQ update blacklist, có độ trễ không? Router cần real-time check, không cache stale | 🔴 Chưa kiểm tra |
| F3 | **ZK Proof Malleability** | Groth16 proof có thể bị malleate. Dùng `keccak256(abi.encode(proof))` làm nonce check | 🔴 Chưa kiểm tra |
| F4 | **Cross-contract Reentrancy** | Khi gọi VRQ Scanner và ZK Verifier, ensure không có callback vào Router | 🔴 Chưa kiểm tra |

---

## DEPLOY DECISION GATE

```
┌─────────────────────────────────────────────────────────────┐
│  ĐIỀU KIỆN BẮT BUỘC trước khi cấp quyền deploy:            │
│                                                              │
│  ✅ Tất cả 30 checks trong A-F đều PASSED                   │
│  ✅ External audit report sạch 100% (zero Critical/High)    │
│  ✅ TreasuryDAO governance vote thông qua (majority)        │
│  ✅ 48h timelock sau DAO approval                           │
│  ✅ Testnet chạy ổn định ≥ 30 ngày không incident          │
│  ✅ GL-LEGAL-COMP-01 ký duyệt                               │
│  ✅ GL-ARCH-CORE-ENGINE ký duyệt                            │
│                                                              │
│  ❌ BẤT KỲ check nào FAILED = BLOCK DEPLOYMENT              │
└─────────────────────────────────────────────────────────────┘
```

**Current Status: 🔴 BLOCKED — 0/30 checks completed**

---

*AXIOLEDGER KPX Router Security Review v0.0.0*  
*"Không một dòng code tài chính nào được deploy trước khi qua đủ cổng kiểm tra." — Genesis Pact §11.11*
