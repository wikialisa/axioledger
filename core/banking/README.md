# AXIOLEDGER Banking Integration — SWIFT Gateway

> **Phân vùng bảo mật:** `core/banking/` (Q:\ isolated — Least Privilege)  
> **Mục đích:** Cổng tích hợp TradFi → AXIOLEDGER KPX (ISO-20022 / SWIFT → RWA Token)  
> **Trạng thái:** v0.0.0 — SDK Installed, Integration Pending (v1.1.0 KPX milestone)

---

## Cấu trúc Thư mục

```
core/banking/
├── swift-gateway/
│   ├── mgw/          ← SWIFT Microgateway 2.0.17-1 (414 files)
│   │   ├── bin/      ← start.sh / stop.sh / service.sh / cbs.sh
│   │   ├── src/      ← Spring Boot Java source
│   │   ├── lib/      ← internal JARs (file-encryptor-decryptor)
│   │   ├── oas/      ← OpenAPI specs (config/management/monitoring)
│   │   └── performance/ ← GPI Tracker benchmark report
│   ├── sdk/          ← SWIFT SDK 2.17.10-6 (6,242 files)
│   │   ├── lib/      ← Core JARs (messaging-sdk, openapi, security)
│   │   ├── apidocs/  ← JavaDoc JARs
│   │   ├── sdk-code-generator/ ← ISO-20022 model generator
│   │   └── config-swift-sdk.yaml ← SDK configuration template
│   ├── security/     ← SWIFT Security SDK 2.17.5-6 (197 files)
│   │   ├── lib/      ← swift-security-sdk.jar + interfaces
│   │   ├── postman/  ← Postman collection (OAuth/mTLS testing)
│   │   └── sample/   ← OAS specs + GPI Tracker sample code
│   ├── config/       ← (700) Runtime config — credentials, endpoints
│   └── keys/         ← (700) SWIFT PKI keys — mTLS client certs
├── iso20022/         ← ISO-20022 message schemas
└── logs/             ← MGW runtime logs
```

## Permissions (Least Privilege)

```
core/banking/     700  root:root  ← chỉ root vào được
├── swift-gateway/        750  root:root
│   ├── keys/             700  root:root  ← KHÔNG ai ngoài root
│   ├── config/           700  root:root  ← credentials bảo mật
│   ├── **/*.jar          640  root:root  ← read-only for service user
│   └── **/*.sh           750  root:root  ← executable
```

## Key JARs

| JAR | Size | Mô tả |
|---|---|---|
| `swift-messaging-sdk-1.17.4.jar` | ~80MB | Core messaging — MT/MX ISO-20022 |
| `swift-sdk-openapi-2.17.10-6.jar` | ~24MB | OpenAPI client generation |
| `swift-security-sdk-2.17.5-6.jar` | ~2MB | OAuth2 + mTLS authentication |
| `swift-sdk-swagger-2.17.10-6.jar` | ~12MB | Swagger codegen |
| `filetransfer-api-sdk-1.17.0-3.jar` | ~10MB | FileAct file transfer |
| `file-encryptor-decryptor-2.17.1-3.jar` | ~10MB | Payload encryption |

## Checksums (MD5 — Verified ✅)

```
SWIFT Security SDK wrapper : 73f31481c3c60b987a86a393eed99dbd ✅
SWIFT MGW wrapper          : d0b6f05cf3635455f7ec4eb279c04d88 ✅
SWIFT SDK wrapper          : 7608f0dc6522c355d5789fd292a06652 ✅
```

## Tích hợp vào AXIOLEDGER KPX

Xem: [`../swift-gateway-spec.md`](swift-gateway-spec.md)
