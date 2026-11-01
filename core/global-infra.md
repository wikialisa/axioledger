# AXIOLEDGER Global Infrastructure — Spec v2.0

> **Nguồn:** Tổng hợp từ [`idead/Global.md`](../idead/Global.md)  
> **Điều lệ:** [`docs/AXIOLEDGER-OFFICIAL-CHARTER.md`](../docs/AXIOLEDGER-OFFICIAL-CHARTER.md)  
> **Node:** `axioledger-devnode` · LAN `192.168.0.47` · WAN `113.22.172.197`

---

## I. TUÂN THỦ TOÀN CẦU (Global Compliance)

| Tiêu chuẩn | Phạm vi | Yêu cầu |
|---|---|---|
| **PCI DSS Level 1** | Xử lý/truyền/lưu dữ liệu thẻ toàn cầu | Bắt buộc với KPX RWA Treasury gateway |
| **E2EE + Tokenization** | Không lưu plaintext số thẻ/CVV | AES-256 + RSA, tất cả qua HSM layer |
| **FATF / AML / KYC** | Chống rửa tiền, định danh người dùng | Xử lý bởi VRQ — ZK-DID |
| **GDPR / ISO 27001** | Bảo vệ dữ liệu cá nhân | Privacy by Design từ giai đoạn thiết kế |
| **MiCA / SEC** | Crypto assets EU + US | Regulator Gateway + Compliance Key |

### Compliant Privacy Principle
- **Người dùng lương thiện:** Ẩn danh tuyệt đối — ZK-DID default
- **Kiểm toán có điều kiện:** Phán quyết Tòa án + hội đồng 5/7 multisig mới giải mã
- **Thuế tự động:** Smart Contract trích xuất tại điểm giao cắt pháp lý

---

## II. PHÂN QUYỀN HỆ THỐNG (RBAC / IAM)

### Identity Naming Convention

```
[Region]-[OrgLevel]-[Subsystem]-[ID]

Ví dụ:
  GL-CORE-FIN-NODE01       ← Global · Core · Finance · Node #1
  EU-LEGAL-AUDIT-HSM02     ← EU · Legal · Audit · HSM #2
  APAC-DEVOPS-CI-RUNNER01  ← APAC · DevOps · CI · Runner #1
  GL-VPX-VALIDATOR-GOV01   ← Global · VPX · Super-Validator · Gov #1
```

### RBAC Matrix

| Role / Identity | Scope | Responsibility |
|---|---|---|
| **Infrastructure Root / SysAdmin** | Toàn quyền kernel, network, Docker, phân vùng `Q:\` | Quản lý lifecycle hạ tầng — **không** can thiệp private key |
| **Blockchain Validator / Node Operator** | Đọc/ghi node blockchain (EVM, SVM), P2P | Xác thực TX, block sync, sổ cái toàn vẹn |
| **Smart Contract / Treasury Engine** | Node.js service Least Privilege, RPC/IPC | Ký TX tự động qua HSM/Multisig, điều phối KPX |
| **CI/CD Automation Agent** | Giới hạn thư mục code, `npm install/build` | Test, build, deploy via GitHub Actions |
| **Security & FIM Auditor** | Read-only logs + security tools | File Integrity Monitor, Legal Audit Trail |
| **HSM Administrator / Crypto Officer** | Hardware Security Module, master keys | Mã hóa/giải mã — **tách biệt hoàn toàn** SysAdmin |
| **Government Super-Validator** | Ưu tiên slot VPX, đọc Compliance Key có điều kiện | Chạy $VPX Node + Genesis Pact Compliance Gateway |

---

## III. PHÂN VÙNG ĐỘC LẬP `/root/` (Production: `Q:\`)

```
/root/                           ← Isolated financial infrastructure root
├── core/
│   ├── api/                     ← API schemas (REST, ANS)
│   ├── github/                  ← OMNI Automation (modal.sh + w1-w7)
│   ├── github-dot/workflows/    ← CI/CD templates (deploy, branch-strategy)
│   ├── scripts/                 ← Cron scripts (emission, buyback, scanner)
│   ├── sdk/                     ← Monorepo root + 15 packages
│   └── global-infra.md          ← This file
├── design-system/               ← Tokens, components, guidelines
├── docs/                        ← Whitepaper + Charter
├── ssl/gpia/                    ← GPIA PKI 4-tier hierarchy
├── asset/icon/                  ← 919 linear + 979 bold SVGs
└── logs/                        ← Audit trail, access logs
```

**Isolation principle:** Financial automation code tách biệt hoàn toàn khỏi `/etc`, `/var`. Private keys không bao giờ tồn tại trong plaintext.

---

## IV. CRON JOBS (Scheduled Automation)

```bash
# Install: sudo crontab -e  (reference: /root/core/scripts/crontab.reference)

# RWA Yield Buyback — daily 02:00
0 2 * * * root node /root/core/scripts/rwa-yield-buyback.js >> /root/logs/treasury.log 2>&1

# AXQ Emission Engine — every 6h
# Emission(t) = κ·ln(1+ΔTVL_RWA) + μ·TxVol − Burn(t)
0 */6 * * * root node /root/core/scripts/axq-emission.js >> /root/logs/treasury.log 2>&1

# File Integrity Monitor — midnight (Legal Audit Trail)
0 0 * * * root node /root/core/scripts/integrity-check.js >> /root/logs/security.log 2>&1

# VRQ Supply Chain Scanner — every 15min
*/15 * * * * root node /root/core/scripts/supply-chain-scan.js >> /root/logs/security.log 2>&1

# GitHub Org Audit — Sunday 01:00
0 1 * * 0 root bash /root/core/github/w7-audit.sh >> /root/logs/github-audit.log 2>&1

# Log cleanup — Sunday 03:00 (keep 30 days)
0 3 * * 0 root find /root/logs/ -type f -mtime +30 -name "*.log" -delete
```

---

## V. CI/CD PIPELINE

```yaml
# Áp dụng cho cả 5 orgs — template tại /root/core/github-dot/workflows/

Jobs:
  1. security-audit   ← npm audit + VRQ Supply Chain Scan + TruffleHog secrets
  2. lint-typecheck   ← ESLint + TypeScript noEmit
  3. test             ← Vitest unit tests + coverage upload
  4. build            ← npm run build → artifact upload
  5. deploy           ← SSH rsync to axioledger-devnode (main branch only)

Branch triggers: push@main, PR→main/ledger/master, workflow_dispatch
Concurrency: cancel-in-progress per branch
```

---

## VI. LICENSE STRATEGY (14 Templates)

| Category | License | Usage in AXIOLEDGER |
|---|---|---|
| **Permissive** | MIT · Apache 2.0 · BSD 2/3 · Boost 1.0 | UI Kit, frontend, utility libraries |
| **Copyleft Strong** | GPLv3 · GPLv2 · AGPLv3 | Validator node software (open source required) |
| **Copyleft Weak** | LGPLv2.1 · MPL-2.0 · EPL-2.0 | Shared libraries, SDKs |
| **Public Domain** | Unlicense · CC0 1.0 | Docs, spec, icon system |
| **Proprietary** | BSL-1.1 (→ Apache 2.0 after 4yr) | Core infrastructure, smart contracts |

---

## VII. SLA & QUALITY TARGETS

| Metric | Target | Mechanism |
|---|---|---|
| **Uptime** | ≥ 99.9% | systemd auto-restart + self-healing cron |
| **Finality (SQX)** | < 3 min | ZK-Rollup Settlement → Hub $AXQ |
| **TPS (SQX testnet)** | 600K+ | AF_XDP NIC Bypass + SVM Rollup |
| **Security Scan** | Every 15 min | VRQ Supply Chain Scanner |
| **Audit Log Retention** | 30 days rolling, 7yr archive | `/root/logs/` → Legal Audit Trail |
| **Disaster Recovery** | RTO < 30min, RPO < 5min | RAMDISK snapshot + NVMe Ledger backup |
| **Max TX Fee** | < $0.001 USD | Encoded in Genesis Block (Điều VII) |

---

## VIII. SERVER IDENTITY

```
Node:     axioledger-devnode
Hostname: axioledger-devnode.axq
LAN IP:   192.168.0.47
WAN IP:   113.22.172.197
OS:       Ubuntu 24.04 / WSL kernel 4.4.0-19041-Microsoft
Nginx:    1.24.0 — HTTP :80 + HTTPS :443
PKI:      GPIA 4-tier hierarchy (Root → Bridge → 5 Pillar CAs → Gateway)
ANS:      /etc/hosts — 44 entries → 192.168.0.47
```

**Linked docs:**
- [`ssl/gpia/export/gpia-identity-declaration.json`](../ssl/gpia/export/gpia-identity-declaration.json)
- [`core/api/ans-service-spec.md`](api/ans-service-spec.md)
- [`core/api/api-schema-v0.0.0.md`](api/api-schema-v0.0.0.md)
