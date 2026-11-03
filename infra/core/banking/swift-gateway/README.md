# `core/banking/swift-gateway` — SWIFT MGW Proxy (Java 8)

## Vị trí trong kiến trúc Dual JVM

Đây là **một trong hai thành phần** của kiến trúc SWIFT Dual JVM của Axioledger. Hai thành phần này **không được merge** — chúng có vai trò riêng biệt và chạy trên JVM tách rời:

```
                                     SWIFT Network
                                          │
                                          ▼ HTTPS (mTLS)
                       ┌──────────────────────────────────┐
                       │  SWIFT MGW (Message Gateway)      │
                       │  localhost:9003                   │
                       │  Port: 9003 (outbound from MGW)   │
                       └──────────────┬───────────────────┘
                                      │ HTTP internal
                                      │ localhost:9003/actuator/*
                    ┌─────────────────▼─────────────────────┐
                    │  swift-gateway  (THIS MODULE)          │
                    │  Java 8  ·  Spring Boot                │
                    │  Role: MGW Proxy + Auth Session        │
                    │  Port: 9004 (health + API surface)     │
                    └─────────────────┬─────────────────────┘
                                      │ HTTP  localhost:9004 → 9003
                                      │ OAuth2 token relay
                    ┌─────────────────▼─────────────────────┐
                    │  packages/swift-bridge  (SIBLING)      │
                    │  Java 17 · Maven · Spring-free         │
                    │  Role: GPI Tracker + RWA Settlement    │
                    │  Port: consumes swift-gateway HTTP API │
                    └─────────────────┬─────────────────────┘
                                      │ HTTP event push
                                      ▼
                              KPX Liquidity Pool
                              (on-chain via viem)
```

---

## Phân công trách nhiệm

| Thành phần | Module | JVM | Nhiệm vụ |
|---|---|---|---|
| **SWIFT MGW Proxy** | `core/banking/swift-gateway` (module này) | Java 8 | Nhận yêu cầu từ `swift-bridge`, xác thực OAuth2 với SWIFT MGW trên port 9003, forward request |
| **GPI Tracker + Settlement** | `packages/swift-bridge` | Java 17 | Gọi 4 GPI Tracker v5.0.5 endpoints qua `swift-gateway`, ánh xạ `CreditTransferTransaction40` → `RwaSettlementEvent`, route vào KPX |

**Lý do dùng Java 8 tại đây:** SWIFT Security SDK 2.17.5 có dependency cứng vào Java 8 bytecode. Không thể nâng lên Java 17 mà không vi phạm license của SDK.

---

## Luồng giao tiếp chi tiết (port 9003)

```
swift-bridge (Java 17)
    │
    │  1. POST http://localhost:9004/api/swift/token
    │     → SwiftAuthService.getAccessToken()
    │     → SwiftAuthService gọi MGW OAuth2 endpoint
    ▼
swift-gateway (Java 8, port 9004)
    │
    │  2. Authenticate với SWIFT MGW:
    │     POST https://sandbox.swift.com/oauth2/v1/token   (UAT)
    │     hoặc mgw.axioledger.internal:9003/oauth2/token   (Production)
    │     → Trả về Bearer token (TTL: 15 phút, auto-refresh)
    ▼
SWIFT MGW (localhost:9003)
    │
    │  3. swift-bridge gọi GPI endpoints qua swift-gateway relay:
    │     GET  /tracker/v5.0.5/payments/{uetr}
    │     POST /tracker/v5.0.5/payments
    │     GET  /tracker/v5.0.5/payments  (bulk status)
    │     POST /tracker/v5.0.5/payments/{uetr}/cancellation-requests
    ▼
swift-bridge (Java 17) nhận response
    │
    │  4. RwaSettlementMapper chuyển đổi response
    │     CreditTransferTransaction40 → RwaSettlementEvent
    │
    │  5. SwiftKpxBridge push event vào KPX on-chain
    │     (qua viem / ethers.js bridge)
    ▼
KPX Liquidity Pool (Ethereum / Sepolia)
```

---

## Cấu trúc module

```
core/banking/swift-gateway/
├── pom.xml                                        # Java 8, Spring Boot 2.x
├── src/
│   ├── main/java/com/axioledger/banking/
│   │   ├── AxioBankingApplication.java            # Spring Boot entry point
│   │   ├── auth/
│   │   │   └── SwiftAuthService.java              # OAuth2 session lifecycle (15-min TTL)
│   │   └── config/
│   │       ├── DaoCollateralProvider.java         # DAO treasury collateral config
│   │       └── SwiftBankingConfig.java            # MGW connection config (port 9003)
│   └── test/java/com/axioledger/banking/auth/
│       ├── soft/
│       │   └── SwiftAuthServiceSoftTest.java      # Unit tests (mock MGW — CI-safe)
│       └── hard/
│           └── GetTokenHardTest.java              # Integration test (needs live MGW)
└── src/main/resources/
    └── application.yml                            # Port 9004, MGW endpoint config
```

---

## Build & Run

```bash
# Soft tests only (no SWIFT credentials — CI-safe)
mvn clean test -pl core/banking/swift-gateway -Dtest=SwiftAuthServiceSoftTest

# Build JAR
mvn clean package -pl core/banking/swift-gateway -DskipTests

# Run (requires SWIFT MGW on localhost:9003)
java -jar target/swift-gateway-*.jar \
  --swift.mgw.url=http://localhost:9003 \
  --swift.oauth2.client-id=${SWIFT_CLIENT_ID} \
  --swift.oauth2.client-secret=${SWIFT_CLIENT_SECRET}
```

---

## Yêu cầu khởi động

1. **SWIFT MGW** phải đang chạy trên `localhost:9003`  
   → Start với `./swift-server/bin/start.sh` (xem `packages/swift-bridge/README.md`)

2. **Environment variables** (KHÔNG được commit):

| Biến | Mô tả |
|---|---|
| `SWIFT_CLIENT_ID` | OAuth2 client ID từ SWIFT Alliance Portal |
| `SWIFT_CLIENT_SECRET` | OAuth2 secret — lưu trong secret manager |
| `SWIFT_MGW_URL` | MGW base URL (default: `http://localhost:9003`) |

3. **Sau khi `swift-gateway` đang chạy**, `packages/swift-bridge` (Java 17) có thể kết nối tới port 9004.

---

## Bảo mật (DP-3 & DP-4)

- `config-swift-mgw.yaml` **TUYỆT ĐỐI KHÔNG commit** (đã enforce trong `.gitignore` + CI TruffleHog scan)
- `*.jks`, `*.key`, `*.pem` **TUYỆT ĐỐI KHÔNG commit**
- `GetTokenHardTest.java` chỉ chạy với flag `-Dswift.hard-tests=true` và SWIFT sandbox credentials
- PII (tên, IBAN) **không bao giờ** được serialize ra log — xử lý trong `packages/swift-bridge/SwiftVrqAmlChecker` và thay bằng ZK-proof hash trước khi on-chain

---

## Liên quan

- Sibling module: [`packages/swift-bridge/`](../../../packages/swift-bridge/README.md) — Java 17, GPI Tracker + RWA Settlement
- SWIFT spec: [`core/banking/swift-gateway-spec.md`](../swift-gateway-spec.md)
- Progress: [`core/banking/PROGRESS-REPORT.md`](../PROGRESS-REPORT.md)
