# AXIOLEDGER — Kế hoạch Kịch bản Grants Ecosystem
# Căn cứ: AXQGovernance v0.2.0 (Sepolia 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4)
# Phân tích từ contract thực tế: AXQGovernance.sol

---

## Thông số DAO thực tế (hardcoded trong contract)

| Tham số | Giá trị | Ý nghĩa |
|---|---|---|
| `VOTING_PERIOD` | 3 ngày | Thời gian bỏ phiếu |
| `TIME_LOCK_PERIOD` | 7 ngày | Thời gian chờ sau khi queue |
| `PROPOSAL_THRESHOLD` | 100,000 AXQ | Cần để tạo proposal |
| `QUORUM_VOTES` | 100,000 | Số phiếu quadratic tối thiểu để pass |
| `VETO_THRESHOLD` | 4/5 guardian | Số guardian cần để veto |
| Quadratic weight | sqrt(balance / 1e18) | Công thức tính phiếu |

---

## KỊCH BẢN 1 — Sepolia Testnet Faucet Grant (ETH từ Treasury)

**Mục tiêu:** DAO phân bổ SepoliaETH từ treasury cho deployer mới để fund operations.

### Điều kiện tiên quyết
- AXQGovernance nhận ETH vào treasury (ai đó send ETH trực tiếp vào contract)
- Proposer có ≥ 100,000 AXQ delegated tại `snapshotBlock - 1`
- rdTreasury (`0x77DF94665C671218beE29c7f4BD62aB083cb59B3`) đã `delegate()` → có voting power
  > ⚠️ Key này đã deprecated (bị ghi đè externally). Nếu cần thao tác trực tiếp, dùng `0xAf3D0febB24706912706660FB41D48Fc89548A53` thay thế.

### Quy trình thực thi

```
NGÀY 0: propose()
  target   = 0xAf3D0febB24706912706660FB41D48Fc89548A53  (AXQ_DEPLOYER mới)
  value    = 0.05 ether
  callData = ""  (bare ETH transfer, no calldata)
  desc     = "Grant: fund AXQ_DEPLOYER 0.05 ETH for Sepolia ops"

NGÀY 0-3: castVote() [Voting Period]
  rdTreasury vote: support=true
  weight = sqrt(150_000_000_000) = 387,298 votes >> QUORUM_VOTES ✅

NGÀY 3-10: Objection Window [Guardian có thể veto]
  Guardian Council review: 4/5 veto để block
  Nếu không veto → tiếp tục

NGÀY 3: queue(proposalId)
  Set p.queued = true
  executionTime = voteEnd + 7 days

NGÀY 10: execute(proposalId)
  call{ value: 0.05 ether }(0xAf3D0...)
  → AXQ_DEPLOYER nhận 0.05 ETH
```

### Solidity calldata để thực thi

```solidity
// Bước 1: Fund governance contract (ai đó send ETH)
// cast send 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4 --value 0.1ether --private-key $PK

// Bước 2: propose
// cast send 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4 \
//   "propose(address,uint256,bytes,string)" \
//   0xAf3D0febB24706912706660FB41D48Fc89548A53 \
//   50000000000000000 \
//   "0x" \
//   "Grant: fund AXQ_DEPLOYER 0.05 ETH for Sepolia ops" \
//   --private-key $SEPOLIA_DEPLOYER_PK

// Bước 3 (sau 3 ngày): castVote
// cast send 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4 \
//   "castVote(uint256,bool)" 1 true \
//   --private-key $SEPOLIA_DEPLOYER_PK

// Bước 4 (sau voting end): queue
// cast send 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4 \
//   "queue(uint256)" 1 \
//   --private-key $SEPOLIA_DEPLOYER_PK

// Bước 5 (sau 7 ngày timelock): execute
// cast send 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4 \
//   "execute(uint256)" 1 \
//   --private-key $SEPOLIA_DEPLOYER_PK
```

---

## KỊCH BẢN 2 — Developer Grant ($AXQ Token từ rdTreasury)

**Mục tiêu:** DAO phê duyệt grant $AXQ cho developer đóng góp SDK.

### Điều kiện tiên quyết
- rdTreasury (`0x77DF94665C671218beE29c7f4BD62aB083cb59B3`) hold 150B AXQ (genesis recipient)
  > ⚠️ Key này đã deprecated. Mọi thao tác governance dùng `0xAf3D0febB24706912706660FB41D48Fc89548A53` (`AXQ_DEPLOYER` ACTIVE).
- rdTreasury đã delegate voting power cho chính nó

### Quy trình

```
NGÀY 0: propose()
  target   = AXQToken (0x72eED93F91e30Bc3d15CbA6FF1E23Ba5f59f2f50)
  value    = 0
  callData = abi.encodeWithSignature(
               "transfer(address,uint256)",
               <developer_address>,
               1_000_000e18  // 1M AXQ
             )
  desc     = "Grant: 1M AXQ cho contributor @handle — @axioledger/ans-sdk v1.0"

Timeline: 3 ngày vote → 7 ngày timelock → execute
  → AXQToken.transfer(developer, 1_000_000e18) được gọi
```

### callData encoding

```bash
# Encode calldata
cast calldata "transfer(address,uint256)" \
  <DEVELOPER_ADDRESS> \
  1000000000000000000000000

# Output: 0xa9059cbb000000000000...
```

---

## KỊCH BẢN 3 — Protocol Treasury Sweep → R&D Fund

**Mục tiêu:** Định kỳ chuyển phí giao dịch tích lũy từ KPXRouter về rdTreasury.

### Quy trình

```
NGÀY 0: propose()
  target   = KPXRouterGateway (0xa513E6E4b8f2a923D98304ec87F64353C4D5C853)
  value    = 0
  callData = abi.encodeWithSignature("sweepFees(address)", rdTreasury)
  desc     = "Treasury: sweep accumulated KPX fees → rdTreasury Q3/2026"

Timeline: vote 3 ngày → timelock 7 ngày → execute sweepFees()
```

---

## KỊCH BẢN 4 — Emergency Deploy Fund (Bypass Timelock qua Guardian)

**Mục tiêu:** Cần ETH gấp cho CI/CD ops, không thể chờ 10 ngày.

### Giới hạn contract hiện tại
`emergencyWithdraw()` trong `AXQGovernance.sol` dòng 287–290:
```solidity
function emergencyWithdraw(address token, address to, uint256 amount) external {
    revert("not implemented - Phase 3");
}
```

**→ Chưa implement.** Cần proposal Phase 3 để build cơ chế này.

### Giải pháp tạm thời (testnet)
Dùng deployer wallet trực tiếp fund từ nguồn ngoài (faucet),
không đi qua governance — governance path chỉ phù hợp sau mainnet launch.

---

## KỊCH BẢN 5 — Mainnet Ecosystem Grant Program

**Mục tiêu:** Hệ thống grant chính thức sau mainnet, phân bổ từ 150B rdTreasury.

### Phân tầng grants

| Tier | Số lượng AXQ | Use case | Timeline |
|---|---|---|---|
| **Micro Grant** | 100K – 1M AXQ | Bug bounty, docs, minor tools | 1 proposal/tuần |
| **Standard Grant** | 1M – 10M AXQ | SDK package, dApp, integration | 1 proposal/tháng |
| **Major Grant** | 10M – 100M AXQ | L2 module, SWIFT connector, ZK circuit | Quarterly review |
| **Strategic** | > 100M AXQ | Partnership, exchange listing | Board approval + Guardian sign-off |

### Quy trình chuẩn hóa

```
Applicant → Submit proposal on-chain
  ↓ VOTING_PERIOD (3 ngày)
Community vote [quadratic]
  ↓ nếu pass QUORUM_VOTES
Guardian Objection Window (3-10 ngày)
  ↓ không bị 4/5 veto
TIME_LOCK (7 ngày) → queue()
  ↓ sau 7 ngày
execute() → transfer AXQ/ETH to grantee
```

### Code chuẩn bị Phase 3

Cần implement trong `AXQGovernance`:

```solidity
// Phase 3: Grant Registry
mapping(address => uint256) public grantReceived;
uint256 public constant MAX_GRANT_PER_ADDRESS = 100_000_000e18; // 100M AXQ

function emergencyWithdraw(
    address token,
    address to,
    uint256 amount
) external {
    // Yêu cầu: 4-of-5 guardians đã vetoVote trên proposal đặc biệt
    // Implementation pending Phase 3
}
```

---

## Tóm tắt Timeline thực tế

```
Testnet (hiện tại):
  ├── Faucet ngoài (sepoliafaucet.com) → 10 phút
  ├── Governance grant → 10 ngày (3 vote + 7 timelock)
  └── emergencyWithdraw → BLOCKED (Phase 3)

Mainnet (sau launch):
  ├── Micro grants → 10 ngày/cycle
  ├── Standard grants → 10 ngày/cycle
  └── Emergency → Phase 3 multisig (Guardian 4/5)
```

---

*Tài liệu tham chiếu: AXQGovernance.sol v0.2.0 · Sepolia 0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4*
*Kiến trúc sư trưởng — AXIOLEDGER Core Engineering — 03/09/2026*
