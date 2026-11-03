# AXIOLEDGER — Team Roles, Skills & Primary Responsibilities

> **Phiên bản:** 2.0 — Cập nhật theo kiến trúc 6-Layer Monorepo  
> **Phân loại:** Internal Engineering — TLP:WHITE  
> **Cập nhật lần cuối:** 2026-11-03

Tài liệu này định nghĩa cấu trúc nhóm kỹ thuật, vai trò, bộ kỹ năng yêu cầu và nhiệm vụ chính theo từng tầng kiến trúc của monorepo AXIOLEDGER.

---

## Sơ đồ tổ chức kỹ thuật

```
                        ┌────────────────────────┐
                        │   LEAD ARCHITECT        │
                        │   @wikialisa          │
                        │   Full ownership across  │
                        │   all 6 layers           │
                        └───────────┬────────────┘
                                    │
          ┌─────────────┬───────────┼───────────┬─────────────┐
          ▼             ▼           ▼           ▼             ▼
   ┌──────────┐  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
   │ @kernel  │  │ @backend │ │@frontend │ │@security │ │@sysadmin │
   │  -team   │  │  -lead   │ │  -lead   │ │  -lead   │ │  -lead   │
   └──────────┘  └──────────┘ └──────────┘ └──────────┘ └──────────┘
          │             │           │
   ┌──────────┐  ┌──────────┐ ┌──────────┐
   │@devtools │  │@contract │ │ @design  │
   │  -lead   │  │ -auditor │ │  -lead   │
   └──────────┘  └──────────┘ └──────────┘
          │
   ┌──────────┐  ┌──────────┐  ┌──────────┐
   │  @qa     │  │ @mobile  │  │ @iot     │
   │  -lead   │  │  -lead   │  │  -lead   │
   └──────────┘  └──────────┘  └──────────┘

   ─────── 5-Pillar Protocol Leads ───────────────────────────────
   @axq-core-dev  ·  @vpx-node-lead  ·  @sqx-kernel-dev
   @kpx-defi-lead ·  @vrq-cipher-dev
```

---

## Vai trò 1 — Lead Architect · `@wikialisa`

**Phạm vi:** Toàn bộ monorepo — default reviewer mọi PR không có owner cụ thể.

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Kiến trúc tổng thể, phê duyệt ADR (Architecture Decision Records), final gate review, quản lý roadmap kỹ thuật, dependency upgrade strategy |
| **Quyền hạn** | Write access tất cả branches; duy nhất có quyền merge vào `main` và `release/*` |
| **Layer phụ trách** | Layer 0 → Layer 5 (toàn bộ) + Services + Tooling + Infra |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Architecture | Distributed systems, monorepo design, ADR, layer isolation, dependency graph |
| Languages | TypeScript (advanced), Rust, Solidity ≥0.8.28, Go (đọc hiểu) |
| Blockchain | EVM, Solana Anchor, ERC-4337/7579, ZK-SNARK, CometBFT |
| Ops | Turborepo, pnpm workspaces, GitHub Actions, Docker, Terraform |
| Security | Threat modeling, PKI, HMAC, OAuth2, cryptographic primitives |

---

## Vai trò 2 — Kernel Team · `@kernel-team`

**Phạm vi:** `libraries/` (Layer 0) — 6 foundation packages

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Duy trì 6 foundation libraries; đảm bảo zero-internal-dependency isolation; quản lý semver và breaking-change policy; viết migration guide cho mỗi major release |
| **Packages phụ trách** | `libraries/core` · `libraries/validation` · `libraries/network` · `libraries/ui-runtime` · `libraries/server-runtime` · `libraries/cli-engine` |
| **Quy tắc cứng** | **Không** được import bất kỳ package nào từ `packages/` hoặc `apps/`. Breaking changes phải có RFC công bố ≥ 7 ngày trước khi merge. |
| **Deliverables** | Typed API contracts, migration guides, changelog entries theo [Conventional Commits](https://www.conventionalcommits.org/) |

**Bộ kỹ năng:**

| Sub-role | Library | Kỹ năng đặc thù |
|---|---|---|
| Runtime Specialist | `core` | `lodash` tree-shaking, `tslib` helper re-exports, polyfill strategy, ESM/CJS dual output |
| Schema Engineer | `validation` | Zod schema composition, `z.infer<>`, discriminated union, schema serialisation, `safeParse` |
| Network Engineer | `network` | Axios interceptor chain, exponential backoff, rate-limit header parsing, typed response |
| VDOM Binding | `ui-runtime` | React 18 reconciler, `createRoot`/`hydrateRoot`, context primitives, peer dep isolation |
| HTTP Server Core | `server-runtime` | Express middleware pipeline order, Helmet CSP config, CORS allowlist, Zod body validation |
| CLI Framework | `cli-engine` | Commander.js plugin model, Inquirer prompt composition, Chalk theming, levelled logger |

---

## Vai trò 3 — Backend Lead · `@backend-lead`

**Phạm vi:** `packages/backend/`, `services/`, domain SDKs

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Thiết kế microservice contracts, định nghĩa REST/WebSocket API, tích hợp SWIFT MGW, database schema management, xây dựng on-chain SDK |
| **Packages phụ trách** | `packages/backend` · `packages/axq-sdk` · `packages/evm-interop` · `packages/core-sdk` · `packages/swift-bridge` · `packages/swift-adapter` · `packages/sdk-swift` · `packages/sdk-internal` · `packages/merchant-sdk` · `packages/config` · `packages/db` |
| **Services phụ trách** | `api-gateway` · `fiat-connector-api` · `swift-gateway` · `swift-chain-bridge` · `indexer-subgraph` · `otc-liquidity-engine` · `role-engine` · `mock-mgw` |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Runtime | Node.js ≥20, TypeScript strict, ESM modules |
| HTTP/API | Express 4, REST design, WebSocket (ws), OpenAPI 3.1 |
| Blockchain | viem, wagmi, ethers.js, Anchor IDL, ERC-20/4337/7579 |
| SWIFT | ISO 20022 (pacs.008, camt.053, MT103/202/940), LAU HMAC signing, SWIFT MGW JVM sidecar (:9003), OAuth2 SWIFT API |
| Data | PostgreSQL, Prisma ORM, Redis (cache + pub/sub), Zod request validation |
| Infra | Docker multi-stage build, health-check endpoints, PM2 cluster mode |

**Quy tắc vận hành:**
- Mọi route phải dùng [`validateBody()`](../libraries/server-runtime/src/index.ts) từ `@axioledger/server-runtime`.
- API response shape phải được khai báo bằng Zod schema trước khi implement handler.
- SWIFT PII files (DP-3) bắt buộc có `@security-lead` approve.

---

## Vai trò 4 — Frontend Lead · `@frontend-lead`

**Phạm vi:** `packages/frontend/`, `apps/`, `design-system/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Xây dựng component architecture, tích hợp Web3 wallet hooks, đảm bảo WCAG 2.1 AA, Core Web Vitals optimisation, SSR/hydration strategy |
| **Apps phụ trách** | Tất cả 15 `apps/*` (co-owner với vertical leads cho security-sensitive apps) |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Framework | React 18+, Next.js 14+ (App Router), TypeScript strict mode |
| Web3 | wagmi v2, RainbowKit, viem, `@axioledger/evm-interop` |
| Styling | Tailwind CSS, CSS Custom Properties, `@axioledger/css` design tokens |
| Quality | WCAG 2.1 AA, Lighthouse CI, `@testing-library/react`, Storybook 8 |
| Performance | RSC (React Server Components), `next/image`, bundle analysis, `@next/bundle-analyzer` |

**Quy tắc:**
- Tất cả UI components phải import từ `@axioledger/ui-runtime` — **không** import `react` trực tiếp.
- Design tokens phải dùng từ `design-system/tokens/` qua `@axioledger/css`.

---

## Vai trò 5 — Design Lead · `@design-lead`

**Phạm vi:** `design-system/`, `packages/css/`, `packages/ui-kit/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Duy trì design token system (color, typography, spacing, shadow), component library API, Storybook documentation, visual regression baseline |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Token System | `style-dictionary`, CSS Custom Properties, Figma tokens plugin, dark/light mode strategy |
| Components | React component API design, compound components pattern, forward-ref, polymorphic props |
| Tooling | Storybook 8, Chromatic visual regression, Vite lib build, `vite.lib.config.ts` |
| Accessibility | WCAG AA contrast ratios (≥4.5:1), focus management, ARIA patterns |

**Quy tắc:**
- Thay đổi token phải chạy `pnpm build:tokens` và commit output files.
- Component API phải backward-compatible — breaking changes cần minor version bump.

---

## Vai trò 6 — Security Lead · `@security-lead`

**Phạm vi:** ZK libs, SWIFT PII, passkey apps, CI workflows

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Security review cho ZK circuits, SWIFT PII handling (DP-3/DP-4), threat modeling, supply-chain audit, dependency vulnerability triage, pen-test coordination |
| **Packages phụ trách** | `packages/zkp-crypto-lib` · `packages/swift-bridge` · `packages/swift-adapter` · `packages/sdk-internal` |
| **Apps phụ trách** | `apps/axiopass-wallet` · `apps/kyc-portal` · `apps/id-fiat-gateway` · `apps/holding-admin-portal` |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| ZK / Crypto | ZK-SNARK (Groth16/PLONK), circom/snarkjs, ERC-7579 passkey validator, P256 key extraction |
| SWIFT Security | LAU HMAC-SHA256 signing, RMA verification, SWIFT MGW keystore (PKCS#12), OAuth2 client credentials |
| AppSec | OWASP Top 10, JWT hardening, rate-limit bypass patterns, SSRF, input sanitisation |
| Supply Chain | `dependabot`, `npm audit`, `pnpm audit`, GitHub Actions pinned SHA, artifact provenance |
| CI Hardening | GitHub Actions security (OIDC, secrets scanning), SAST (Slither, Semgrep), DAST coordination |

**Data Classification:**
- **DP-3** (PII/biometric): `packages/swift-bridge/src/…/vrq/`, KYC data flows — `@security-lead` bắt buộc.
- **DP-4** (SWIFT cleartext config): `services/swift-server/`, `tooling/ssl/` — `@sysadmin-lead` + `@security-lead` bắt buộc.

---

## Vai trò 7 — Contract Auditor · `@contract-auditor`

**Phạm vi:** `smart-contracts/`, `programs/`, `packages/contracts/`, `packages/evm-interop/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Smart contract security review, test coverage enforcement, formal verification, reentrancy/oracle manipulation analysis, gas optimisation audit |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| EVM | Solidity ≥0.8.28, Foundry (forge/cast/anvil), OpenZeppelin patterns, ERC-20/ERC-4337/ERC-7579 |
| Solana | Anchor framework, Rust borrow checker, account constraint model, CPI security |
| Analysis | Slither static analysis, MythX, Echidna fuzz testing, symbolic execution (Manticore) |
| Formal | Halmos, Certora Prover (cơ bản), invariant testing |
| Standards | EIP-1559, EIP-4844, EIP-2771 meta-tx, EIP-712 typed signing |

**Quy tắc cứng:**
- **Không** PR nào vào `smart-contracts/` hoặc `programs/` được merge mà thiếu `@contract-auditor` approval.
- Foundry test coverage ≥ **90%** line, ≥ **85%** branch — bắt buộc.
- Mọi contract deploy script phải có dry-run output đính kèm PR.

---

## Vai trò 8 — Sysadmin Lead · `@sysadmin-lead`

**Phạm vi:** `tooling/`, `infra/`, `services/swift-server/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Quản lý Docker Compose stack local, Helm chart maintenance cho K8s, Terraform IaC cho AWS, Nginx virtual host, TLS certificate rotation, PM2 production process management |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Container | Docker, Docker Compose, multi-stage Dockerfile optimisation |
| Orchestration | Kubernetes (Helm 3), `kubectl`, resource limits, liveness/readiness probes |
| IaC | Terraform (AWS ECS + ECR + Cloudflare DNS + WAF rules), `terraform plan/apply` |
| Networking | Nginx reverse proxy, SSL/TLS (Let's Encrypt, PKCS#12), CoreDNS config |
| Process | PM2 cluster mode, `ecosystem.config.cjs`, log rotation |

**Environments:**

| Env | Stack | Trigger |
|---|---|---|
| `local` | `docker compose -f deploy/docker/docker-compose.dev.yml` | Developer `pnpm localnet` |
| `testnet` | K8s + Helm | Merge to `release/*` |
| `mainnet` | K8s + Terraform (AWS ECS) | Manual approval gate |

---

## Vai trò 9 — DevTools Lead · `@devtools-lead`

**Phạm vi:** `packages/cli/`, `packages/docs/`, `packages/coverage/`, `tooling/scripts/`, CI pipeline

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Xây dựng CLI `axq` (scaffold generators, migration tools, workspace manager), API doc extraction từ Zod schema, quality gate enforcement, Turborepo pipeline optimisation |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| CLI | Commander.js advanced (subcommands, option groups), Inquirer complex prompt flows |
| Docs | TypeDoc, Zod-to-OpenAPI schema extraction, Redoc/Swagger UI integration |
| Build | Turborepo remote cache, task dependency graph, `--filter` patterns, `outputs` hashing |
| CI | GitHub Actions matrix builds, cache strategies, `actions/cache`, OIDC artifact signing |
| Quality | lcov parsing, Istanbul/v8 coverage, `@axioledger/coverage` assertQualityGate |

---

## Vai trò 10 — QA Lead · `@qa-lead`

**Phạm vi:** `packages/testing/`, `packages/coverage/`, `tests/e2e/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | E2E test strategy (Playwright), unit test scaffolding (Vitest), coverage threshold enforcement, regression test management, mock factory maintenance |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| E2E | Playwright (page object model, network mocking, tracing), test parallelisation |
| Unit | Vitest, Jest, `@testing-library/react`, snapshot diffing |
| Mocking | `msw` (Mock Service Worker), Vitest `vi.mock`, factory patterns với Zod schema |
| Coverage | Istanbul v8, lcov report parsing, `assertQualityGate()`, badge generation |

**Quality Gates (bắt buộc trước khi merge `main`):**

| Metric | Threshold |
|---|---|
| Line coverage | ≥ **80%** |
| Branch coverage | ≥ **70%** |
| E2E critical paths | 100% pass (no flaky) |

---

## Vai trò 11 — Mobile Lead · `@mobile-lead`

**Phạm vi:** `packages/mobile/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | Cross-platform runtime adapter, React Native bridge, native storage `AsyncStorage` abstraction layer, push notification bridge |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Mobile | React Native (Expo managed + bare), TypeScript strict |
| Native | Native module bridging (iOS Swift/ObjC, Android Kotlin/Java), Turbo Modules |
| Storage | `AsyncStorage` abstraction, SecureStore (Expo), Keychain (iOS), Keystore (Android) |
| Build | EAS Build, Fastlane, app signing, OTA update strategy |

---

## Vai trò 12 — IoT Lead · `@iot-lead`

**Phạm vi:** `packages/iot/`, `packages/robotics/`, `apps/digital-twin-engine/`

| Mục | Nội dung |
|---|---|
| **Nhiệm vụ chính** | MQTT v5 telemetry stream design, Zod-typed payload decoding, HAL (Hardware Abstraction Layer) interface design, kinematics math, digital twin simulation engine |

**Bộ kỹ năng:**

| Nhóm | Kỹ năng |
|---|---|
| Protocols | MQTT v5 (QoS 0/1/2), CoAP, WebSocket raw frames, topic hierarchy design |
| Typed Streams | TypeScript generics, Zod discriminated union for sensor schemas, rxjs observables |
| Robotics | Forward kinematics, Denavit–Hartenberg parameters, motor PID control, Vec3/Mat4 math |
| Simulation | Digital twin state machine, time-step simulation, capital-flight model, RBS stability sim |

---

## 5-Pillar Protocol Leads

Nhóm này hoạt động theo trục **dọc** của từng token/pillar, song song với các vertical leads trên:

| Handle | Pillar | Token | Nhiệm vụ chính | Kỹ năng đặc thù |
|---|---|---|---|---|
| `@axq-core-dev` | Axioledger Hub | `$AXQ` | AXQToken, AXQGovernance, ANSRegistry, Quadratic Voting, Guardian Council | Solidity, ERC-4337, DAO governance patterns, Babylonian sqrt |
| `@vpx-node-lead` | Valiprecision | `$VPX` | Oracle price daemon, CometBFT consensus, validator node SDK | Node.js cron daemon, Binance/CoinGecko/Kraken API, median aggregation, on-chain pusher |
| `@sqx-kernel-dev` | Sequentichain | `$SQX` | L2 sequencer, Zstd compression, VRF sequencer selection, fast withdrawal | Rust, Zstd, CometBFT, optimistic rollup, ZK fast withdrawal |
| `@kpx-defi-lead` | Kinetoprotocol | `$KPX` | AMM router, veKPX fee sharing, cross-chain routing, dark pool interface | Solidity AMM (x\*y=k), EIP-2771 meta-tx, Uniswap v3 math, veToken |
| `@vrq-cipher-dev` | Veraciphers | `$VRQ` | ZK-SNARK prover, ZK-DID, ERC-7579 passkey validator, NPM supply-chain checksum | circom, snarkjs, Groth16, P256/WebAuthn, sha256 artifact verification |

---

## Ma trận Review & SLA

| Loại thay đổi | Reviewers bắt buộc | SLA |
|---|---|---|
| Breaking change trong `libraries/` | `@wikialisa` + `@kernel-team` | 5 ngày làm việc |
| New library trong `libraries/` | `@wikialisa` + `@kernel-team` (RFC required) | 7 ngày làm việc |
| `smart-contracts/` hoặc `programs/` | `@wikialisa` + `@contract-auditor` | 3 ngày làm việc |
| `apps/axiopass-wallet/` (security) | `@wikialisa` + `@security-lead` | 2 ngày làm việc |
| `.github/workflows/` | `@wikialisa` + `@security-lead` | 1 ngày làm việc |
| `tooling/deploy/terraform/` | `@wikialisa` + `@sysadmin-lead` + `@security-lead` | 2 ngày làm việc |
| SWIFT PII files (DP-3/DP-4) | `@wikialisa` + `@security-lead` (+ `@sysadmin-lead` cho DP-4) | 1 ngày làm việc |
| Feature thường trong `apps/` | `@wikialisa` + vertical lead | 1 ngày làm việc |
| `fix/*` hotfix | `@wikialisa` | 4 giờ |

---

## Quy Tắc Vận Hành Chung

| # | Quy tắc | Áp dụng cho |
|---|---|---|
| 1 | **Contract-First:** Mọi data shape phải được khai báo bằng Zod schema (`@axioledger/validation`) trước khi viết implementation | Tất cả packages & services |
| 2 | **Layer Boundary:** Higher layer imports lower layer — không bao giờ ngược lại. CI lint sẽ reject vi phạm | Tất cả packages |
| 3 | **Isomorphic Exports:** Mọi package phải export đủ 3 subpath: `.` (main), `./node`, `./browser` | `libraries/*`, `packages/*` |
| 4 | **Commit Signing:** GPG signing bắt buộc với tất cả commits merge vào `main` | Tất cả contributors |
| 5 | **Quality Gate:** `pnpm coverage:check` phải pass. Line ≥ 80%, Branch ≥ 70% | Tất cả packages |
| 6 | **Contract Coverage:** Foundry coverage ≥ 90% line trước khi merge smart contract changes | `smart-contracts/`, `programs/` |
| 7 | **No Cleartext Secrets:** Tuyệt đối không commit secrets, keystore password, hay private key vào repo | Tất cả |
| 8 | **RFC for Breaking Changes:** Breaking API changes trong `libraries/` cần RFC issue mở ≥ 7 ngày | `libraries/*` |

---

## Tham chiếu nhanh

| Tài liệu | Đường dẫn |
|---|---|
| CODEOWNERS (ai review path nào) | [`CODEOWNERS`](../CODEOWNERS) |
| Contribution guide | [`CONTRIBUTING.md`](../CONTRIBUTING.md) |
| Architecture overview | [`README.md`](../README.md) |
| Technical blueprint | [`docs/AXIOLEDGER_TECHNICAL_BLUEPRINT.md`](./AXIOLEDGER_TECHNICAL_BLUEPRINT.md) |
| Infrastructure standards | [`docs/INFRASTRUCTURE_STANDARDS.md`](./INFRASTRUCTURE_STANDARDS.md) |
| Operations cheat sheet | [`infra/community/OPERATIONS.md`](../infra/community/OPERATIONS.md) |

---

*Tài liệu này được duy trì bởi Lead Architect — cập nhật mỗi khi có thay đổi cấu trúc team hoặc kiến trúc tầng.*  
*AXIOLEDGER Core Engineering — 2026-11-03*
