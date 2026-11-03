# Open Financial Infrastructure Monorepo

> **Free forever · Fork freely · Run anywhere**  
> Trường học · Chính phủ · Doanh nghiệp · Nhà phát triển toàn cầu

Monorepo tầng doanh nghiệp cho hệ thống thanh toán, quản trị DAO, cổng SWIFT,
AMM DEX và KYC — được tham số hóa hoàn toàn để bất kỳ tổ chức nào cũng có thể
fork và vận hành dưới danh tính riêng trong vòng 3 phút.

```
pnpm + Turborepo · Next.js 14 · Solana Anchor · EVM Solidity · Node.js
```

---

## Bắt đầu nhanh (3 phút)

```bash
# 1. Clone
git clone <your-fork-url> && cd monorepo

# 2. Điền danh tính tổ chức
cp brand.config.json brand.config.json.bak
# chỉnh sửa brand.config.json — domain, tên tổ chức, token symbol
node scripts/apply-brand.js          # áp dụng toàn codebase

# 3. Cài đặt
cp .env.example .env                 # điền secrets thực
pnpm install

# 4. Khởi động môi trường dev
docker compose -f deploy/docker/docker-compose.dev.yml up -d
pnpm dev                             # tất cả apps chạy song song
```

Truy cập:
- `http://localhost:3000` — App chính (PWA)
- `http://localhost:3001` — KYC Portal
- `http://localhost:3002` — DAO Portal
- `http://localhost:3003` — Block Explorer
- `http://localhost:3004` — Merchant Portal
- `http://localhost:4000` — API Gateway

---

## Kiến trúc 7 tầng

Xem chi tiết: [`ARCHITECTURE.md`](./ARCHITECTURE.md)

**Tầng Ứng dụng:**
```
Tầng 4 — apps/          Giao diện người dùng (Next.js PWA)
Tầng 3 — services/      Backend microservices (Node.js · Docker)
Tầng 2 — packages/      Thư viện & SDK dùng chung (TypeScript · MIT)
Tầng 1 — programs/      Smart contracts (Solana Anchor · EVM Solidity)
```

**Tầng Kỹ thuật (mới):**
```
Tầng C — ctf/           5 CTF challenges · Bảo mật từ audit thực tế
Tầng B — verify/        CLI xác thực artifact vs on-chain bytecode
Tầng A — runtime/       VM sandbox · EVM bytecode execution · Trace
```

---

## Dành cho từng đối tượng

### 🎓 Trường học & Nghiên cứu
- **Sandbox**: `apps/sandbox-dashboard/` — môi trường thực hành tách biệt
- **Smart contracts**: `programs/` — bài tập Solana/EVM với Program ID riêng
- **SDK exercises**: `packages/core-sdk/`, `packages/merchant-sdk/`
- **Chạy cục bộ không cần cloud**: Docker Compose all-in-one

```bash
pnpm --filter sandbox-dashboard dev   # http://localhost:3007
```

### 🏛️ Chính phủ & Tổ chức công
- **KYC Portal** tích hợp eKYC/eCitizen: `apps/kyc-portal/`
- **Block Explorer** & Proof of Reserve công khai: `apps/explorer-AXVNscan/`
- **Quản trị DAO on-chain**: `apps/dao-portal/` + `programs/treasury-rbs/`
- **SWIFT institutional banking**: `packages/swift-adapter/` + `services/swift-gateway/`
- **On-premise deployment**: `deploy/docker/` hoặc `deploy/kubernetes/`

```bash
pnpm --filter kyc-portal build        # build tĩnh để host on-premise
```

### 🏢 Doanh nghiệp & Tổ chức tài chính
- **Cổng thanh toán**: `apps/merchant-portal/` + `apps/pay-portal/`
- **P2P Escrow**: `programs/p2p-escrow/` + `apps/id-fiat-gateway/`
- **DEX nội bộ**: `apps/swap-dex/` + `programs/amm-swap/`
- **SWIFT integration**: `services/swift-gateway/` + `services/swift-chain-bridge/`
- **Merchant SDK**: `packages/merchant-sdk/` — npm install vào backend bất kỳ

```bash
pnpm --filter merchant-portal dev     # cổng quản lý đối tác
pnpm --filter pay-portal dev          # checkout page nhúng vào web
```

### 💻 Nhà phát triển toàn cầu
- **Design System**: `packages/ui-kit/` — MIT, dùng trong bất kỳ React app
- **Shared types**: `packages/types/` — MIT, TypeScript interfaces
- **SWIFT SDK**: `packages/swift-adapter/` — ISO 20022 / MT103 / MT940
- **API Gateway**: `services/api-gateway/` — REST API hoàn chỉnh với auth/audit
- **Contribute**: `CONTRIBUTING-FORK.md` → PR về upstream

```bash
pnpm --filter ui-kit build            # build design system
pnpm --filter swift-adapter test      # chạy SWIFT SDK tests
```

---

## Tham số hóa danh tính

Tất cả thông tin nhận dạng đều là biến — không có gì hardcode:

| File | Mục đích |
|------|----------|
| `brand.config.json` | Domain, tên tổ chức, token symbol, npm scope, BIC |
| `.env` | Secrets runtime (DB, SMTP, API keys — không commit) |
| `programs/program-ids.config.json` | Solana Program IDs + EVM contract addresses |

```bash
node scripts/apply-brand.js --dry-run   # xem trước thay đổi
node scripts/apply-brand.js             # áp dụng
source scripts/set-program-ids.sh devnet && anchor build  # build contracts
```

---

## Cấu trúc thư mục

```
monorepo/
├── apps/              # 11 ứng dụng Next.js (PWA + Admin portals)
├── packages/          # 11 thư viện TypeScript (SDK, UI, types)
├── programs/          # 5 smart contracts (Solana Anchor + EVM Solidity)
├── services/          # 9 microservices Node.js (API, SWIFT, Indexer)
├── runtime/           # VM sandbox · bytecode execution (Rust · MIT)
├── verify/            # On-chain verification CLI (Rust · MIT)
├── ctf/               # 5 Security challenges từ audit thực tế (Rust · MIT)
├── deploy/            # Docker · Kubernetes · Nginx · Terraform
└── scripts/           # Automation: brand, program-ids, SWIFT setup
```

→ Chi tiết từng file: [`ARCHITECTURE.md`](./ARCHITECTURE.md)

---

## Yêu cầu hệ thống

| Công cụ | Phiên bản | Bắt buộc |
|---------|-----------|---------|
| Node.js | ≥ 20 | ✅ |
| pnpm | ≥ 9 | ✅ |
| Docker | ≥ 24 | ✅ (dev stack) |
| Rust + Anchor CLI | 0.30.1 | Chỉ khi deploy Solana |
| Foundry (forge/cast) | latest | Chỉ khi deploy EVM |
| Solana CLI | 1.18.x | Chỉ khi deploy Solana |

---

## Giấy phép

| Thư mục | Giấy phép | Ý nghĩa |
|---------|-----------|---------|
| `packages/ui-kit`, `packages/types`, `packages/config`, `packages/core-sdk` | **MIT** | Tự do hoàn toàn — dùng, sửa, phân phối |
| `apps/*` | **AGPL-3.0** | Mã nguồn mở, phải chia sẻ sửa đổi |
| `programs/*, packages/swift-adapter, packages/sdk-swift` | **BSL-1.1** | Source-available, cần giấy phép thương mại cho production fork |
| `services/*` | **AGPL-3.0** | Microservices open source |
| `runtime/`, `verify/`, `ctf/` | **MIT** | Tự do hoàn toàn — giáo dục, nghiên cứu, production |

---

*Fork it. Run it. Build the future.*
