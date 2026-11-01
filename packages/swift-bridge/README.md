# swift-bridge

**SWIFT GPI & MGW Integration Layer — Axioledger RWA Treasury**

> Giai đoạn B · Java 17 · openapi_codegen path · Spring-free

## Modules

| Class | Role | Phase |
|---|---|---|
| `SwiftSessionManager` | OAuth2 session lifecycle (15-min TTL, auto-refresh) | B1 |
| `GpiTrackerClient` | 4 GPI Tracker v5.0.5 endpoints via MGW port 9003 | B2 |
| `RwaSettlementMapper` | CreditTransferTransaction40 → RwaSettlementEvent | B3 |
| `SwiftKpxBridge` | Route settled events into KPX Liquidity Pool | B4 |
| `SwiftVrqAmlChecker` | PII → ZK-Proof via VRQ (off-chain, DP-3) | B5 |

## DP-3 PII Guarantee

**No PII is ever serialised, logged, or propagated beyond `SwiftVrqAmlChecker`.**
The only on-chain artefact is the ZK proof hash from Veraciphers ($VRQ).

## Prerequisites

1. Java 17
2. Maven 3.8+
3. Swift Security SDK installed (2-layer unzip):
```bash
unzip swift-security-sdk-2.17.5-6.zip -d ./outer-sec/
unzip ./outer-sec/swift-security-sdk-2.17.5-6.zip -d ./sdk-sec/
mvn install:install-file \
  -Dfile=./sdk-sec/lib/swift-security-sdk-2.17.5-6.jar \
  -DgroupId=com.swift.commons.oauth \
  -DartifactId=swift-security-sdk \
  -Dversion=2.17.5-6 \
  -Dpackaging=jar \
  -Dclassifier=jar-with-dependencies \
  -DgeneratePom=true
```

## Build & Test

```bash
# Soft tests only (no SWIFT credentials needed — runs in CI)
mvn clean test

# Build JAR
mvn clean package -DskipTests
```

## SWIFT MGW

MGW listens on `localhost:9003` (Dedicated Server — DP-4).
Start with `./swift-server/bin/start.sh` before running hard tests.

## Security

- `config-swift-mgw.yaml` **must never be committed** (enforced by `.gitignore` + CI secret scan)
- `./keys/*.jks` **must never be committed** (enforced by `.gitignore`)
- Branch protection: 2 approvals required, Security Engineer mandatory for `vrq/` changes
