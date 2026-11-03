# AXIOLEDGER SDK — Monorepo

> **Phiên bản:** v0.1.0 — Initial Pre-Release
> **NPM Registry:** `registry.npmjs.org` (sau khi publish)
> **Node.js yêu cầu:** ≥ 20.0.0

> **⚠️ Package Manager:** `core/sdk` sử dụng **npm workspaces** nội bộ, tách biệt hoàn toàn
> khỏi pnpm workspace gốc của monorepo. Để quản lý packages tại đây, luôn dùng `npm`
> bên trong thư mục `core/sdk/`, không dùng `pnpm` từ root.
> Versioning: `cd core/sdk && npx changeset add && npx changeset version`

---

## Cấu trúc Packages

| Package | Scope | Mô tả |
|---|---|---|
| `@axioledger/core` | Hub | Smart contracts lõi + Treasury DAO |
| `@axioledger/ans-sdk` | Hub | ANS Resolver SDK |
| `@axioledger/treasury-client` | Hub | Treasury DAO on-chain client |
| `@valiprecision/node-client` | VPX | Node connection SDK |
| `@valiprecision/validator-kit` | VPX | Validator management toolkit |
| `@valiprecision/consensus-lib` | VPX | ZK-OBFT library |
| `@sequentichain/rollup-kit` | SQX | L2 development toolkit |
| `@sequentichain/sequencer` | SQX | AF_XDP Sequencer client |
| `@sequentichain/svm-adapter` | SQX | SVM Rollup adapter |
| `@kinetoprotocol/amm` | KPX | AMM Pool SDK |
| `@kinetoprotocol/rwa-vault` | KPX | RWA Vault interface |
| `@kinetoprotocol/bridge-sdk` | KPX | Cross-chain Bridge |
| `@veraciphers/zk-proof` | VRQ | ZK-Proof module |
| `@veraciphers/did-resolver` | VRQ | ZK-DID resolver |
| `@veraciphers/supply-scanner` | VRQ | Supply Chain Scanner |

## Quick Install

```bash
# Hub SDK
npm install @axioledger/core @axioledger/ans-sdk

# Validator tools
npm install @valiprecision/node-client @valiprecision/validator-kit

# L2 development
npm install @sequentichain/rollup-kit @sequentichain/svm-adapter

# DeFi & liquidity
npm install @kinetoprotocol/amm @kinetoprotocol/bridge-sdk

# Security & identity
npm install @veraciphers/zk-proof @veraciphers/did-resolver
```

## Development

```bash
# Install all dependencies
npm install

# Build all packages
npm run build

# Run all tests
npm run test

# Supply chain audit
npm run audit-supply
```

## License

`BSL-1.1` — Business Source License 1.1.  
Tự động chuyển sang `Apache 2.0` sau 4 năm kể từ ngày phát hành.
