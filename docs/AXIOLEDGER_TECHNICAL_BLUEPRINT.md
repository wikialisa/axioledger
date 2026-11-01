# QUY HOẠCH ĐỊNH DANH & LỘ TRÌNH PHÁT TRIỂN HỆ SINH THÁI AXIOLEDGER

> **Phiên bản:** 1.0 — Tài liệu triển khai chính thức
> **Ngày lập:** 03/09/2026
> **Phân loại:** TLP:WHITE — Công khai nội bộ đội ngũ kỹ sư

---

## 1. Quy Hoạch Scope NPM & Định Danh Web3 Monorepo

Cấu trúc scope chuẩn kết hợp tên thương hiệu độc quyền đảm bảo **100% khả năng khởi tạo và publish ngay lập tức mà không gặp rủi ro trùng lặp namespace**:

| Dự án | Ticker | Ý nghĩa | NPM Scope | GitHub Org | Dev Lead |
|---|---|---|---|---|---|
| **Axioledger** | **$AXQ** | AXioledger Quantum/Core | `@axioledger/*` | github.com/axioledger | `axq-core-dev` |
| **Valiprecision** | **$VPX** | ValiPrecision EXchange | `@valiprecision/*` | github.com/valiprecision | `vpx-node-lead` |
| **Sequentichain** | **$SQX** | SeQuentichain IndeX | `@sequentichain/*` | github.com/sequentichain | `sqx-kernel-dev` |
| **Kinetoprotocol** | **$KPX** | KinetoProtocol eXchange | `@kinetoprotocol/*` | github.com/kinetoprotocol | `kpx-defi-lead` |
| **Veraciphers** | **$VRQ** | VeRaciphers Quantum/Proof | `@veraciphers/*` | github.com/veraciphers | `vrq-cipher-dev` |

### Cấu Trúc Module Monorepo Theo Trụ Cột

| Trụ cột | Package | Chức năng |
|---|---|---|
| **$AXQ** | `@axioledger/core` | Hợp đồng thông minh lõi và quản trị |
| **$AXQ** | `@axioledger/ans-sdk` | Thư viện phân giải tên miền ANS `.axq` |
| **$VPX** | `@valiprecision/node-client` | SDK kết nối và xác thực node |
| **$SQX** | `@sequentichain/rollup-kit` | Bộ công cụ phát triển giao dịch tuần tự L2 |
| **$KPX** | `@kinetoprotocol/liquidity-engine` | Smart routing và AMM SDK |
| **$VRQ** | `@veraciphers/snark-prover` | Mô-đun tạo và kiểm chứng ZK-Proof |

---

## 2. Kiến Trúc Hạ Tầng DNS Gateway Phân Giải ANS

Luồng phân giải tên miền tùy chỉnh (`.axq`, `.vpx`, `.sqx`, `.kpx`, `.vrq`):

```
              [Client / Web Browser / dApp]
                           │
               (1) Query *.axq, *.vpx,...
                           ▼
           [CoreDNS / Unbound Server (Port 53)]
                           │
    ┌──────────────────────┴──────────────────────┐
    │ Custom DNS Plugin / Internal Forwarder      │
    ▼                                             ▼
[ANS Local Resolver Gateway]          [Public Upstream DNS]
  (Port 8053 / REST / JSON-RPC)         (1.1.1.1 / 8.8.8.8)
    │
    ├─► [Redis Cache] (TTL: 60s)
    ├─► [PostgreSQL Metadata DB]
    └─► [Blockchain Node (Anvil/Geth)]
          • ANSRegistry Contract
          • PublicResolver Contract
          • ReverseRegistrar Contract
```

### Phân Tầng Dịch Vụ Server

| Tầng | Công nghệ | Chức năng |
|---|---|---|
| DNS Capture | CoreDNS port `53` | Điều hướng TLD tùy chỉnh → Gateway port `8053` |
| Routing Gateway | Nginx Reverse Proxy | Ánh xạ `*.axq.domain.com` → IPFS/Web3 |
| ANS Core Resolver | Node.js / Go | Namehash, đọc bản ghi đa chuỗi, IPFS ContentHash |
| Caching & Storage | Redis + PostgreSQL | Bảng ánh xạ định danh, độ trễ < 5ms |
| Smart Contract Local | Foundry Anvil | `ANSRegistry`, `PublicResolver`, `ReverseRegistrar` |

### Cấu Hình CoreDNS (`Corefile`)

```corefile
axq:53 vpx:53 sqx:53 kpx:53 vrq:53 {
    log
    errors
    forward . 127.0.0.1:8053 {
        force_tcp
    }
    cache 30
}

. {
    forward . 1.1.1.1 8.8.8.8
    cache 300
    reload
}
```

### Schema PostgreSQL

```sql
CREATE TABLE ans_domains (
    node_hash       VARCHAR(66)  PRIMARY KEY,     -- Keccak-256 Namehash
    domain_name     VARCHAR(255) NOT NULL,         -- e.g. "alice.axq"
    tld             VARCHAR(10)  NOT NULL,          -- axq, vpx, sqx, kpx, vrq
    owner_address   VARCHAR(42)  NOT NULL,
    resolver_address VARCHAR(42) NOT NULL,
    ttl             INT DEFAULT 3600,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ans_crypto_records (
    id              SERIAL PRIMARY KEY,
    node_hash       VARCHAR(66) REFERENCES ans_domains(node_hash) ON DELETE CASCADE,
    coin_symbol     VARCHAR(10) NOT NULL,           -- AXQ, VPX, ETH, BTC, SOL...
    coin_type       INT NOT NULL,                   -- SLIP-0044 standard
    wallet_address  VARCHAR(128) NOT NULL,
    UNIQUE (node_hash, coin_symbol)
);

CREATE TABLE ans_text_records (
    id              SERIAL PRIMARY KEY,
    node_hash       VARCHAR(66) REFERENCES ans_domains(node_hash) ON DELETE CASCADE,
    record_key      VARCHAR(50) NOT NULL,           -- 'contenthash', 'url', 'avatar', 'zk_did_proof'
    record_value    TEXT NOT NULL,
    UNIQUE (node_hash, record_key)
);
```

### REST API Gateway

| Endpoint | Method | Input | Output | Mục đích |
|---|---|---|---|---|
| `/api/v1/resolve` | GET | `?name=alice.axq` | `{ name, owner, records }` | Phân giải toàn diện danh tính |
| `/api/v1/addr` | GET | `?name=treasury.axq&symbol=AXQ` | `{ address }` | Lấy địa chỉ ví nhanh |
| `/api/v1/reverse` | GET | `?address=0x892a...` | `{ primary_name }` | Reverse lookup |
| `/api/v1/zk-verify` | POST | `{ name, proof }` | `{ valid, identity_tier }` | Xác thực ZK-Proof DID |

---

## 3. Tokenomics — 5-Token Decoupled Model

```
+============================================================================+
|                        HỆ SINH THÁI AXIOLEDGER                            |
+============================================================================+
|                                                                            |
|  [ $AXQ: Settlement & Governance ] ──► DAO, cross-chain security          |
|          │                                                                 |
|          ├──► [ $VPX: Consensus ]     ──► Validator staking, no vote fee  |
|          ├──► [ $SQX: Execution ]     ──► Gas < $0.0005, no 7-day lock    |
|          ├──► [ $KPX: Liquidity Hub ] ──► Unified TVL, no bridge exploit  |
|          └──► [ $VRQ: Privacy & DID ] ──► ZK proof, supply chain shield   |
|                                                                            |
+============================================================================+
```

### Ma Trận Utility

| Token | Trụ Cột | Vai Trò Cốt Lõi | Vấn Đề Đã Giải Quyết |
|---|---|---|---|
| **$AXQ** | Axioledger Hub | Native Reserve, Settlement, DAO | Tách gánh nặng tính toán khỏi governance token |
| **$VPX** | Valiprecision | Validator Staking, Slashing, Block Rewards | Loại bỏ voting fee tốn kém (cf. Solana); pool 300+ nodes |
| **$SQX** | Sequentichain | Micro-gas < $0.0005, Sequencer Staking, Fee Burn | Triệt tiêu 7-ngày withdrawal (Hybrid Optimistic-ZK) |
| **$KPX** | Kinetoprotocol | Cross-chain Routing, veKPX Fee Sharing | Unified TVL, loại bỏ bridge bọc token rủi ro |
| **$VRQ** | Veraciphers | ZK-Proof, ZK-DID, Prover DePIN Rewards | Giảm 85% chi phí ZK; NPM supply chain checksum |

### Phân Bổ Nguồn Cung

| Hạng Mục | $AXQ (Hub) | $VPX & $SQX | $KPX & $VRQ | Vesting |
|---|---|---|---|---|
| **Tổng cung (Max)** | **500,000,000** | **1,000,000,000** | **2,000,000,000** | Khóa ≥ 12 tháng |
| Cơ chế cung | Cố định (0% lạm phát) | Giảm dần (4.5%/năm) | Giảm phát (burn từ fees) | Trả tuyến tính 36–48 tháng |
| Node Staking / LP | 10% | 40% | 35–40% | Phân phối tự động theo Epoch |
| Ecosystem Treasury | 25% | 20% | 20% | DAO governance vote |
| Core Dev | 15% | 15% | 15% | Cliff 12 tháng, trả 48 tháng |
| Strategic / Sales | 25% | 17% | 20% | Cliff 12 tháng, trả 36 tháng |
| Liquidity Bootstrap | 25% | 8% | 8–10% | Khóa ban đầu tạo độ sâu thị trường |

---

## 4. Đặc Tả Kỹ Thuật L2 Sequencer ($SQX) & DeFi Engine ($KPX)

### Sequentichain L2 ($SQX)

- **Compression Engine:** Zstandard (Zstd) cho CallData/Blob → giảm 70% payload trước khi commit lên Settlement Layer
- **Decentralized Sequencer Pool:** VRF chọn Sequencer theo lượng $SQX stake → triệt tiêu MEV manipulation
- **Fast Withdrawal:** Kích hoạt ZK-Proof tức thì qua $VRQ → loại bỏ 7-ngày withdrawal window

### Kinetoprotocol AMM ($KPX)

- **Sequencer-Level Native AMM:** Logic swap tích hợp trực tiếp vào State Machine L2 → phí tiệm cận $0
- **Unified TVL:** Pool gốc đặt tại Hub ($AXQ), L2 giữ Virtual Balances → không phân mảnh thanh khoản

---

## 5. Lộ Trình Triển Khai (Parallel Sprints)

| Nhóm | Mục Tiêu | Deliverables | Timeline |
|---|---|---|---|
| **Nhóm 1: Core Hub & Consensus ($AXQ, $VPX)** | Settlement ledger, DAO contracts, Validator Node | `@axioledger/core`, `@valiprecision/node-client`, CometBFT engine | Sprint 1–3 (Tuần 1–6) |
| **Nhóm 2: L2 Sequencer & DeFi ($SQX, $KPX)** | L2 Sequencer Zstd, AMM Smart Router | `@sequentichain/rollup-core`, `@kinetoprotocol/liquidity-engine`, `@kpx-labs/router` | Sprint 1–4 (Tuần 1–8) |
| **Nhóm 3: ZK-Privacy & ANS Gateway ($VRQ, UI)** | ZK-DID Prover, Checksum Registry, CoreDNS Plugin | `@veraciphers/snark-prover`, `@axioledger/ans-sdk`, CoreDNS Plugin, Postgres/Redis | Sprint 2–4 (Tuần 3–8) |

---

## 6. Developer UX & An Toàn Chuỗi Cung Ứng

- **CLI:** `npx @axioledger/cli create-dapp --template am-router` — tự động kéo package chuẩn
- **TypeScript Strict:** Định nghĩa kiểu chặt chẽ cho toàn bộ API và ZK Proof Parameters
- **NPM Supply Chain Shield:** ZK-Proof ($VRQ) đối chiếu hash package trước khi cài — loại bỏ typosquatting
- **Local Mock:** Giả lập 5 token + ANS Gateway trên máy local qua một lệnh duy nhất

---

## 7. Ánh Xạ Golem Factory → Axioledger Monorepo

Bảng mapping từ thư viện mã nguồn mở lõi **Golem Factory** sang scope package tương ứng trong monorepo:

| Golem Library | Vai Trò Kỹ Thuật | Axioledger Package | Trụ Cột |
|---|---|---|---|
| [golem-js](https://github.com/golemfactory/golem-js) / [yapapi](https://github.com/golemfactory/yapapi) | SDK kết nối, điều phối & gửi tác vụ P2P | `@axioledger/sdk` / `@axq-protocol/core` | **$AXQ** — Lõi SDK điều phối dApp, phân giải ANS |
| [ya-client](https://github.com/golemfactory/ya-client) / [ya-runtime-vm](https://github.com/golemfactory/ya-runtime-vm) | Client Daemon REST API & VM execution | `@valiprecision/node-client` / `@vpx-network/consensus` | **$VPX** — Môi trường xác thực node, CometBFT |
| [ya-relay](https://github.com/golemfactory/ya-relay) / [goth](https://github.com/golemfactory/goth) | P2P relay & distributed test framework | `@sequentichain/sequencer` / `@sqx-chain/rollup` | **$SQX** — Lưới Sequencer L2, batch Zstd |
| [erc20_payment_lib](https://github.com/golemfactory/erc20_payment_lib) / [gnt2](https://github.com/golemfactory/gnt2) | On-chain/Off-chain ERC20 payment | `@kinetoprotocol/amm` / `@kpx-labs/router` | **$KPX** — Routing thanh khoản, fee sharing $veKPX |
| [ya-runtime-wasi](https://github.com/golemfactory/ya-runtime-wasi) / [yagna-zksync](https://github.com/golemfactory/yagna-zksync) | WASM sandbox & ZK cryptographic attestation | `@veraciphers/zk-proof` / `@vrq-crypto/core` | **$VRQ** — ZK-Proof isolate, DID checksum |

---

## 8. Cấu Hình `package.json` Tham Chiếu Monorepo

```json
{
  "name": "@axioledger/monorepo",
  "private": true,
  "workspaces": [
    "packages/*"
  ],
  "dependencies": {
    "@axq-protocol/core":      "workspace:*",
    "@vpx-network/consensus":  "workspace:*",
    "@sqx-chain/rollup":       "workspace:*",
    "@kpx-labs/router":        "workspace:*",
    "@vrq-crypto/core":        "workspace:*"
  }
}
```

---

## 9. Trạng Thái Triển Khai Hiện Tại (Sepolia Testnet)

> Đối chiếu với lộ trình trên, cập nhật ngày 03/09/2026:

| Contract | Địa Chỉ Sepolia | Trạng Thái |
|---|---|---|
| AXQToken | `0x72eED93F91e30Bc3d15CbA6FF1E23Ba5f59f2f50` | ✅ Live + Verified + Genesis |
| AXQGovernance | `0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4` | ✅ Live + Verified |
| AXQVestingVault | `0x29E5E815211De8f5f842751CD4de83e00034bD0a` | ✅ Live + Verified |
| ANSRegistry | `0xC939c62cfFB905aa9fF00B90908286c31f46B18c` | ✅ Live + Verified |
| KPXRouterGateway | `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853` | ✅ Live |
| VPXOracleFeed | *(deploy trước)* | ✅ Live |
| VRQPasskeyValidator | *(deploy trước)* | ✅ Live |

**Deployer active:** `0xAf3D0febB24706912706660FB41D48Fc89548A53` (funded 0.05 ETH)
**Guardian Council:** GUARDIAN_0–2 có ví riêng, GUARDIAN_3–4 pending

---

*Tài liệu này là căn cứ kỹ thuật chính thức cho toàn bộ đội ngũ phát triển AXIOLEDGER.*
*Kiến trúc sư trưởng — AXIOLEDGER Core Engineering — 03/09/2026*
