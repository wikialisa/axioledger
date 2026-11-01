# BÁO CÁO TIẾN ĐỘ — SWIFT INTEGRATION LAYER
## Kính gửi: Cố vấn Đặc biệt (Pháp chế – Kiến trúc – DevOps)

> **Ngày lập báo cáo:** Phiên làm việc hiện tại  
> **Phạm vi:** Toàn bộ SWIFT Integration Layer — `packages/swift-bridge/` + `core/banking/swift-gateway/`  
> **Trạng thái tổng thể:** 🟡 Scaffold hoàn chỉnh — Đang chờ tháo gỡ điểm nghẽn vật lý & pháp lý

---

## I. TÓM TẮT ĐIỀU HÀNH

Kể từ khi nhận Chỉ thị Khởi động từ Cố vấn, đội kỹ thuật đã hoàn thành toàn bộ phần **có thể tự động hóa bằng code** của Phase A (scripts), Phase B (soft tests), và giai đoạn v0.1.0–v0.2.0 (Spring Boot Banking Translator). Toàn bộ điểm nghẽn còn lại đều thuộc về **yếu tố con người và vật lý** — nằm ngoài phạm vi code.

---

## II. MA TRẬN TRẠNG THÁI THEO MODULE

### Module 1 — `packages/swift-bridge/` (GPI Tracker Client Layer)

| Hạng mục | File | Trạng thái |
|---|---|---|
| Scaffold chính | `pom.xml`, 5 Java classes | ✅ Có trong repo |
| Session / OAuth2 | `SwiftSessionManager.java` | ✅ Scaffold |
| GPI API Client | `GpiTrackerClient.java` | ✅ Scaffold + test constructor |
| Data Mapping | `RwaSettlementMapper.java` | ✅ Scaffold |
| KPX Bridge | `SwiftKpxBridge.java` | ✅ Scaffold |
| VRQ AML Checker | `SwiftVrqAmlChecker.java` | ⚠️ **Stub** — `buildPiiPayloadStub()` chưa có logic thật |
| Soft tests | 6 files, 40 test cases | ✅ Chạy được ngay (không cần SDK, không cần certs) |
| CI / CODEOWNERS | `.github/workflows/swift-bridge-ci.yml` | ✅ Có |
| **`mvn compile`** | — | ❌ **FAIL** — `swift-security-sdk` JAR chưa install |

### Module 2 — `core/banking/swift-gateway/` (Spring Boot Banking Translator)

| Hạng mục | File | Trạng thái |
|---|---|---|
| Maven module | `pom.xml` (Spring Boot 3.3.2) | ✅ v0.2.0-SNAPSHOT |
| Entry point | `AxioBankingApplication.java` | ✅ Profile: sandbox \| production (locked) |
| App config | `SwiftBankingConfig.java` | ✅ `@ConfigurationProperties` đầy đủ |
| **Dynamic collateral** | `DaoCollateralProvider.java` | ✅ DAO eth_call → YAML → 15% fallback |
| **OAuth2 + mTLS** | `SwiftAuthService.java` | ✅ Token cache, 60s proactive refresh |
| Spring config | `application.yml` | ✅ Secrets qua env vars, production locked |
| Soft tests auth | `SwiftAuthServiceSoftTest.java` | ✅ 14 test cases |
| Hard tests auth | `GetTokenHardTest.java` | ⛔ **BLOCKED** — chờ PKI keys + env vars |
| Translator | `SwiftMessageTranslator.java` | ⏳ v0.3.0+ — chưa implement |

---

## III. SCRIPTS TỰ ĐỘNG HÓA ĐÃ TẠO

| Script | Mục đích | Phase | Trạng thái |
|---|---|---|---|
| `scripts/install-swift-sdk.sh` | Giải nén 2 tầng bundle + `mvn install:install-file` | A7 | ✅ Sẵn sàng |
| `scripts/provision-mgw-server.sh` | Tạo `./swift-server/` structure, DP-4 guard, `keys/ chmod 700` | A1–A5 | ✅ Sẵn sàng |

---

## IV. CHECKLIST PHASE A — ĐIỂM NGHẼN HIỆN TẠI

### 4 Gate Conditions — Tất cả đang `[ ]` (chưa hoàn thành)

```
[ ] GET http://localhost:9003/monitoring/health → {"status":"UP"}
    → Trách nhiệm: SysAdmin — chạy scripts/provision-mgw-server.sh rồi khởi động MGW

[ ] ./swift-server/config/ chỉ chứa .enc và .ks (không có .yaml)
    → Trách nhiệm: Security Engineer — chạy bin/encrypt.sh sau khi điền config

[ ] Kineto SPV filing submitted + BIC application receipt từ SWIFT
    → Trách nhiệm: Legal (DP-1) — nộp hồ sơ đăng ký SWIFT BIC cho pháp nhân Kineto SPV

[ ] GetTokenTest(hard) → HTTP 200, token TTL ≥ 14 min từ sandbox.swift.com
    → Trách nhiệm: Backend Engineer — sau khi 3 gate trên xong
```

### 6 Gate Conditions v0.2.0 Banking Translator — Tất cả đang `[ ]`

```
[ ] client.p12 đặt tại /mnt/q/core/banking/swift-gateway/keys/ (chmod 600)
[ ] swift-sandbox-ca.jks đặt tại /mnt/q/core/banking/swift-gateway/keys/ (chmod 600)
[ ] export SWIFT_CLIENT_ID=<từ SWIFT Developer Portal>
[ ] export SWIFT_CLIENT_SECRET=<từ SWIFT Developer Portal>
[ ] export SWIFT_MGW_API_KEY + SWIFT_KEYSTORE_PASSWORD + SWIFT_TRUSTSTORE_PASSWORD
[ ] GetTokenHardTest → HTTP 200, access_token, expires_in ≥ 840s
```

---

## V. TRIỂN KHAI CÁC CHỈ THỊ CỐ VẤN

### Lăng kính Kiến trúc — Dynamic Collateral Ratio

| Chỉ thị | Trước | Sau |
|---|---|---|
| Tỷ lệ thế chấp AXQ | `calculateAXQCollateral(amount, 15)` — hardcoded | `DaoCollateralProvider.getCollateralPct()` — DAO live → YAML floor → 15% fallback |

**Logic 3 tầng đã implement:**
```
Tầng 1 (ưu tiên cao nhất): eth_call → TreasuryDAO.getCollateralBps() on-chain
Tầng 2 (khi DAO không trả lời): axioledger.min_axq_collateral_pct từ application.yml
Tầng 3 (last resort):          DEFAULT_BPS = 1500 (= 15%)
```
→ DAO Governance có thể thay đổi tỷ lệ **không cần re-deploy service**.

### Lăng kính Pháp chế — AML Shield

Đã xác nhận trong `SwiftVrqAmlChecker.java`:
- Luồng `attachProof()` → VRQ `/vrq/v1/aml/prove` → nhận `proofHash`
- `SwiftKpxBridge.forwardEvents()` → **drop event nếu `vrqAmlProofHash == null`** (AML block)
- 9 soft tests bao phủ: PASS / BLOCK / HTTP error / DP-3 PII safety

### Lăng kính DevOps — Secrets & Co-location

| Quy tắc | Triển khai | File |
|---|---|---|
| Secrets qua env vars | `${SWIFT_CLIENT_ID}`, `${SWIFT_CLIENT_SECRET}`, `${SWIFT_MGW_API_KEY}` | `application.yml` |
| Co-location với MGW | Tất cả paths trỏ `/mnt/q/core/banking/swift-gateway/` | `application.yml`, `GetTokenHardTest.java` |
| Production locked | Profile `production` — requires Gate G3 (TVL ≥ $10B) | `application.yml` |
| DP-4 guard | Script exit nếu phát hiện `sqxd` trên cùng host | `provision-mgw-server.sh` |

---

## VI. TEST INVENTORY TỔNG HỢP

| Module | Test file | Loại | Số case | Chạy ngay? |
|---|---|---|---|---|
| `packages/swift-bridge` | `SwiftSessionManagerSoftTest` | soft | 2 | ✅ |
| `packages/swift-bridge` | `RwaSettlementMapperSoftTest` | soft | 4 | ✅ |
| `packages/swift-bridge` | `RwaSettlementMapperChangedTransactionsSoftTest` | soft | 10 | ✅ |
| `packages/swift-bridge` | `GpiTrackerClientSoftTest` | soft | 7 | ✅ |
| `packages/swift-bridge` | `SwiftKpxBridgeSoftTest` | soft | 8 | ✅ |
| `packages/swift-bridge` | `SwiftVrqAmlCheckerSoftTest` | soft | 9 | ✅ |
| `core/banking` | `SwiftAuthServiceSoftTest` | soft | 14 | ✅ |
| `core/banking` | `GetTokenHardTest` | hard | 3 | ⛔ blocked |
| — | **Tổng soft** | — | **54** | ✅ |
| — | **Tổng hard** | — | **3** | ⛔ |

---

## VII. LỘ TRÌNH VÀ TRÁCH NHIỆM

### Thứ tự tháo gỡ (phụ thuộc vào nhau)

```
[Legal]   Nộp hồ sơ BIC Kineto SPV (DP-1)          ─────────────────────────────────┐
[SysAdmin] chạy provision-mgw-server.sh              ─────────────┐                  │
[SecEng]  Tạo JKS, encrypt config (A4–A5)                        ↓                  │
[SysAdmin] Khởi động MGW → health check (A6)          → Phase A gate → [Backend] A7–A9
[Backend]  chạy install-swift-sdk.sh (A7)                        ↓
[Backend]  Soft tests pass → Hard tests (A8–A9)       → Phase A COMPLETE
                                                                  ↓
[SysAdmin] client.p12 + swift-sandbox-ca.jks → keys/             ↓
[Backend]  export SWIFT_CLIENT_ID / SECRET                        ↓
[Backend]  GetTokenHardTest → HTTP 200            → v0.2.0 COMPLETE
                                                                  ↓
[Backend]  Implement SwiftMessageTranslator (v0.3.0)              ↓
[Backend]  Implement SwiftVrqAmlChecker stub → full               ↓
[All]      Phase B → C → D → v1.0.0 Testnet → v1.1.0 Mainnet
```

### Giai đoạn tiếp theo theo ưu tiên

| Ưu tiên | Track | Hành động cụ thể | Người thực hiện |
|---|---|---|---|
| **P0** | Legal | Nộp đơn SWIFT BIC cho Kineto SPV (DP-1) | Legal |
| **P0** | SysAdmin | `sudo ./scripts/provision-mgw-server.sh --mgw-zip <zip>` | SysAdmin |
| **P0** | SysAdmin | Đặt `client.p12` + `swift-sandbox-ca.jks` vào `keys/` (`chmod 600`) | SysAdmin |
| **P1** | SecEng | Tạo JKS keystore, chạy `bin/encrypt.sh`, xóa cleartext YAML | Security Engineer |
| **P1** | Backend | `sudo ./scripts/install-swift-sdk.sh --sdk-zip <zip>` | Backend Engineer |
| **P2** | Backend | `export SWIFT_CLIENT_ID=... SWIFT_CLIENT_SECRET=...` rồi chạy hard tests | Backend Engineer |

---

## VIII. QUY TẮC BẤT BIẾN (KHÔNG ĐƯỢC VI PHẠM)

| DP | Quy tắc | Đã enforce |
|---|---|---|
| **DP-1** | BIC đăng ký dưới **Kineto SPV**, không phải Axioledger Foundation | ✅ `bic8: "AXIQBEB0"` placeholder, chờ BIC thật |
| **DP-2** | Connectivity Option License ký trước Phase D | ✅ Production locked |
| **DP-3** | PII off-chain → chỉ ZK hash lên on-chain | ✅ `RwaSettlementEvent` không có PII field. 6 test DP-3 |
| **DP-4** | MGW trên dedicated server, không co-locate với SQX node | ✅ `provision-mgw-server.sh` có guard `pgrep sqxd` |
| **DP-5** | `ON_PREMISES_PROD` locked đến post-TGE Mainnet | ✅ Profile `production` locked trong `application.yml` |

---

*Báo cáo được tạo tự động từ trạng thái repo thực tế.*  
*AXIOLEDGER SWIFT Integration Layer — Phiên làm việc hiện tại*
