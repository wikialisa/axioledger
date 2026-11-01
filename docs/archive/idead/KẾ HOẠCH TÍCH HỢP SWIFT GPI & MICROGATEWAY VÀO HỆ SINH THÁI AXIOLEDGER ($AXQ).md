# KẾ HOẠCH TÍCH HỢP SWIFT GPI & MICROGATEWAY VÀO HỆ SINH THÁI AXIOLEDGER ($AXQ)

**Kính gửi Cố vấn Đặc biệt (Pháp chế – Kiến trúc – DevOps)**
**Phiên bản:** v3.1 | **Ngày lập:** 2026-09-02 | **Cập nhật:** 2026-09-05
**Người lập kế hoạch:** Kỹ sư trưởng – Axioledger Foundation
**Trạng thái:** ✅ **NGHIỆM THU HOÀN TẤT** — Cố vấn Đặc biệt AXIOLEDGER (2026-09-05) | 🚀 **GIAI ĐOẠN A: GREEN LIGHT**

**Cơ sở tài liệu:** Phân tích trực tiếp mã nguồn & cấu hình từ 3 gói SDK (đã mở và kiểm tra đầy đủ):

| Tệp nguồn | Phiên bản nội tệp | Checksum | Nội dung thực tế |
|---|---|---|---|
| `swift-security-sdk-2.17.5-6.zip` | `2.17.5-6` (jar) | md5.sum ✅ / sha1.sum ✅ | 297 files — OAuth2, mTLS, Signing SDK (Java 17) |
| `swift-sdk-2.17.10-6.zip` | `2.17.10-6` (zip ngoài bao zip trong) | md5.sum ✅ / sha1.sum ✅ | ~246MB — full SDK bundle |
| `swift-mgw-package-2.0.17-1.zip` | `swift-mgw-2.0.17-1` (Spring Boot 2.4.5 / Java 8) | md5.sum ✅ / sha1.sum ✅ | source + config + bin scripts |

> **Lưu ý kỹ thuật quan trọng:** Cả 3 gói đều là **zip lồng zip** (outer wrapper chỉ chứa file zip thật + md5/sha1). Quy trình cài đặt phải giải nén 2 tầng.

---

## 0. BẢNG QUYẾT ĐỊNH CHÍNH THỨC CỦA CỐ VẤN ĐẶC BIỆT

> *Mục này ghi lại toàn bộ chỉ đạo đã được phê duyệt, có hiệu lực ràng buộc với mọi giai đoạn triển khai.*

### DP-1 · Pháp chế: Định danh thực thể đăng ký SWIFT BIC ✅ ĐÃ PHÊ DUYỆT

**Quyết định:** TUYỆT ĐỐI KHÔNG sử dụng Axioledger Foundation Ltd., DAO LLC, hay bất kỳ thực thể quản trị lõi nào để đăng ký SWIFT BIC.

**Chỉ đạo:** Bộ phận Pháp chế thành lập **SPV** chuyên trách thuộc trụ cột **Kinetoprotocol ($KPX)** — pháp nhân đề xuất: *`Kineto Fiat Gateway Ltd.`* hoặc *`Kineto RWA SPV`*.

**Căn cứ:** Axioledger Foundation duy trì vị thế trung lập là nhà phát triển mã nguồn mở. Rủi ro AML/KYC hoặc lệnh trừng phạt SWIFT được giới hạn tại SPV, bảo vệ $AXQ core.

---

### DP-2 · Pháp chế: SWIFT API Connectivity Option License ✅ ĐÃ PHÊ DUYỆT

**Quyết định:** PHÊ DUYỆT ký kết. Giấy phép ký bởi đại diện pháp luật của Kineto SPV (xem DP-1). Hoàn tất **trước khi** khởi động Giai đoạn D.

**Link:** `Swift-API-Connectivity-Option-License.html` có trong cả 3 gói SDK → [PDF chính thức](https://developer.swift.com/sites/default/files/Swift-API-Connectivity-Option-License.pdf)

---

### DP-3 · Kiến trúc: Tách JVM Java 8 / Java 17 + ZK PII Mandate ✅ ĐÃ PHÊ DUYỆT

**Quyết định:** PHÊ DUYỆT. Hai JVM cô lập giao tiếp qua HTTP nội bộ cổng 9003 — Fault-tolerant design.

**ZK Mandate (củng cố từ phê duyệt v1.0):** Mọi PII từ SWIFT GPI phải xử lý **off-chain** qua `SwiftVrqAmlChecker` → VRQ ZK-Proof → **chỉ hash lên on-chain**. Không có ngoại lệ.

---

### DP-4 · DevOps: Dedicated Server + RBAC tách biệt Validator ✅ ĐÃ PHÊ DUYỆT

**Quyết định:** KHÔNG ĐƯỢC PHÉP chạy chung cluster với `sequentichain-node` (SQX).

**Chỉ đạo:** Dedicated Server / VM cô lập hoàn toàn. Sandboxed Directory `./`. `./keys/` → `chmod 600`.

**RBAC bắt buộc:**

| Role | SWIFT Server | SQX/Blockchain |
|---|---|---|
| Infrastructure Root / SysAdmin | ✅ Full | ❌ |
| Blockchain Validator / Node Operator | ❌ BLOCKED | ✅ P2P |
| Security Engineer | ✅ PKI/keys only | ❌ |
| Backend Engineer | ✅ Deploy/log | ❌ |
| Legal Officer | ❌ Không SSH | ❌ |

---

### DP-5 · Ưu tiên: Hybrid Schedule ✅ ĐÃ PHÊ DUYỆT

| Giai đoạn | Trạng thái | Điều kiện |
|---|---|---|
| **A, B, C** | 🟢 **Khởi chạy ngay** | Song song với chuẩn bị Mainnet |
| **D** | 🔒 **Khóa** | Chỉ mở khi $VPX và $SQX ổn định trên Mainnet sau TGE |

---

## I. BỐI CẢNH & MỤC TIÊU CHIẾN LƯỢC

### 1.1 Tại sao cần SWIFT?

Axioledger định vị **RWA Treasury** là trụ cột thu nhập trọng yếu trong Giai đoạn 5 (Thu hoạch). Để triển khai ở quy mô **$1B+ tokenized RWA vào Năm 2**, hệ thống cần kết nối với hạ tầng thanh toán của 11.500+ định chế tài chính tại 200+ quốc gia qua **SWIFT GPI**.

| Chỉ số | Trước tích hợp | Sau tích hợp |
|---|---|---|
| Thời gian xác nhận RWA settlement | N/A (manual) | < 5 phút qua SWIFT gCCT |
| AML/KYC | ZK-DID nội bộ | ZK-DID + SWIFT Network screening |
| Tiếp cận định chế | Cổng DeFi | 11.500+ ngân hàng SWIFT |
| Chứng chỉ bảo mật | GPIA PKI nội bộ | GPIA PKI + mTLS SWIFTNet SIPN |

---

## II. PHÂN TÍCH KỸ THUẬT CÁC GÓI SDK (DỮ LIỆU THỰC TẾ)

### 2.1 `swift-security-sdk` v2.17.5-6

297 files, ~2.1MB JAR. **Môi trường AUDIENCE_SET** (từ `OAuthConstants.java`):

| AUDIENCE_SET | URL OAuth2 Token | Mục đích |
|---|---|---|
| `SANDBOX_PROD` | `sandbox.swift.com/oauth2/v1/token` | Dev / test (Giai đoạn A/B/C) |
| `ON_PREMISES_PILOT` | `api-test.swiftnet.sipn.swift.com/oauth2/v1/token` | Test SIPN |
| `ON_PREMISES_PROD` | `api.swiftnet.sipn.swift.com/oauth2/v1/token` | Production (Giai đoạn D) |

**Token TTL:** `DEFAULT_EXPIRY_TIME_MIN = 15` phút. **Codegen path khuyến nghị:** `sample/openapi_codegen/` (OkHttp3).

### 2.2 `swift-sdk` v2.17.10-6 — GPI Tracker v5.0.5

| Endpoint | Method | Java class | Relevance |
|---|---|---|---|
| `/payments/{uetr}/transactions` | GET | `GetPaymentTransactionDetailsApi` | RWA settlement |
| `/payments/changed-transactions` | GET | `GetChangedPaymentTransactionsApi` | KPX Liquidity sync |
| `/payments/{uetr}/cancellations` | POST | `CancelTransactionApi` | Risk management |
| `/payments/{uetr}/transaction-cancellation-status` | GET | `TransactionCancellationStatusApi` | DAO governance |

**Key models:** `CreditTransferTransaction40` (8.1KB), `PaymentEvent13` (48.6KB), `TransactionIndividualStatus5Code` (ACSC/ACCC/RJCT).

### 2.3 `swift-mgw-package` v2.0.17-1

| Thành phần | Giá trị thực tế |
|---|---|
| Spring Boot | 2.4.5 |
| Java target | **1.8** ⚠️ (khác SDK Java 17 — giải quyết bởi DP-3) |
| Web container | Jetty |
| Database | H2 AES-encrypted |
| Default port | **9003** (không phải 8443) |
| TLS | TLSv1.2 (`-Dhttps.protocols=TLSv1.2`) |

---

## III. KIẾN TRÚC TÍCH HỢP (v3.1 — ĐÃ PHÊ DUYỆT)

### 3.1 Sơ đồ tổng thể

```
┌─────────────────────────────────────────────────────────────────────┐
│                     AXIOLEDGER ECOSYSTEM                             │
│  KinetoProtocol ($KPX) — Kineto Fiat Gateway Ltd. (SPV)             │
│  ┌──────────────────────┐                ┌─────────────────────┐    │
│  │ RWA Treasury         │                │ Veraciphers ($VRQ)  │    │
│  │ Cross-chain Bridge   │                │ PII → ZK-Proof      │    │
│  │ [BIC: Kineto SPV]    │                │ (off-chain only) ✅  │    │
│  └───────────┬──────────┘                └──────────┬──────────┘    │
│              └─────────────────┬────────────────────┘               │
│               ┌────────────────▼─────────────────┐                  │
│               │   packages/swift-bridge/  (Java 17)│                 │
│               │   • SwiftSessionManager   (B1)    │                  │
│               │   • GpiTrackerClient      (B2)    │                  │
│               │   • RwaSettlementMapper   (B3)    │                  │
│               │   • SwiftKpxBridge        (B4)    │                  │
│               │   • SwiftVrqAmlChecker    (B5) DP-3│                 │
│               └────────────────┬─────────────────┘                  │
└────────────────────────────────│────────────────────────────────────┘
                                 │ HTTP localhost:9003
                  ╔══════════════▼══════════════════╗
                  ║  DEDICATED SERVER (PCI DSS) DP-4 ║
                  ║  ./swift-server/  chmod 600 keys  ║
                  ║  RBAC: SysAdmin only              ║
                  ║  ┌──────────────────────────────┐ ║
                  ║  │  MGW v2.0.17-1 — port 9003   │ ║
                  ║  │  Spring Boot 2.4.5 / Java 8  │ ║
                  ║  │  Jetty + H2(AES) + Caffeine  │ ║
                  ║  └──────────────┬───────────────┘ ║
                  ╚═════════════════│═════════════════╝
                                    │ TLSv1.2 / mTLS JKS
                                    ▼
                  ┌──────────────────────────────────┐
                  │   SWIFTNet SIPN GPI Tracker v5.0.5│
                  └──────────────────────────────────┘
```

### 3.2 Phân tầng Java (DP-3 approved)

```
Bridge Layer  [Java 17]  ──HTTP:9003──►  MGW  [Java 8, isolated JVM]
  openapi_codegen                          Spring Boot 2.4.5 / Jetty
  OkHttp3 + swift-security-sdk             H2(AES) on Dedicated Server
  PII off-chain → VRQ ZK-Proof
```

---

## IV. KẾ HOẠCH TRIỂN KHAI (ROADMAP v3.1 — HYBRID SCHEDULE DP-5)

### 🚀 LỆNH ĐIỀU ĐỘNG GIAI ĐOẠN A — HIỆU LỰC NGAY LẬP TỨC

> *Green Light từ Cố vấn Đặc biệt — 2026-09-05. Giai đoạn D phong tỏa cho đến post-TGE.*

---

#### ĐỘI 1 — DevOps / SysAdmin · Ưu tiên: KHẨN

```bash
# BƯỚC 1 — Khởi tạo Sandboxed Directory
# Hoặc chạy script đã tạo:
sudo bash axioledger-monorepo/swift-server/bin/setup.sh swift-admin mgw-service

# BƯỚC 2 — Cài Java 8 JDK riêng biệt
apt-get install -y openjdk-8-jdk
update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/bin/java
java -version   # → openjdk version "1.8.x"

# BƯỚC 3 — Giải nén 2 tầng MGW
unzip swift-mgw-package-2.0.17-1.zip -d ./mgw-outer/
unzip ./mgw-outer/swift-mgw-2.0.17-1.zip -d ./swift-server/
```

**Báo cáo hoàn thành:** `bash swift-server/bin/health-check.sh <apikey>` → HEALTHY

---

#### ĐỘI 2 — Security Engineer · Song song với Đội 1

```bash
# Tạo JKS keystore từ Cross-Bridge CA
keytool -importkeystore \
  -srckeystore ./cross-bridge-cert.p12 -srcstoretype PKCS12 \
  -destkeystore ./swift-server/keys/cross-bridge-keystore.jks -deststoretype JKS \
  -srcalias cross-bridge-client -destalias cross-bridge-client
chmod 600 ./swift-server/keys/*.jks

# Điền config → mã hóa → XÓA cleartext ngay
vim ./swift-server/config/config-swift-mgw.yaml
cd ./swift-server/bin && ./encrypt.sh
rm -f ../config/config-swift-mgw.yaml   # QUAN TRỌNG
```

**Báo cáo:** `ls ./swift-server/config/` chỉ có `.enc` và `.ks`

---

#### ĐỘI 3 — Legal/Compliance · Song song (tuần này)

```
[ ] Thành lập Kineto SPV: "Kineto Fiat Gateway Ltd." (jurisdiction: Singapore/BVI/Cayman)
[ ] Đọc SWIFT Connectivity Option License PDF (link tại DP-2)
[ ] Nộp đơn đăng ký SWIFT BIC (SWIFT Customer Operations Portal)
[ ] Báo cáo tiến độ hàng tuần (BIC registration: 4–8 tuần)
```

---

#### ĐỘI 4 — Backend Java 17 · Sau khi Đội 1 xong bước 3

```bash
# Giải nén SDK 2 tầng + install JAR
unzip swift-security-sdk-2.17.5-6.zip -d ./outer-sec/
unzip ./outer-sec/swift-security-sdk-2.17.5-6.zip -d ./sdk-sec/
mvn install:install-file \
  -Dfile=./sdk-sec/lib/swift-security-sdk-2.17.5-6.jar \
  -DgroupId=com.swift.commons.oauth -DartifactId=swift-security-sdk \
  -Dversion=2.17.5-6 -Dpackaging=jar -Dclassifier=jar-with-dependencies -DgeneratePom=true

# Build swift-bridge + chạy soft tests
cd axioledger-monorepo/packages/swift-bridge
mvn clean test -Dtest="**/soft/**Test"
# → 3 test classes, ~12 assertions, tất cả xanh
```

**Báo cáo:** `GetTokenTest` (hard) → HTTP 200, token TTL ≥ 14 phút từ `sandbox.swift.com`

---

### Điều kiện báo cáo "GIAI ĐOẠN A HOÀN TẤT"

```
✅ Đội 1: GET http://localhost:9003/monitoring/health → {"status":"UP"}
✅ Đội 2: ls ./swift-server/config/ → chỉ .enc và .ks
✅ Đội 3: Receipt SWIFT BIC registration đang xử lý
✅ Đội 4: GetTokenTest(hard) → HTTP 200, TTL ≥ 14 phút từ sandbox.swift.com
```

---

### Giai đoạn A: Thiết lập hạ tầng (Tuần 1–2) 🟢 ĐANG TRIỂN KHAI

| # | Công việc | Đội | Kết quả |
|---|---|---|---|
| A1 | Khởi tạo `./swift-server/` + RBAC (`setup.sh`) | DevOps | `chmod 600 keys/` + Validator blocked |
| A2 | Java 8 JDK riêng, `java -version` → `1.8.x` | DevOps | JVM Java 8 isolated |
| A3 | Giải nén 2 tầng MGW → `./swift-server/` | DevOps | `bin/start.sh` tồn tại |
| A4 | JKS keystore → `./keys/` `chmod 600` | Security | `keytool -list` alias OK |
| A5 | Mã hóa config `.enc` + `.ks`, xóa `.yaml` | Security | Chỉ `.enc`/`.ks` trong `config/` |
| A6 | Start MGW, health check | DevOps | `{"status":"UP"}` cổng 9003 |
| A7 | Giải nén SDK 2 tầng + `mvn install:install-file` | Backend | `mvn dependency:get` OK |
| A8 | Soft tests (`GetTokenTest` mock) | Backend | Không exception |
| A9 | Hard test → `sandbox.swift.com` | Backend | HTTP 200, TTL ≥ 14 phút |

---

### Giai đoạn B: Phát triển Swift Integration Layer (Tuần 3–5) 🟢 MỞ

Module `packages/swift-bridge/` đã được khởi tạo (xem Mục IX.9.1).

| Module | Class | Status |
|---|---|---|
| B1 | `SwiftSessionManager` — OAuth2 lifecycle | ✅ Khởi tạo |
| B2 | `GpiTrackerClient` — 4 GPI endpoints | ✅ Khởi tạo |
| B3 | `RwaSettlementMapper` — GPI → AXQ model | ✅ Khởi tạo |
| B4 | `SwiftKpxBridge` — KPX callback | ✅ Khởi tạo |
| B5 | `SwiftVrqAmlChecker` — ZK-Proof (DP-3) | ✅ Khởi tạo |

---

### Giai đoạn C: Kiểm thử & Bảo mật (Tuần 6–7) 🟢 MỞ

| # | Test | Class | Pass Criteria |
|---|---|---|---|
| C1 | OAuth2 lifecycle | `GetTokenTest`, `RefreshTokenTest`, `RevokeTokenTest` | TTL ≥ 14 phút |
| C2 | GPI Transaction Details | `GetPaymentTransactionDetailsTest` | HTTP 200, schema v5.0.5 |
| C3 | Delta query + paging | `GetChangedPaymentTransactionsTest` | "next" token hoạt động |
| C4 | Cancellation flow | `CancelTransactionTest` | ACCC/RJCT đúng |
| C5 | Async variants | `*AsyncTest.java` | Callback không timeout |
| C6 | mTLS JKS chain | Manual + MGW health | CA→CrossBridge→MGW OK |
| C7 | Load test | `swift-mgw-2.0.14.postman_collection.json` | Theo PDF benchmark |
| C8 | Config encrypt roundtrip | `bin/encrypt.sh` + `bin/decrypt.sh` | Không mất data |
| C9 | RBAC isolation | SSH audit | Validator blocked hoàn toàn |
| C10 | ZK-Proof pipeline | Integration test | PII không on-chain (DP-3) |

---

### Giai đoạn D: Production Rollout (Tuần 8–10) 🔒 KHÓA — Post-TGE (DP-5)

| # | Công việc | Điều kiện |
|---|---|---|
| D1 | `AUDIENCE_SET.SANDBOX_PROD` → `ON_PREMISES_PROD` | Kineto SPV BIC Production |
| D2 | `environment: TEST` → `PRODUCTION`, mã hóa lại | D1 |
| D3 | Deploy MGW production (Java 8 isolated) | D2 + C1–C10 passed |
| D4 | Ký Connectivity Option License (Kineto SPV) | DP-2 |
| D5 | Kích hoạt `AxioledgerSystem.sol` RWA Treasury | D3 + D4 |
| D6 | Mở KPX Cross-chain Bridge | D5 + Mainnet ổn định post-TGE |
| D7 | View Keys audit log (GDPR, theo lệnh tòa) | D6 + Legal |

---

## V. YÊU CẦU PHÁP LÝ & TUÂN THỦ

### 5.1 Điều kiện bắt buộc

| Yêu cầu | Thực thể | Trạng thái |
|---|---|---|
| SWIFT BIC đăng ký | **Kineto SPV** (DP-1) | ⏳ Đang xúc tiến |
| Connectivity Option License | **Kineto SPV** (DP-2) | ⏳ Ký trước Giai đoạn D |
| JKS Keystore cert GPIA | Security Engineer | ✅ Cross-Bridge CA sẵn sàng |
| TLSv1.2 | DevOps | ✅ Enforced trong `start.sh` |
| H2 AES encrypted | Built-in MGW | ✅ |
| Dedicated Server (DP-4) | SysAdmin | ⏳ Cấp phát trước A1 |
| Java 8 JVM riêng | DevOps | ⏳ A2 |

### 5.2 Cam kết GDPR & AML (DP-3)

| Cam kết | Cơ chế |
|---|---|
| PII không on-chain | `SwiftVrqAmlChecker`: PII → VRQ off-chain → ZK hash only |
| AML song song | ZK-DID (VRQ) + SWIFT Network screening |
| UETR traceability | `CreditTransferTransaction40.uetr` lưu L1 |
| View Keys | SWIFT GPI history + ZK-DID proof theo lệnh tòa (D7) |
| Liability isolation | Kineto SPV BIC — Foundation không tiếp xúc Fiat (DP-1) |

### 5.3 Rủi ro

| Rủi ro | Trạng thái |
|---|---|
| Entity sai đăng ký BIC | ✅ Giải quyết DP-1 |
| Java version conflict | ✅ Giải quyết DP-3 |
| MGW chung với SQX | ✅ Giải quyết DP-4 |
| PII on-chain | ✅ Giải quyết DP-3 |
| Production trước Mainnet | ✅ Giải quyết DP-5 |
| SWIFT License giới hạn BIC | ⏳ Legal rà soát |
| BIC registration 4–8 tuần | ⚠️ Theo dõi song song |

---

## VI. TÀI NGUYÊN & NHÂN LỰC

| Vai trò | Số lượng | RBAC SWIFT Server |
|---|---|---|
| Infrastructure Root / SysAdmin | 1 | ✅ Full |
| Backend Engineer (Java 17) | 2 | Deploy/log |
| Backend Engineer (Java 8) | 1 | Deploy/log |
| Security Engineer | 1 | PKI only |
| Legal/Compliance | 1 | ❌ |
| DevOps Engineer | 1 | Deploy |
| QA Engineer | 1 | Read-only log |

**Critical path:** SysAdmin server (trước A1) → Legal BIC (4–8 tuần) → Giai đoạn D

---

## VII. TRẠNG THÁI CÁC ĐIỂM QUYẾT ĐỊNH

| DP | Nội dung | Trạng thái |
|---|---|---|
| DP-1 | Entity đăng ký BIC → Kineto SPV | ✅ Phê duyệt |
| DP-2 | Ký Connectivity Option License → Kineto SPV | ✅ Phê duyệt |
| DP-3 | Tách JVM Java 8/17 + PII off-chain ZK mandate | ✅ Phê duyệt |
| DP-4 | Dedicated Server bắt buộc, RBAC tách biệt Validator | ✅ Phê duyệt |
| DP-5 | Hybrid: A/B/C mở ngay; D khóa đến post-TGE | ✅ Phê duyệt |

**Tất cả 5 DP phê duyệt. Giai đoạn A đang triển khai — lệnh điều động 2026-09-05.**

---

## VIII. KẾ HOẠCH GITHUB COLLABORATION, CI/CD & BRANCH GOVERNANCE

### 8.1 Repository Mapping

| Repository | Ngôn ngữ | Vai trò | Liên quan SWIFT |
|---|---|---|---|
| `axioledger` | Solidity | Core settlement — RWA Treasury | `AxioledgerSystem.sol` kích hoạt D5 |
| `vrq-zk-circuits` | Solidity | Veraciphers ZK-DID AML | PII off-chain pipeline (DP-3) |
| `kpx-amm-router` | Solidity | KPX AMM Cross-chain Bridge | `SwiftKpxBridge.java` kết nối |
| `sqx-rollup-core` | — | SQX L2 node | KHÔNG chung server MGW (DP-4) |
| `vpx-node-client` | — | VPX consensus | Điều kiện mở khóa D (DP-5) |
| `swift-bridge` | Java 17 | **[MỚI — tạo Giai đoạn B]** | Repo private cần tạo |

### 8.2 Branch Governance (Trunk-Based + Release Gates)

```
main ───────────────────────────────────────────────►
       ↑ squash-merge     ↑ squash-merge   ↑ post-TGE
  feature/swift-session  feature/gpi-tracker  feature/swift-prod
       (B1)                  (B2)              (D1–D7 locked)
```

**Quy tắc:** `main` luôn deployable. Branch `feature/swift-prod-*` bị khóa đến post-TGE.

### 8.3 Branch Protection Rules

| Rule | Giá trị |
|---|---|
| Branch name pattern | `main` |
| Require PR before merging | ✅ ON |
| Required approving reviews | `2` |
| Require CODEOWNERS review | ✅ ON |
| Required status checks | `🔐 Swift Security Gate`, `☕ Swift Bridge Build & Test` |
| Block bypass (kể cả admin) | ✅ ON |

### 8.4 CI/CD Workflows (đã tạo)

| File | Jobs |
|---|---|
| `.github/workflows/swift-bridge-ci.yml` | Secret Gate + DP-3 PII audit + Java 17 build/test + Foundry |
| `.github/workflows/zk-circuits-ci.yml` | ZK PII output scan + Circom compile + zkp-crypto-lib test |

### 8.5 Labels

| Label | Màu | Mục đích |
|---|---|---|
| `swift-security` | `#e11d48` | PKI, keystore, ZK-Proof |
| `swift-infra` | `#7c3aed` | MGW, Java 8, Dedicated Server |
| `swift-backend` | `#0284c7` | GpiTrackerClient, Java 17 |
| `legal-compliance` | `#b45309` | BIC, License, GDPR |
| `giai-doan-A` | `#16a34a` | Đang triển khai |
| `giai-doan-D-locked` | `#6b7280` | Post-TGE only |
| `pci-dss` | `#dc2626` | PCI DSS / RBAC |

---

## IX. TRẠNG THÁI TRIỂN KHAI THỰC TẾ (Cập nhật 2026-09-05)

> *Files đã được tạo trong `/root/axioledger-monorepo` khi thực hiện song song.*

### 9.1 `packages/swift-bridge/` ✅ KHỞI TẠO

| File | Trạng thái |
|---|---|
| `pom.xml` | ✅ Java 17, swift-security-sdk 2.17.5-6, JUnit 5, Mockito |
| `session/SwiftSessionManager.java` | ✅ B1 — OAuth2 lifecycle, auto-refresh 2 phút trước expiry |
| `gpi/GpiTrackerClient.java` | ✅ B2 — 4 GPI endpoints, retry-on-401 |
| `gpi/RwaSettlementMapper.java` | ✅ B3 — JSON → RwaSettlementEvent, status mapping |
| `gpi/model/RwaSettlementEvent.java` | ✅ No-PII domain model (DP-3 guaranteed) |
| `kpx/SwiftKpxBridge.java` | ✅ B4 — KPX settlement/rejection callbacks |
| `vrq/SwiftVrqAmlChecker.java` | ✅ B5 — `piiFields.clear()` enforced after ZK proof |
| `soft/SwiftSessionManagerSoftTest.java` | ✅ 5 test cases, Mockito mock |
| `soft/RwaSettlementMapperSoftTest.java` | ✅ 4 cases + DP-3 PII field check |
| `soft/SwiftVrqAmlCheckerSoftTest.java` | ✅ 3 cases, PII.clear() verified |
| `README.md` | ✅ Setup guide + DP-3 guarantee |

**Chạy soft tests:** `mvn clean test -Dtest="**/soft/**Test"` (sau khi install SDK)

### 9.2 `swift-server/` ✅ SCAFFOLDED

| File | Mô tả |
|---|---|
| `swift-server/README.md` | PCI DSS guide, RBAC table, directory structure |
| `swift-server/bin/setup.sh` | Khởi tạo dirs, `chmod 600 keys/`, groupadd, ACL RBAC |
| `swift-server/bin/health-check.sh` | `GET /monitoring/health` → exit 0 nếu HEALTHY |

```bash
sudo bash swift-server/bin/setup.sh   # Thiết lập Dedicated Server
bash swift-server/bin/health-check.sh <apikey>   # Xác nhận HEALTHY
```

### 9.3 GitHub Collaboration ✅ TRIỂN KHAI

| File | Mô tả |
|---|---|
| `.github/workflows/swift-bridge-ci.yml` | 3 jobs: Security Gate + Build/Test + Foundry |
| `.github/workflows/zk-circuits-ci.yml` | DP-3 PII audit + Circom compile + lib test |
| `.github/pull_request_template.md` | Checklist bảo mật DP-3/DP-4, CODEOWNERS routing |
| `CODEOWNERS` | `@davictran76` + team routing theo path |

### 9.4 Việc còn lại để hoàn tất Giai đoạn A

```
[ ] SysAdmin:   Deploy MGW binary (2-layer unzip) vào ./swift-server/
[ ] SysAdmin:   Cài Java 8 JDK riêng trên Dedicated Server
[ ] Security:   Tạo JKS keystore → swift-server/keys/ (chmod 600)
[ ] Security:   bin/encrypt.sh → xóa cleartext .yaml
[ ] Legal:      Nộp hồ sơ Kineto SPV + SWIFT BIC registration
[ ] Backend:    GetTokenTest(hard) → sandbox.swift.com HTTP 200
[ ] GitHub:     Branch Protection Rules (Settings → Branches)
[ ] GitHub:     Tạo Teams: swift-admin, security-lead, contract-auditor
```

---

*Kế hoạch v3.1 — Nghiệm thu hoàn tất & lệnh triển khai từ Cố vấn Đặc biệt (2026-09-05)*
*Kỹ sư trưởng – Axioledger Foundation · `engineering@axioledger.network`*
