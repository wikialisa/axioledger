# Contributing to AXIOLEDGER

Cảm ơn bạn đã đóng góp. Vui lòng đọc kỹ hướng dẫn này trước khi mở PR.

---

## Mục lục

1. [Code of Conduct](#code-of-conduct)
2. [Development Setup](#development-setup)
3. [Monorepo Layer Rules](#monorepo-layer-rules)
4. [Branching Strategy](#branching-strategy)
5. [Commit Convention](#commit-convention)
6. [Pull Request Guidelines](#pull-request-guidelines)
7. [Review & SLA](#review--sla)
8. [Quality Gates](#quality-gates)
9. [Licensing](#licensing)

---

## Code of Conduct

Tất cả contributors phải tuân thủ [Code of Conduct](./CODE_OF_CONDUCT.md).

---

## Development Setup

```bash
# 1. Fork & clone
git clone https://github.com/wikialisa/axioledger.git
cd axioledger

# 2. Install dependencies (frozen lockfile)
pnpm install --frozen-lockfile

# 3. Build toàn bộ (theo dependency graph)
pnpm build

# 4. Test
pnpm test

# 5. Coverage check
pnpm coverage:check

# 6. Khởi động localnet (Docker stack)
pnpm localnet
```

### Prerequisites

| Tool | Version | Dùng cho |
|---|---|---|
| Node.js | ≥ 20.0.0 | Tất cả packages & apps |
| pnpm | ≥ 9.0.0 | Workspace management |
| Foundry | latest | `smart-contracts/` |
| Anchor CLI | 0.30+ | `programs/` (Solana) |
| Docker | ≥ 24 | `pnpm localnet` |

---

## Monorepo Layer Rules

Repository tuân theo **kiến trúc 6 tầng** với dependency graph một chiều:

```
Layer 0 (libraries/)  →  Layer 1 (packages/)  →  Layer 2 (design-system/)
                                                          ↓
                                              Layer 3 (apps/)
Layer 4 (core-nodes/) — protocol infra (không phụ thuộc layer trên)
Layer 5 (smart-contracts/ + programs/) — on-chain (không phụ thuộc layer trên)
```

**Quy tắc cứng:**

| # | Quy tắc |
|---|---|
| **L1** | `libraries/*` **không** được import từ `packages/` hoặc `apps/` |
| **L2** | `packages/*` **không** được import từ `apps/` |
| **L3** | Breaking changes trong `libraries/*` cần RFC issue mở ≥ **7 ngày** |
| **L4** | Mọi data shape phải khai báo bằng Zod schema (**Contract-First**) |
| **L5** | Mọi package export đủ 3 subpath: `.`, `./node`, `./browser` |

Vi phạm các quy tắc trên sẽ bị CI reject tự động.

---

## Branching Strategy

| Branch | Mục đích | Ai tạo |
|---|---|---|
| `main` | Production-ready, protected | Auto (merge từ `release/*`) |
| `feat/<scope>/<description>` | Feature mới | Developer |
| `fix/<scope>/<description>` | Bug fix | Developer |
| `chore/<scope>/<description>` | Non-functional (deps, docs, config) | Developer |
| `release/<version>` | Release preparation | Lead Architect |
| `hotfix/<description>` | Critical production fix | Backend/Frontend Lead |

**Ví dụ tên branch:**
```
feat/backend/add-swift-gpi-tracker
fix/frontend/wallet-connect-reconnect
chore/kernel/upgrade-zod-v4
```

---

## Commit Convention

Tuân theo [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | Khi nào dùng |
|---|---|
| `feat` | Thêm tính năng mới |
| `fix` | Sửa bug |
| `chore` | Cập nhật deps, config, docs |
| `refactor` | Refactor code (không thay đổi behavior) |
| `test` | Thêm/sửa tests |
| `perf` | Cải thiện performance |
| `ci` | Thay đổi CI/CD pipeline |
| `build` | Thay đổi build system |
| `revert` | Revert commit trước |

### Scopes (theo layer & package)

| Scope | Áp dụng cho |
|---|---|
| `kernel` | `libraries/*` chung |
| `core`, `validation`, `network`, `ui-runtime`, `server-runtime`, `cli-engine` | Từng library cụ thể |
| `backend`, `frontend`, `cli`, `math`, `iot`, `robotics`… | `packages/*` |
| `design-system` | `design-system/` |
| `apps/<app-name>` | `apps/<app>/` |
| `contracts` | `smart-contracts/` |
| `programs` | `programs/` |
| `services/<name>` | `services/<service>/` |
| `tooling` | `tooling/` |
| `ci` | `.github/workflows/` |

**Ví dụ:**
```
feat(network): add rate-limit retry-after header parsing
fix(apps/axiopass-wallet): correct P256 key extraction on iOS
chore(kernel): upgrade zod from 3.23 to 3.24
feat(contracts): add Guardian Council veto mechanism
```

### GPG Signing

GPG signing **bắt buộc** cho tất cả commits merge vào `main`:

```bash
git config --global user.signingkey YOUR_GPG_KEY_ID
git config --global commit.gpgsign true
```

---

## Pull Request Guidelines

### Checklist trước khi mở PR

- [ ] Branch đặt tên đúng convention
- [ ] Commits có Conventional Commits format
- [ ] `pnpm build` pass không có lỗi
- [ ] `pnpm lint` pass
- [ ] `pnpm typecheck` pass
- [ ] `pnpm test` pass
- [ ] `pnpm coverage:check` pass (line ≥ 80%, branch ≥ 70%)
- [ ] Đã cập nhật `CHANGELOG.md` cho user-visible changes
- [ ] Đã link GitHub Issue liên quan

### PR Description Template

```markdown
## Summary
<!-- Mô tả ngắn gọn thay đổi -->

## Type of change
- [ ] feat — New feature
- [ ] fix — Bug fix
- [ ] chore — Maintenance
- [ ] breaking — Breaking change (cần RFC)

## Related Issues
Closes #<issue-number>

## Layer(s) affected
- [ ] Layer 0 — libraries/
- [ ] Layer 1 — packages/
- [ ] Layer 2 — design-system/
- [ ] Layer 3 — apps/
- [ ] Layer 4 — core-nodes/
- [ ] Layer 5 — smart-contracts/ / programs/
- [ ] Services
- [ ] Tooling

## Test coverage
<!-- Paste output của pnpm coverage:check -->

## Checklist
- [ ] CI passes
- [ ] Tests added/updated
- [ ] Docs updated
```

---

## Review & SLA

Xem đầy đủ trong [`docs/TEAM-ROLES.md`](./docs/TEAM-ROLES.md). Tóm tắt:

| Loại thay đổi | Reviewers bắt buộc | SLA |
|---|---|---|
| Breaking change `libraries/*` | `@wikialisa` + `@kernel-team` | 5 ngày làm việc |
| `smart-contracts/` hoặc `programs/` | `@wikialisa` + `@contract-auditor` | 3 ngày làm việc |
| Security-sensitive (`axiopass-wallet`, SWIFT PII) | `@wikialisa` + `@security-lead` | 2 ngày làm việc |
| `.github/workflows/` | `@wikialisa` + `@security-lead` | 1 ngày làm việc |
| Feature thường trong `apps/` | `@wikialisa` + vertical lead | 1 ngày làm việc |
| Hotfix `fix/*` | `@wikialisa` | 4 giờ |

Xem [`CODEOWNERS`](./CODEOWNERS) để biết chính xác ai phải approve từng path.

---

## Quality Gates

### TypeScript packages

```bash
pnpm coverage:check    # line ≥ 80%, branch ≥ 70%
pnpm typecheck         # tsc --noEmit (zero errors)
pnpm lint              # eslint (zero warnings)
```

### Smart contracts (Foundry)

```bash
forge test --gas-report          # tất cả tests pass
forge coverage --report lcov     # line ≥ 90%, branch ≥ 85%
```

### E2E

```bash
pnpm test:e2e      # Jest E2E suites (tests/e2e/)
pnpm test:e2e:pw   # Playwright critical paths
```

---

## Licensing

| Thư mục | Giấy phép | Ghi chú |
|---|---|---|
| `smart-contracts/`, `core-nodes/` | **BSL 1.1** | Source-available, no production fork without commercial license |
| `libraries/`, `packages/` | **MIT / Apache-2.0** | Free to use and fork |
| `apps/` | **AGPL-3.0** | Copyleft for user-facing apps |
| `programs/` | **BSL 1.1** | Solana on-chain programs |

Bằng cách submit PR, bạn đồng ý rằng đóng góp của mình sẽ được cấp phép theo giấy phép tương ứng của thư mục đó.

---

*Xem thêm: [`docs/TEAM-ROLES.md`](./docs/TEAM-ROLES.md) · [`CODEOWNERS`](./CODEOWNERS) · [`SECURITY.md`](./SECURITY.md)*
