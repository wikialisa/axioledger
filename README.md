# AXIOLEDGER ($AXQ) — Monorepo

> **500,000 LOC · Hub & 4 Pillars · BSL-1.1 Core · MIT/Apache-2.0 SDKs**

The canonical monorepo for the AXIOLEDGER protocol — a high-performance, privacy-preserving, multi-chain financial operating system. Managed with [Turborepo](https://turbo.build) + [pnpm workspaces](https://pnpm.io/workspaces).

---

## 📐 Architecture: Hub & 4 Pillars

```
axioledger-monorepo/ (~500k LOC)
│
├── apps/                        # User-facing applications
│   ├── axq-governance-ui/       # DAO voting + treasury dashboard   (~15k LOC)
│   ├── axiopass-wallet/         # Passkey-native smart wallet (PWA)  (~20k LOC)
│   ├── kpx-dex-frontend/        # KPX DEX — gasless swaps UI        (~12k LOC)
│   └── kpx-dex-frontend2/       # Next iteration DEX UI              (~8k LOC)
│
├── packages/                    # Shared libraries & SDKs
│   ├── axio-design-system/      # @veraciphers/axio-design-system    (~18k LOC)
│   ├── axq-sdk/                 # @axioledger/axq-sdk (TS client)    (~10k LOC)
│   ├── ans-resolver/            # ANS Domain resolver SDK            (~8k LOC)
│   ├── zkp-crypto-lib/          # ZK proof utilities (Wasm bindings) (~20k LOC)
│   └── evm-interop/             # EVM ABI codegen + wagmi hooks      (~10k LOC)
│
├── core-nodes/                  # Protocol infrastructure
│   ├── valiprecision-node/      # VPX Oracle — price feed daemon     (~120k LOC)
│   └── sequentichain-node/      # SQX L2 sequencer + rollup engine  (~150k LOC)
│
└── smart-contracts/             # On-chain logic (Solidity / Foundry)
    ├── axioledger-system/       # $AXQ governance, DAO, treasury     (~15k LOC)
    ├── ans-registry/            # ANS domain registry (.axq/.vpx/…)  (~12k LOC)
    ├── kpx-liquidity/           # AMM router, LP pools, bridge       (~25k LOC)
    └── vrq-circuits/            # ZK circuits, passkey validator     (~35k LOC)
```

**Total allocated: ~538k LOC** across 14 workspaces.

---

## 🏛️ 5-Organisation Governance

| Org | Pillar | Token | Scope |
|---|---|---|---|
| `axioledger` | Hub (Core) | `$AXQ` | Governance, DAO, Treasury, Genesis |
| `veraciphers` | Security & ZK-DID | `$VRQ` | ZK-Circuits, DID, Axiopass Wallet, Design System |
| `kinetoprotocol` | DeFi Liquidity | `$KPX` | AMM Router, Bridge, RWA Logic, DEX Frontend |
| `valiprecision` | Oracle Network | `$VPX` | Price Feeds, Consensus Engine, P2P Client |
| `sequentichain` | Scaling Layer | `$SQX` | L2 Execution, SVM Rollup, AF_XDP Bypass |

---

## 🚀 Quick Start

### Prerequisites

```bash
node >= 20.0.0
pnpm >= 9.0.0
foundry (forge, cast, anvil) — https://getfoundry.sh
```

### Install

```bash
git clone https://github.com/axioledger/axioledger-monorepo.git
cd axioledger-monorepo
pnpm install
```

### Auth for `@veraciphers` packages

```bash
echo "//npm.pkg.github.com/:_authToken=YOUR_READ_PACKAGES_PAT" >> ~/.npmrc
```

### Build all

```bash
pnpm build
```

### Test all

```bash
pnpm test
```

### Run a specific workspace

```bash
pnpm --filter kpx-dex-frontend dev
pnpm --filter @axioledger/axq-sdk build
pnpm --filter axioledger-system forge test
```

---

## 🗺️ 7-Phase Execution Roadmap

### Phase 1 — Ideation & Positioning ✅
- [x] Define Hub & 4 Pillars architecture
- [x] Allocate 500k LOC across 14 workspaces
- [x] Establish BSL-1.1 (core) / MIT (SDK) licensing strategy
- [x] Register 5 GitHub organisations + ANS namespaces

### Phase 2 — Planning & Architecture ✅
- [x] Turborepo monorepo scaffold (`turbo.json`, `pnpm-workspace.yaml`)
- [x] Tokenomics: 500B $AXQ allocation model
- [x] ANS domain plan: `.axq` `.vpx` `.sqx` `.kpx` `.vrq`
- [ ] Smart contract DAO architecture (Quadratic Voting + Guardian Council)

### Phase 3 — Roadmap & Governance 🔄
- [x] Parallel execution tracks (Foundation / DeFi / Scaling)
- [x] Milestone 1 (Localnet): docker-compose + cargo test
- [ ] DAO Contracts: Quadratic Voting, Time-Lock (7d), Escape Hatch
- [ ] Guardian Council (5 seats, 4/5 veto)

### Phase 4 — Building Infrastructure ✅
- [x] Design System published → `@veraciphers/axio-design-system@4.0.0`
- [x] `VRQPasskeyValidator` deployed → Sepolia
- [x] `KPXRouterGateway` CI pipeline → green on `feat/kpx-amm-router-scaffold`
- [x] VPX Oracle node implemented + tested
- [ ] Internal PKI: Root CA + 5 Intermediate CAs for ANS domains
- [ ] RBAC/IAM: SysAdmin / Node Operator / Treasury Engine roles

### Phase 5 — Harvesting & Integration 🔄
- [x] `@axioledger/axq-sdk` v0.2.0 — real viem calls to AXQToken + ANSRegistry
- [x] `@axioledger/evm-interop` v0.2.0 — full ABI catalogue + wagmi hook factories
- [x] `axq-governance-ui` — wired to AXQGovernance: propose / castVote / queue / execute
- [x] `axiopass-wallet` — VRQPasskeyValidator install flow, passkey registration, P256 key extraction
- [ ] AMM liquidity pools + Emission Controller
- [ ] Cross-chain bridge (KPX ↔ SQX)
- [ ] RWA Treasury activation
- [ ] Namespace Security Guard (anti-squatting)

### Phase 6 — Testing & SecOps ⏳
- [ ] `supply-chain-audit.yml` GitHub Actions
- [ ] GPG commit signing enforcement
- [ ] Cron: Node health (5min), Treasury sweep (1h), FIM (nightly)
- [ ] 100k TPS stress test on devnet

### Phase 7 — Success & Endgame 🏆
- [ ] > 600,000 TPS throughput
- [ ] < 100ms soft confirmation latency
- [ ] Nakamoto Coefficient > 50
- [ ] Validator cost < 0.1 $AXQ/day
- [ ] ZK-Proof user data protection: 100%
- [ ] Genesis Block mainnet + Upgrade Authority → DAO

---

## 💰 Tokenomics — 500B $AXQ

| Allocation | % | Amount |
|---|---|---|
| VPX Validator Subsidy | 25% | 125B $AXQ |
| R&D & Protocol Treasury | 30% | 150B $AXQ |
| RWA Backing Reserve | 15% | 75B $AXQ |
| Core Team (4-yr vest) | 12% | 60B $AXQ |
| Strategic Partners | 13% | 65B $AXQ |
| TGE / Public Liquidity | 5% | 25B $AXQ |

---

## 🔐 Security & Licensing

- **Core Protocol** (`smart-contracts/`, `core-nodes/`): [BSL 1.1](./LICENSE) — source-available, no production fork without commercial license
- **SDKs & Design System** (`packages/`): MIT / Apache-2.0
- **Applications** (`apps/`): AGPL-3.0

Security vulnerabilities: see [`SECURITY.md`](./SECURITY.md)

---

## 📋 Status Matrix

| Workspace | Status | CI | Testnet |
|---|---|---|---|
| `smart-contracts/axioledger-system` | 🔄 In Progress | — | — |
| `smart-contracts/vrq-circuits` | ✅ v1 on Sepolia | ✅ Green | ✅ Sepolia |
| `smart-contracts/kpx-liquidity` | ✅ v1 scaffold | ✅ Green | ⏳ Pending |
| `core-nodes/valiprecision-node` | ✅ v1 implemented | ✅ Green | ⏳ Pending |
| `core-nodes/sequentichain-node` | ❄️ Frozen (Phase 3) | — | — |
| `packages/axio-design-system` | ✅ v4.0.0 published | ✅ Green | N/A |
| `packages/axq-sdk` | ✅ v0.2.0 — viem on-chain client | ✅ Green | N/A |
| `packages/ans-resolver` | ✅ v1 — 15 tests, 85.7% coverage | ✅ Green | N/A |
| `packages/zkp-crypto-lib` | 🔄 Scaffolded | — | — |
| `packages/evm-interop` | ✅ v0.2.0 — ABIs + wagmi hooks | — | N/A |
| `apps/kpx-dex-frontend` | ✅ Scaffold | 🔄 Running | — |
| `apps/axiopass-wallet` | ✅ v1 — VRQPasskeyValidator wired | — | — |
| `apps/axq-governance-ui` | ✅ v1 — AXQGovernance wired | — | — |

---

*Made with ⚡ by the AXIOLEDGER core team.*
