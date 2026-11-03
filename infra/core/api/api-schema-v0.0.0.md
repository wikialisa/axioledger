# AXIOLEDGER — API Schema v0.0.0 (Genesis Pact Edition)

> **Gateway:** `https://api.axioledger.axq/v1/`  (bind: `192.168.0.47:443`)
> **Auth:** ZK-DID Bearer Token (Header: `Authorization: Bearer <zk-did-token>`)
> **TLS:** 1.3 only — cert: `/mnt/q/root/Ubuntu-24.04/rootfs/root/ssl/server.crt`
> **Version:** `v0.0.0` — Genesis. Không tương thích ngược với phiên bản tương lai cho đến `v1.0.0`.

---

## Mục lục

1. [Hub $AXQ — `/core/`](#1-hub-axq----core)
2. [VALIPRECISION $VPX — `/vp/`](#2-valiprecision-vpx----vp)
3. [SEQUENTICHAIN $SQX — `/sqx/`](#3-sequentichain-sqx----sqx)
4. [KINETOPROTOCOL $KPX — `/kpx/`](#4-kinetoprotocol-kpx----kpx)
5. [VERACIPHERS $VRQ — `/vrq/`](#5-veraciphers-vrq----vrq)
6. [Mã lỗi chung (Error Codes)](#6-mã-lỗi-chung)

---

## 1. Hub $AXQ — `/core/`

### `POST /core/treasury/propose`

Tạo đề xuất quản trị DAO gửi lên Treasury on-chain.

**Request Body:**
```json
{
  "proposer_did": "did:axq:0xABC...123",
  "title": "Điều chỉnh hệ số κ trong phương trình phát thải",
  "description": "Tăng κ từ 0.03 lên 0.035 để phản ứng với tốc độ tăng TVL_RWA",
  "payload": {
    "target": "emission_engine",
    "param": "kappa",
    "value": "0.035"
  },
  "voting_period_hours": 72
}
```

**Response `201`:**
```json
{
  "proposal_id": "prop-00001",
  "status": "pending_vote",
  "zk_proof_hash": "0xDEF...456",
  "voting_ends_at": "2025-01-10T00:00:00Z"
}
```

---

### `GET /core/metrics/inflation`

Truy xuất thông số phát thải và tốc độ đốt hiện tại.

**Response `200`:**
```json
{
  "timestamp": "2025-01-07T12:00:00Z",
  "emission_rate_axq_per_block": "142857.14",
  "burn_rate_axq_per_block": "89000.00",
  "net_inflation": "53857.14",
  "delta_tvl_rwa_usd": "150000000",
  "deflation_crossover_eta": "Year 3 (estimated)",
  "kappa": "0.03",
  "mu": "0.00001"
}
```

---

## 2. VALIPRECISION $VPX — `/vp/`

### `GET /vp/validators/reputation`

Truy xuất danh sách chỉ số Reputation $R_i$ của tất cả Validator đang hoạt động.

**Query Params:**
| Param | Type | Mô tả |
| :---- | :---- | :---- |
| `limit` | int | Số lượng kết quả (default: 100, max: 1000) |
| `sort` | string | `reputation_desc` (default) \| `stake_desc` |
| `status` | string | `active` \| `slashed` \| `all` |

**Response `200`:**
```json
{
  "epoch": 1042,
  "validators": [
    {
      "pubkey": "VPX1abc...xyz",
      "stake_vpx": "500000000",
      "uptime_percent": 99.97,
      "bandwidth_mbps": 1200,
      "reputation_score": 0.9821,
      "voting_power": "490050000",
      "status": "active"
    }
  ],
  "nakamoto_coefficient": 127,
  "total_validators": 5234
}
```

---

### `POST /vp/consensus/zk-proof`

Leader Validator gửi bằng chứng ZK-SNARKs tổng hợp sau khi đạt ngưỡng 2/3 VP.

**Request Body:**
```json
{
  "epoch": 1042,
  "micro_epoch": 7,
  "zk_proof_bytes": "BASE64_ENCODED_284_BYTES",
  "aggregated_signatures_count": 3481,
  "total_vp_voted": "8234500000",
  "total_vp_network": "11200000000",
  "block_hash": "0xBLOCK...HASH"
}
```

**Response `200`:**
```json
{
  "accepted": true,
  "finality_slot": 1042007,
  "settlement_tx": "0xSETTLE...TX",
  "verification_time_ms": 12
}
```

---

## 3. SEQUENTICHAIN $SQX — `/sqx/`

### `POST /sqx/tx/batch`

Gửi một cụm giao dịch (batch) lên L2 SVM Rollup qua Zero-Copy Network.

**Request Body:**
```json
{
  "transactions": [
    {
      "from": "0xSENDER",
      "to": "0xRECIPIENT",
      "amount": "1000000",
      "token": "AXQ",
      "mode": "confidential",
      "nonce": 42,
      "signature": "0xSIG..."
    }
  ],
  "batch_mode": "atomic",
  "gas_token": "USDC",
  "paymaster": "0xPAYMASTER"
}
```

**Response `202`:**
```json
{
  "batch_id": "batch-sqx-0000012345",
  "status": "queued",
  "estimated_finality_minutes": 2.4,
  "zk_rollup_proof_eta": "2025-01-07T12:03:00Z"
}
```

---

### `GET /sqx/rollup/state`

Truy xuất trạng thái hiện tại của L2 Rollup.

**Response `200`:**
```json
{
  "l2_block_height": 8834201,
  "l1_settlement_block": 104231,
  "pending_tx_count": 14200,
  "tps_current": 412000,
  "tps_peak_24h": 601000,
  "last_zk_proof_at": "2025-01-07T11:58:42Z",
  "sequencer_leader": "SQX1leader...pubkey",
  "finality_status": "healthy"
}
```

---

## 4. KINETOPROTOCOL $KPX — `/kpx/`

### `POST /kpx/pool/swap`

Thực thi lệnh hoán đổi cross-chain qua AMM Pool với Anti-slippage routing.

**Request Body:**
```json
{
  "from_chain": "axioledger",
  "to_chain": "ethereum",
  "from_token": "AXQ",
  "to_token": "USDC",
  "amount_in": "10000000",
  "slippage_tolerance_bps": 30,
  "recipient": "0xETH_RECIPIENT",
  "zk_did": "did:axq:0xUSER...DID"
}
```

**Response `200`:**
```json
{
  "swap_id": "kpx-swap-00098765",
  "amount_out_estimated": "9985.12",
  "price_impact_bps": 4,
  "route": ["AXQ/USDC-AMM", "AXIO-ETH-BRIDGE"],
  "bridge_fee_axq": "0.50",
  "status": "executing",
  "estimated_completion_seconds": 180
}
```

---

### `GET /kpx/rwa/vault`

Truy xuất danh sách tài sản thực (RWA) đang được thế chấp trong Treasury.

**Query Params:** `institution_did`, `asset_type` (`bond`|`cd`|`gov_debt`|`all`), `limit`

**Response `200`:**
```json
{
  "total_tvl_usd": "1250000000",
  "total_locked_axq": "187500000000",
  "assets": [
    {
      "asset_id": "rwa-bond-001",
      "institution_did": "did:axq:INST...KYC",
      "asset_type": "government_bond",
      "face_value_usd": "50000000",
      "locked_axq_collateral": "7500000000",
      "maturity_date": "2030-01-01",
      "yield_percent": 4.5
    }
  ]
}
```

---

## 5. VERACIPHERS $VRQ — `/vrq/`

### `POST /vrq/did/verify`

Xác thực KYC ẩn danh — trả về kết quả pass/fail mà không lộ danh tính thực.

**Request Body:**
```json
{
  "zk_proof": "BASE64_ZK_PROOF",
  "nullifier_hash": "0xNULLIFIER",
  "merkle_root": "0xMERKLE_ROOT",
  "compliance_level": "kyc_aml_fatf",
  "jurisdiction": "VN"
}
```

**Response `200`:**
```json
{
  "verified": true,
  "compliance_level": "kyc_aml_fatf",
  "did_issued": "did:axq:0x...HASH",
  "expires_at": "2026-01-07T00:00:00Z",
  "sanctions_check": "clean",
  "pii_exposed": false
}
```

---

### `GET /vrq/scanner/blacklist`

Truy xuất dữ liệu blacklist từ Supply Chain Scanner (npm/DApp/contract addresses).

**Query Params:** `type` (`npm`|`contract`|`domain`|`all`), `severity` (`critical`|`high`|`all`), `limit`

**Response `200`:**
```json
{
  "last_scan_at": "2025-01-07T11:55:00Z",
  "total_entries": 28451,
  "entries": [
    {
      "id": "bl-npm-004421",
      "type": "npm",
      "identifier": "axio1edger-sdk",
      "severity": "critical",
      "reason": "Typosquatting — exfiltrates private keys",
      "detected_at": "2025-01-06T08:12:00Z",
      "blocked_transactions": 1204
    }
  ]
}
```

---

## 6. Mã Lỗi Chung

| HTTP Code | Error Code | Mô tả |
| :---- | :---- | :---- |
| `400` | `INVALID_ZK_PROOF` | Bằng chứng ZK-DID không hợp lệ hoặc đã hết hạn |
| `400` | `INSUFFICIENT_COLLATERAL` | Số dư $AXQ không đủ tỷ lệ bảo chứng 15% |
| `401` | `AUTH_REQUIRED` | Thiếu hoặc sai Bearer Token |
| `403` | `SANCTIONS_MATCH` | Địa chỉ bị chặn bởi OFAC/AML blacklist |
| `403` | `COMPLIANCE_FAILED` | Không pass KYC theo jurisdiction yêu cầu |
| `409` | `NONCE_REPLAY` | Giao dịch bị phát hiện tái sử dụng nonce |
| `429` | `RATE_LIMITED` | Vượt ngưỡng rate limit tại Gateway |
| `503` | `SEQUENCER_UNAVAILABLE` | L2 Sequencer đang trong quá trình bầu Leader mới |

---

> **File:** `core/api/api-schema-v0.0.0.md`
> **Đồng bộ với:** `docs/Whitepaper AXIOLEDGER ($AXQ).md` §11.5
> **Maintainer:** Axioledger Core Maintainer <315885655+davictran76@users.noreply.github.com>

---

## ADDENDUM — KPX Router Endpoints (v0.0.0-kpx)

> Thêm vào tại Genesis Block `2026-08-31T09:41:34Z`  
> Ref: Whitepaper §11.11 · `core/contracts/IKPXRouter.sol`

### `GET /kpx/router/quote`

Tính toán output swap trước khi thực thi (read-only).

**Query params:** `tokenIn`, `tokenOut`, `amountIn`

**Response `200`:**
```json
{
  "token_in":        "0x...",
  "token_out":       "0x...",
  "amount_in":       "1000000000000000000",
  "amount_out":      "998234567890123456",
  "price_impact_bps": 12,
  "route_path":      ["0xPoolA", "0xPoolB"],
  "valid_until_block": 1234590
}
```

---

### `POST /kpx/router/swap`

Thực thi AMM swap với ZK-Proof bắt buộc.

**Request Body:**
```json
{
  "token_in":       "0x...",
  "token_out":      "0x...",
  "amount_in":      "1000000000000000000",
  "min_amount_out": "990000000000000000",
  "deadline_block": 1234600,
  "zk_proof":       "0x...",
  "zk_pub_inputs":  ["0x1234...", "0x5678..."]
}
```

**Response `200`:**
```json
{
  "tx_hash":         "0x...",
  "amount_out":      "997123456789000000",
  "actual_slip_bps": 8,
  "zk_proof_hash":   "0x...",
  "block_height":    1234589
}
```

**Error `403`** (VRQ Scanner flag):
```json
{ "error": "VRQ_FLAGGED", "reason": "Caller address flagged by Supply Chain Scanner" }
```

---

### `POST /kpx/bridge/out`

Khởi tạo bridge tài sản sang chain khác.

**Request Body:**
```json
{
  "token":           "0x...",
  "amount":          "5000000000000000000",
  "target_chain_id": 42161,
  "recipient":       "0x000000000000000000000000RecipientAddressHere",
  "deadline_block":  1234700,
  "zk_proof":        "0x...",
  "zk_pub_inputs":   ["0x..."]
}
```

**Response `201`:**
```json
{
  "bridge_id":   "0xabc...def",
  "status":      "PENDING",
  "estimated_completion_blocks": 24,
  "mpc_relayers_required": 2
}
```

---

### `GET /kpx/bridge/status`

Truy vấn trạng thái bridge operation.

**Query param:** `bridge_id`

**Response `200`:**
```json
{
  "bridge_id":   "0xabc...def",
  "status":      "IN_FLIGHT",
  "source_chain": 31337,
  "target_chain": 42161,
  "signatures_collected": 2,
  "signatures_required":  2,
  "updated_at":  "2026-09-01T10:00:00Z"
}
```

---

### `POST /kpx/rwa/deposit`

Gửi RWA vào Treasury (chỉ institutional tier).

**Request Body:**
```json
{
  "asset_id":       "0xRWA_BOND_VNGOV_2026_001",
  "rwa_amount":     "1000000000000000000000",
  "axq_collateral": "150000000000000000000",
  "zk_proof":       "0x...",
  "zk_pub_inputs":  ["0x..."]
}
```

**Response `201`:**
```json
{
  "rwa_tokens_minted": "1000000000000000000000",
  "axq_locked":        "150000000000000000000",
  "collateral_ratio":  "15.00%",
  "asset_id":          "0xRWA_BOND_VNGOV_2026_001",
  "tx_hash":           "0x..."
}
```

---

### `POST /kpx/darkpool/order`

Đặt lệnh ẩn vào Dark Pool (institutional tier).

**Request Body:**
```json
{
  "commitment":    "0xPedersenCommitment...",
  "expiry_blocks": 100,
  "zk_proof":      "0x...",
  "zk_pub_inputs": ["0x..."]
}
```

**Response `201`:**
```json
{
  "order_id":     "0xOrderId...",
  "commitment":   "0xPedersenCommitment...",
  "expiry_block": 1234689,
  "status":       "PENDING_MATCH"
}
```
