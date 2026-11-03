# Open Financial Infrastructure — Architecture

> **Dành cho:** Trường học · Chính phủ · Doanh nghiệp · Nhà phát triển toàn cầu  
> **Giấy phép:** MIT (packages/ui-kit, packages/types, packages/config, packages/core-sdk)  
> AGPL-3.0 (apps/*)  
> BSL-1.1 (programs/*, packages/swift-adapter, packages/sdk-swift)  
> **Cấu hình danh tính:** `brand.config.json` + `programs/program-ids.config.json`

---

## Tầm nhìn thiết kế

Hệ thống được chia thành **4 tầng độc lập**, mỗi tầng có thể triển khai riêng lẻ hoặc kết hợp:

```
┌─────────────────────────────────────────────────────────────────────┐
│  TẦNG 4 — GIAO DIỆN NGƯỜI DÙNG  (apps/)                            │
│  Next.js PWA · Responsive · WCAG AA · Localizable                  │
├─────────────────────────────────────────────────────────────────────┤
│  TẦNG 3 — DỊCH VỤ BACKEND       (services/)                        │
│  Node.js · REST/WS · Microservices · Docker-ready                  │
├─────────────────────────────────────────────────────────────────────┤
│  TẦNG 2 — THƯ VIỆN DÙNG CHUNG   (packages/)                        │
│  TypeScript SDK · Design System · Shared Types                     │
├─────────────────────────────────────────────────────────────────────┤
│  TẦNG 1 — HỢP ĐỒNG THÔNG MINH   (programs/)                        │
│  Solana Anchor · EVM Solidity · Biến số Programme ID               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Sơ đồ cây thư mục — Toàn bộ hệ sinh thái

```
monorepo/
│
├── brand.config.json              ← Điền tên tổ chức, domain, token symbol
├── programs/
│   └── program-ids.config.json   ← Điền Solana Program IDs + EVM addresses
│
│
├── ══════════════════════════════════════════════════════════════════
│   TẦNG 1: HỢP ĐỒNG THÔNG MINH
│   Ai dùng: Trường học (nghiên cứu), Doanh nghiệp (sản xuất), Chính phủ (CBDC)
│   ══════════════════════════════════════════════════════════════════
│
├── programs/
│   │
│   ├── p2p-escrow/               ← Solana Anchor · Giao dịch ngang hàng
│   │   └── src/lib.rs            │  make_offer · take_offer · cancel_offer
│   │                             │  declare_id!(env!("PROGRAM_ID_P2P_ESCROW", "111..."))
│   │
│   ├── mint-governance/          ← Solana Anchor · Phát hành token có kiểm soát
│   │   └── src/lib.rs            │  initialize · add_to_whitelist · mint · burn
│   │                             │  declare_id!(env!("PROGRAM_ID_MINT_GOVERNANCE", "111..."))
│   │
│   ├── amm-swap/                 ← Solana Anchor · AMM x*y=k với fee tier
│   │   └── src/lib.rs            │  initialize_pool · swap · add_liquidity · remove_liquidity
│   │                             │  declare_id!(env!("PROGRAM_ID_AMM_SWAP", "111..."))
│   │
│   ├── treasury-rbs/             ← Solana Anchor · Kho bạc DAO + Bình ổn giá
│   │   └── src/lib.rs            │  initialize · update_bounds · deposit · rebalance
│   │                             │  declare_id!(env!("PROGRAM_ID_TREASURY_RBS", "111..."))
│   │
│   ├── swift-bridge/             ← Cầu nối SWIFT ↔ On-chain
│   │   ├── evm/
│   │   │   ├── SwiftBridge.sol   │  EVM: createEscrow · releaseEscrow · refundEscrow
│   │   │   └── SwiftBridgeV2.sol │  EVM: FX Oracle tích hợp tỷ giá SBV
│   │   └── solana/
│   │       └── src/lib.rs        │  Solana: lock_funds · release · refund
│   │                             │  declare_id!(env!("PROGRAM_ID_SWIFT_BRIDGE", "111..."))
│   │
│   └── program-ids.config.json   ← Source of truth cho tất cả program/contract addresses
│
│
├── ══════════════════════════════════════════════════════════════════
│   TẦNG 2: THƯ VIỆN DÙNG CHUNG
│   Ai dùng: Nhà phát triển (npm install), Trường học (giảng dạy SDK)
│   ══════════════════════════════════════════════════════════════════
│
├── packages/
│   │
│   ├── config/                   ← PROGRAM_IDS · EVM_CONTRACTS · RPC endpoints
│   │   └── src/index.ts          │  Tất cả đọc từ process.env — không hardcode
│   │
│   ├── types/                    ← Shared TypeScript interfaces
│   │   └── src/index.ts          │  KYCProfile · OrderState · FiatReceipt · SubgraphTypes
│   │
│   ├── core-sdk/                 ← Solana + EVM Web3 wrapper
│   │   └── src/index.ts          │  Anchor IDL integrator · viem public client
│   │
│   ├── ui-kit/                   ← Design System (Work Sans · WCAG AA)
│   │   └── src/
│   │       ├── components/       │  Button · Input · Modal · DataTable · Chart
│   │       │   ├── AppShell/     │  Layout shell với Sidebar + TopNavbar
│   │       │   ├── DataTable/    │  Server-side pagination · sortable columns
│   │       │   ├── Chart/        │  Bar/Pie charts (recharts)
│   │       │   ├── FormWizard/   │  Multi-step form với validation
│   │       │   └── QRCodeModal/  │  QR code display + copy address
│   │       └── tokens/
│   │           ├── colors.ts     │  Brand palette: dark/grey/magenta/orange/greeny/violet/blue/yellow
│   │           ├── typography.ts │  Work Sans · h1–h6 · body · caption (rem scale)
│   │           ├── spacing.ts    │  4px base grid · xs/sm/md/lg/xl/2xl
│   │           ├── shadows.ts    │  card/modal/dropdown shadow tokens
│   │           └── cssVariables.ts │ CSS custom properties cho theming
│   │
│   ├── merchant-sdk/             ← SDK tích hợp cổng thanh toán
│   │   └── src/index.ts          │  MerchantClient · createOrder · getStatus · webhook
│   │
│   ├── sdk-internal/             ← Internal SDK (builders, security, event bus)
│   │   └── src/
│   │       ├── builders/         │  SWIFT message builder (MT/MX)
│   │       ├── security/         │  LAU HMAC · JWT · rate-limit
│   │       ├── events/           │  EventBus · typed event emitter
│   │       └── types/            │  SwiftAdapterTypes · InternalTypes
│   │
│   ├── swift-adapter/            ← SWIFT Alliance Banking SDK (ISO 20022)
│   │   └── src/
│   │       ├── mt/               │  MT103 (credit transfer) · MT202 (bank-to-bank) · MT940 (statement)
│   │       ├── iso20022/         │  pacs.008 · pacs.009 · camt.053
│   │       ├── security/         │  LAU header signing · RMA verification
│   │       └── client.ts         │  OAuth2 + SWIFT MGW HTTP client
│   │
│   ├── sdk-swift/                ← High-level SWIFT SDK (wraps swift-adapter)
│   │   └── src/
│   │       ├── clients/          │  GPI Tracker · BIC Directory · Account Validation
│   │       ├── blockchain/       │  EVM + TRON bridge contract bindings
│   │       ├── generators/       │  ISO 20022 parser/builder (MX format)
│   │       └── security/         │  PKI Manager · LAU Signer · OAuth
│   │
│   └── contracts/                ← EVM Solidity contracts (Hardhat/Foundry)
│       └── contracts/
│           ├── kernel/           │  Kernel.sol · Module.sol (Olympus-style modular governance)
│           ├── modules/
│           │   ├── ROLES/        │  Phân quyền vai trò on-chain
│           │   ├── TRSRY/        │  Treasury v2 — quản lý tài sản DAO
│           │   ├── MINTR/        │  Mint/Burn controller
│           │   ├── RANGE/        │  Range Bound Stability module
│           │   └── COMPL/        │  Compliance module (AML/KYC on-chain flag)
│           ├── policies/
│           │   ├── Governance.sol      │  Quadratic voting + timelock
│           │   ├── RangeBound.sol      │  Price stability corridor
│           │   ├── P2PEscrow.sol       │  EVM P2P escrow (mirror Solana)
│           │   ├── SwiftEscrow.sol     │  SWIFT settlement escrow
│           │   ├── VNDGateway.sol      │  Fiat gateway (VND pegged)
│           │   ├── CapitalControl.sol  │  Regulatory capital controls
│           │   └── StakingPolicy.sol   │  Token staking + emission
│           └── tokens/
│               ├── Token.sol     │  ERC-20 base (rename via brand.config.json)
│               ├── sToken.sol    │  Staked token (sERC-20)
│               └── gToken.sol    │  Governance token (vote-escrowed)
│
│
├── ══════════════════════════════════════════════════════════════════
│   TẦNG 3: DỊCH VỤ BACKEND
│   Ai dùng: Doanh nghiệp (self-host), Chính phủ (on-premise), Nhà phát triển (Docker)
│   ══════════════════════════════════════════════════════════════════
│
├── services/
│   │
│   ├── api-gateway/              ← API tổng hợp · Auth · Rate-limit · Audit log
│   │   └── src/routes/
│   │       ├── auth.route.ts     │  Đăng ký · Đăng nhập · OTP · Refresh token
│   │       ├── user.route.ts     │  Profile · KYC status · Wallet binding
│   │       ├── wallet.route.ts   │  Balance · Transaction history · Address book
│   │       ├── p2p.route.ts      │  Tạo lệnh · Khớp lệnh · Hủy · Lịch sử P2P
│   │       ├── finance.route.ts  │  Nạp/rút Fiat · Lịch sử giao dịch
│   │       ├── exchange.route.ts │  Swap · Pool info · Price feed
│   │       ├── swift.route.ts    │  SWIFT transfer · UETR tracking · MT inquiry
│   │       ├── compliance.route.ts │ AML check · Sanction screening · Report
│   │       ├── learn.route.ts    │  Course content · Progress · Certificate
│   │       └── admin/            │  KYC review · User management · Finance admin
│   │
│   ├── fiat-connector-api/       ← Kết nối ngân hàng · Webhook · Khớp lệnh Fiat
│   │   └── src/
│   │       ├── index.ts          │  Express API · Nhận bank webhook · Match lệnh P2P
│   │       └── mailer.ts         │  Gửi OTP · Xác nhận giao dịch · Alert (Stalwart SMTP)
│   │
│   ├── swift-gateway/            ← SWIFT Microgateway proxy · LAU auth · Định tuyến
│   │   └── src/
│   │       ├── index.ts          │  REST API endpoint nhận lệnh chuyển tiền
│   │       ├── mgw-client.ts     │  HTTP client → SWIFT MGW JVM sidecar (:9003)
│   │       └── bridge.ts         │  Webhook relay → swift-chain-bridge
│   │
│   ├── swift-chain-bridge/       ← Blockchain Relayer · SWIFT event ↔ On-chain
│   │   └── src/
│   │       ├── relayer.ts        │  Ký & gửi on-chain tx khi SWIFT xác nhận
│   │       ├── fx-oracle.ts      │  Tỷ giá SBV + Vietcombank (1 TOKEN = 1 VND)
│   │       ├── listeners/
│   │       │   ├── swift-webhook.ts │ Lắng nghe từ swift-gateway
│   │       │   └── onchain.ts    │  Lắng nghe EVM log filter
│   │       └── executors/
│   │           ├── swift-executor.ts  │ Gửi MT103/pacs.008 outbound
│   │           └── chain-executor.ts  │ Mint/release token sau xác nhận SWIFT
│   │
│   ├── indexer-subgraph/         ← Helius/Subgraph indexer · Proof of Reserve
│   ├── otc-liquidity-engine/     ← OTC cho tổ chức · VARA compliance
│   ├── mock-mgw/                 ← Mock SWIFT MGW (dev/test môi trường cục bộ)
│   └── dune-alert-bots/          ← Telegram/Discord analytics bots
│
│
├── ══════════════════════════════════════════════════════════════════
│   TẦNG 4: GIAO DIỆN NGƯỜI DÙNG
│   Ai dùng: End-users, KYC officers, DAO members, Merchants, Developers
│   ══════════════════════════════════════════════════════════════════
│
├── apps/
│   │
│   ├── app-web/                  ← Ứng dụng chính (Mobile-first PWA)
│   │   └── src/app/
│   │       ├── (auth)/           │  Splash · Login · Register · OTP · PIN
│   │       ├── (app)/            │  Home · Wallet · P2P · Transfer · SWIFT · QR
│   │       │   ├── p2p/          │  Giao dịch ngang hàng (fiat ↔ token)
│   │       │   ├── swift/        │  Chuyển tiền quốc tế SWIFT
│   │       │   ├── crypto/       │  Crypto portfolio · deposit
│   │       │   ├── learn/        │  Khóa học tài chính & blockchain
│   │       │   └── onramp/       │  Mua token bằng Fiat (onramp)
│   │       └── admin/            │  Admin CMS · KYC · Finance · Compliance
│   │
│   ├── kyc-portal/               ← Cổng thẩm định danh tính (KYC officers)
│   │   └── src/app/(portal)/
│   │       ├── dashboard/        │  Tổng quan KYC queue · thống kê tier
│   │       ├── queue/            │  Hàng chờ duyệt · lọc theo tier/status
│   │       ├── verified/         │  Danh sách đã xác minh · export CSV
│   │       ├── attestations/     │  Chứng thực on-chain · ZK proof
│   │       ├── audit-log/        │  Lịch sử thao tác của KYC officer
│   │       └── settings/         │  Cấu hình tổ chức · API keys
│   │
│   ├── dao-portal/               ← Quản trị DAO · Treasury · Staking
│   │   └── src/app/(portal)/
│   │       ├── governance/       │  Đề xuất · Bỏ phiếu · Timelock queue
│   │       ├── treasury/         │  Quản lý tài sản · Proof of Reserve
│   │       ├── staking/          │  Stake/Unstake · APY calculator
│   │       ├── bonds/            │  Phát hành trái phiếu token hóa
│   │       └── rbs-monitor/      │  Giám sát Range Bound Stability
│   │
│   ├── explorer-vnkrscan/        ← Block explorer · Proof of Reserve công khai
│   │   └── src/app/(explorer)/
│   │       ├── blocks/           │  Danh sách block · TPS real-time
│   │       ├── txs/              │  Giao dịch · filter by type/address
│   │       ├── address/[id]/     │  Chi tiết địa chỉ · balance · history
│   │       ├── swift-uetr/[uetr] │  Tra cứu giao dịch SWIFT theo UETR
│   │       └── reserve-audit/    │  Kiểm toán dự trữ công khai
│   │
│   ├── merchant-portal/          ← Cổng đối tác thương mại
│   │   └── src/app/(portal)/
│   │       ├── dashboard/        │  Doanh thu · volume · fee summary
│   │       ├── payments/         │  Lịch sử thanh toán · webhook log
│   │       ├── orders/           │  Quản lý đơn hàng · trạng thái
│   │       └── api-keys/         │  Tạo/thu hồi API keys
│   │
│   ├── pay-portal/               ← Checkout tích hợp (iFrame / redirect)
│   │   └── src/app/(checkout)/
│   │       ├── pay/[orderId]/    │  Trang thanh toán · QR/bank/crypto
│   │       └── pos-terminal/     │  POS tại quầy · in hóa đơn
│   │
│   ├── id-fiat-gateway/          ← Cổng danh tính & Fiat On/Off-ramp
│   │   └── src/app/(gateway)/
│   │       ├── ekic-verify/      │  eKYC/eCitizen verification
│   │       ├── vietqr/           │  VietQR payment integration
│   │       └── bank-rates/       │  Tỷ giá ngân hàng real-time
│   │
│   ├── swap-dex/                 ← DEX (AMM · Pools · Analytics)
│   ├── holding-admin-portal/     ← Quản trị Holding (IP asset · whitelist · capital)
│   ├── sandbox-dashboard/        ← Môi trường sandbox cho nhà phát triển & trường học
│   └── digital-twin-engine/      ← Digital Twin simulation (R&D / AI Labs)
│
│
├── ══════════════════════════════════════════════════════════════════
│   HẠ TẦNG & TRIỂN KHAI
│   ══════════════════════════════════════════════════════════════════
│
├── deploy/
│   ├── docker/
│   │   ├── docker-compose.yml    ← Full stack cục bộ (DB · Redis · Mail · SWIFT mock)
│   │   └── docker-compose.dev.yml
│   ├── kubernetes/               ← Helm charts cho production K8s
│   ├── nginx/                    ← Virtual host configs (app/api/scan/dao/pay/...)
│   ├── terraform/                ← IaC: AWS ECS + Cloudflare DNS + WAF
│   └── npm/                      ← Scripts publish npm packages
│
└── scripts/
    ├── apply-brand.js            ← Thay thế tất cả ${VAR} bằng brand.config.json
    ├── set-program-ids.sh        ← Export PROGRAM_ID_* trước khi anchor build
    ├── installer.sh              ← Cài đặt toàn bộ dependencies
    ├── extract-swift-sdk.sh      ← Giải nén SWIFT vendor packages
    ├── setup-mgw-keystore.sh     ← Khởi tạo JVM keystore SWIFT MGW
    └── test-swift-gateway.sh     ← End-to-end test luồng SWIFT
```

---

## Ma trận Use-case theo đối tượng

| Tầng | Trường học | Chính phủ | Doanh nghiệp | Nhà phát triển |
|------|-----------|-----------|-------------|----------------|
| **Hợp đồng (programs/)** | Nghiên cứu DeFi, lab thực hành | CBDC prototype, escrow công | Token hóa tài sản, AMM nội bộ | Học Anchor/Rust, fork & deploy |
| **Thư viện (packages/)** | Giảng dạy SDK, bài tập | Tích hợp cổng thanh toán nhà nước | Merchant SDK, SWIFT integration | npm install, extend, contribute |
| **Backend (services/)** | Mock API cho course | Self-host on-premise, air-gapped | Microservices production | Docker dev environment |
| **Frontend (apps/)** | Sandbox dashboard học tập | KYC Portal, DAO governance | Merchant portal, Pay portal | Fork & customize UI |

---

## Cấu hình 3 phút để bắt đầu

### Bước 1 — Clone & điền identity
```bash
git clone <repo-url>
cp brand.config.json.example brand.config.json  # điền domain, org, token
node scripts/apply-brand.js                      # áp dụng toàn codebase
```

### Bước 2 — Khởi động môi trường cục bộ
```bash
cp .env.example .env          # điền secrets
docker compose -f deploy/docker/docker-compose.dev.yml up -d
pnpm install && pnpm dev      # khởi động tất cả apps
```

### Bước 3 — Deploy smart contracts (tuỳ chọn)
```bash
source scripts/set-program-ids.sh devnet   # load IDs
anchor build && anchor deploy              # Solana
npx hardhat deploy --network testnet       # EVM
# Cập nhật IDs vào programs/program-ids.config.json
```

---

## Cây nguồn gốc kỹ thuật — Mapping tên biến định danh

| Tên thư mục | Biến định danh (`brand.config.json`) | Mô tả |
|-------------|--------------------------------------|-------|
| `programs/p2p-escrow` | `PROGRAM_ID_P2P_ESCROW` | Solana: giao dịch ngang hàng fiat↔token |
| `programs/mint-governance` | `PROGRAM_ID_MINT_GOVERNANCE` | Solana: kiểm soát phát hành token |
| `programs/amm-swap` | `PROGRAM_ID_AMM_SWAP` | Solana: AMM liquidity pool |
| `programs/treasury-rbs` | `PROGRAM_ID_TREASURY_RBS` | Solana: kho bạc + bình ổn giá |
| `programs/swift-bridge` | `PROGRAM_ID_SWIFT_BRIDGE` | Solana+EVM: cầu nối SWIFT↔on-chain |
| `packages/ui-kit` | *(tên bare, không scope)* | Design system · MIT |
| `packages/swift-adapter` | `SWIFT_BIC_CODE` (trong config) | SWIFT SDK · BSL-1.1 |
| `services/swift-gateway` | `DOCKER_SERVICE_SWIFT` | SWIFT MGW proxy service |
| `services/fiat-connector-api` | `DOCKER_SERVICE_FIAT` | Fiat bank connector |
| `apps/app-web` | `BRAND_DOMAIN` | Main PWA |
| Tất cả domains | `BRAND_DOMAIN` | Thay thế bằng domain của tổ chức |
| Tên tổ chức | `BRAND_ORG_FULL` | Tên đầy đủ của tổ chức fork |
