# AXIOLEDGER Name Service (ANS) — Technical Specification

> **File:** `/root/core/api/ans-service-spec.md`  
> **Phiên bản:** 1.0 — Genesis Pact Edition  
> **Nguồn:** Tổng hợp từ [`idead/Name-Service.md`](../../idead/Name-Service.md) + [`idead/Global.md`](../../idead/Global.md)  
> **Điều lệ:** [`docs/AXIOLEDGER-OFFICIAL-CHARTER.md`](../../docs/AXIOLEDGER-OFFICIAL-CHARTER.md)

---

## MỤC LỤC

1. [Tổng quan Kiến trúc](#1-tổng-quan-kiến-trúc)
2. [NPM Scope & GitHub Org Identity Map](#2-npm-scope--github-org)
3. [Monorepo Package Structure](#3-monorepo-package-structure)
4. [TLD Namespace & Namehash](#4-tld-namespace--namehash)
5. [Service Layer Architecture](#5-service-layer-architecture)
6. [PostgreSQL Schema](#6-postgresql-schema)
7. [CoreDNS Corefile](#7-coredns-corefile)
8. [Docker Compose Stack](#8-docker-compose-stack)
9. [API Gateway Endpoints](#9-api-gateway-endpoints)
10. [Smart Contracts](#10-smart-contracts)
11. [Deployment Roadmap](#11-deployment-roadmap)
12. [Identity Reference Table](#12-identity-reference-table)

---

## 1. TỔNG QUAN KIẾN TRÚC

```
              [Client / Web Browser / dApp / CLI]
                            │
               (1) Query *.axq / *.vpx / *.sqx / *.kpx / *.vrq
                            ▼
           ┌────────────────────────────────────┐
           │  CoreDNS / Unbound  —  Port 53     │
           │  Intercept 5 custom TLDs           │
           └──────────────┬─────────────────────┘
                          │
          ┌───────────────┴────────────────┐
          ▼                                ▼
[ANS Resolver Gateway]         [Public Upstream DNS]
 Node.js/Express — Port 8053    1.1.1.1 / 8.8.8.8
 REST / JSON-RPC
          │
     ┌────┴────────────────────┐
     ▼                         ▼
[Redis Cache]          [PostgreSQL Registry]
 TTL: 60s               Off-chain simulator
 namehash → addr        Tables: domains, records
          │
          ▼
[Local Blockchain Node]
 Hardhat / Foundry Anvil
 ANSRegistry + PublicResolver
 + ReverseRegistrar contracts
```

### Phân tầng Dịch vụ

| Tầng | Công nghệ | Mô tả |
|---|---|---|
| **T1 — DNS Capture** | CoreDNS + Unbound | Port 53, intercept 5 TLDs custom, forward internet traffic → 1.1.1.1 |
| **T2 — Web2 Routing** | Nginx Reverse Proxy | Wildcard TLS `*.axq.axqprotocol.com`, ánh xạ subdomain → ANS Resolver |
| **T3 — ANS Core Resolver** | Node.js/Express hoặc Go | Namehash (Keccak-256), multi-chain records, ZK-DID verification |
| **T4 — Caching & Storage** | Redis + PostgreSQL | Redis TTL 60s (<5ms), PostgreSQL off-chain registry |
| **T5 — Smart Contracts** | Hardhat / Foundry Anvil | ANSRegistry, PublicResolver, ReverseRegistrar |

---

## 2. NPM SCOPE & GITHUB ORG

| Trụ cột | Ticker | NPM Scope chính | NPM Scope phụ | GitHub Org | Dev Lead |
|---|---|---|---|---|---|
| **Axioledger** | `$AXQ` | `@axioledger/*` | `@axq-protocol/*` | `github.com/axioledger` | `axq-core-dev` |
| **Valiprecision** | `$VPX` | `@valiprecision/*` | `@vpx-network/*` | `github.com/valiprecision` | `vpx-node-lead` |
| **Sequentichain** | `$SQX` | `@sequentichain/*` | `@sqx-chain/*` | `github.com/sequentichain` | `sqx-kernel-dev` |
| **Kinetoprotocol** | `$KPX` | `@kinetoprotocol/*` | `@kpx-labs/*` | `github.com/kinetoprotocol` | `kpx-defi-lead` |
| **Veraciphers** | `$VRQ` | `@veraciphers/*` | `@vrq-crypto/*` | `github.com/veraciphers` | `vrq-cipher-dev` |

> **Ghi chú:** Scope 3 ký tự (`@axq`, `@vpx`) đã bị squat/reserved trên npm. Sử dụng tên đầy đủ thương hiệu.

---

## 3. MONOREPO PACKAGE STRUCTURE

### `@axioledger` — Core Hub

```
packages/
  @axioledger/core              — Smart contracts lõi + Treasury DAO interface
  @axioledger/ans-sdk           — ANS resolver SDK (.axq domain queries)
  @axioledger/treasury-client   — Treasury DAO on-chain client
  @axioledger/hub-rpc           — JSON-RPC client cho Hub $AXQ node
```

### `@valiprecision` — Consensus & Validation

```
packages/
  @valiprecision/node-client    — SDK kết nối và authenticate $VPX node
  @valiprecision/validator-kit  — Setup, monitor, và manage Validator
  @valiprecision/consensus-lib  — ZK-OBFT implementation library
```

### `@sequentichain` — L2 Execution

```
packages/
  @sequentichain/rollup-kit     — L2 transaction development toolkit
  @sequentichain/sequencer      — AF_XDP Sequencer client
  @sequentichain/svm-adapter    — SVM (Solana VM) Rollup adapter
```

### `@kinetoprotocol` — DeFi & Liquidity

```
packages/
  @kinetoprotocol/amm           — AMM Pool SDK
  @kinetoprotocol/liquidity-engine — Smart routing + LP management
  @kinetoprotocol/rwa-vault     — RWA Treasury vault interface
  @kinetoprotocol/bridge-sdk    — Cross-chain Bridge client (ETH/ARB/SOL)
```

### `@veraciphers` — ZK-Security & Privacy

```
packages/
  @veraciphers/zk-proof         — ZK-Proof generation & verification
  @veraciphers/snark-prover     — ZK-SNARKs prover engine (~284 bytes π)
  @veraciphers/did-resolver     — ZK-DID identity resolver
  @veraciphers/supply-scanner   — Supply Chain Scanner (npm/DApp audit)
```

### Repository Naming Convention

| Pattern | Ví dụ |
|---|---|
| `{ticker}-core-contracts` | `axq-core-contracts` |
| `{ticker}-{function}` | `vpx-node-client`, `sqx-rollup-core` |
| `{ticker}-{function}-sdk` | `kpx-amm-router`, `vrq-zk-circuits` |
| `{ticker}-ans-sdk` | `axq-ans-sdk` |

---

## 4. TLD NAMESPACE & NAMEHASH

### TLD Registry

| TLD | Trụ cột | Ví dụ tên miền | Mục đích |
|---|---|---|---|
| `.axq` | Axioledger Hub | `treasury.axq`, `governance.axq`, `rpc.axq` | Hub addresses, DAO endpoints |
| `.vpx` | Valiprecision | `validator-001.vpx`, `staking.vpx`, `gov-super-01.vpx` | Validator node identity |
| `.sqx` | Sequentichain | `sequencer.sqx`, `rollup.sqx`, `rpc.sqx` | L2 service endpoints |
| `.kpx` | Kinetoprotocol | `pool-usdc-axq.kpx`, `bridge.kpx`, `rwa-treasury.kpx` | DeFi protocol addresses |
| `.vrq` | Veraciphers | `did-auth.vrq`, `kyc-gate.vrq`, `scanner.vrq` | ZK-DID identity, compliance |

### Namehash Algorithm (Keccak-256 ENS-compatible)

```javascript
// Thuật toán ENS-compatible Namehash
// Ref: EIP-137 — Ethereum Name Service

function namehash(name) {
  if (name === '') return '0x' + '00'.repeat(32);
  
  const parts = name.split('.');
  let node = Buffer.alloc(32); // 0x0000...0000 (root)
  
  for (let i = parts.length - 1; i >= 0; i--) {
    const label = keccak256(Buffer.from(parts[i]));
    node = keccak256(Buffer.concat([node, label]));
  }
  return '0x' + node.toString('hex');
}

// Ví dụ:
// namehash("")            = 0x0000000000000000000000000000000000000000000000000000000000000000
// namehash("axq")         = keccak256(namehash("") + keccak256("axq"))
// namehash("treasury.axq")= keccak256(namehash("axq") + keccak256("treasury"))
// namehash("alice.axq")   = keccak256(namehash("axq") + keccak256("alice"))
```

### Pre-computed TLD Root Hashes

```
namehash("axq") = keccak256(0x0000...0000 || keccak256("axq"))
namehash("vpx") = keccak256(0x0000...0000 || keccak256("vpx"))
namehash("sqx") = keccak256(0x0000...0000 || keccak256("sqx"))
namehash("kpx") = keccak256(0x0000...0000 || keccak256("kpx"))
namehash("vrq") = keccak256(0x0000...0000 || keccak256("vrq"))
```

---

## 5. SERVICE LAYER ARCHITECTURE

### Tầng 1 — CoreDNS Config (DNS Capture)

```
# Corefile — CoreDNS config
# Lắng nghe port 53, intercept 5 TLDs, forward internet traffic

axq:53 {
    forward . 127.0.0.1:8053 {
        force_tcp
    }
    log
    errors
}

vpx:53 {
    forward . 127.0.0.1:8053 { force_tcp }
}

sqx:53 {
    forward . 127.0.0.1:8053 { force_tcp }
}

kpx:53 {
    forward . 127.0.0.1:8053 { force_tcp }
}

vrq:53 {
    forward . 127.0.0.1:8053 { force_tcp }
}

.:53 {
    forward . 1.1.1.1 8.8.8.8 {
        max_concurrent 1000
    }
    cache 30
    log
    errors
}
```

### Tầng 2 — Nginx Wildcard Gateway

```nginx
# /etc/nginx/conf.d/ans-wildcard.conf
server {
    listen 443 ssl http2;
    server_name ~^(?<subdomain>.+)\.axq\.axqprotocol\.com$
                ~^(?<subdomain>.+)\.vpx\.vpxchain\.com$
                ~^(?<subdomain>.+)\.sqx\.sqxledger\.com$
                ~^(?<subdomain>.+)\.kpx\.kpxprotocol\.com$
                ~^(?<subdomain>.+)\.vrq\.vrqledger\.com$;

    ssl_certificate     /root/ssl/gpia/gateway/gateway-fullchain.crt;
    ssl_certificate_key /root/ssl/gpia/gateway/gateway.key;

    location / {
        proxy_pass http://127.0.0.1:8053/api/v1/resolve?name=$subdomain;
        proxy_set_header Host $host;
        proxy_set_header X-ANS-Name "$subdomain";
        add_header X-ANS-Resolver "axioledger-devnode.axq" always;
    }
}
```

---

## 6. POSTGRESQL SCHEMA

```sql
-- Database: axioledger_ans
-- Encoding: UTF-8, Collation: en_US.UTF-8

-- ─── TLD Registry ──────────────────────────────────────────────────────────
CREATE TABLE ans_tlds (
    id          SERIAL PRIMARY KEY,
    tld         VARCHAR(10) NOT NULL UNIQUE,   -- 'axq', 'vpx', 'sqx', 'kpx', 'vrq'
    pillar      VARCHAR(50) NOT NULL,
    owner       VARCHAR(42) NOT NULL,          -- Ethereum/AXQ address
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ─── Domain Registry ───────────────────────────────────────────────────────
CREATE TABLE ans_domains (
    id           SERIAL PRIMARY KEY,
    namehash     CHAR(66) NOT NULL UNIQUE,     -- '0x' + 64 hex chars
    name         VARCHAR(253) NOT NULL UNIQUE, -- 'treasury.axq', 'alice.axq'
    tld          VARCHAR(10) NOT NULL REFERENCES ans_tlds(tld),
    label        VARCHAR(100) NOT NULL,        -- 'treasury', 'alice'
    owner        VARCHAR(42) NOT NULL,         -- Wallet address
    resolver     VARCHAR(42),                  -- Resolver contract address
    ttl          INTEGER DEFAULT 3600,
    expiry       TIMESTAMP,
    registered_at TIMESTAMP DEFAULT NOW(),
    updated_at   TIMESTAMP DEFAULT NOW()
);

-- ─── Crypto Address Records ────────────────────────────────────────────────
CREATE TABLE ans_crypto_records (
    id           SERIAL PRIMARY KEY,
    namehash     CHAR(66) NOT NULL REFERENCES ans_domains(namehash),
    coin_type    INTEGER NOT NULL,             -- SLIP-44 coin type
    coin_ticker  VARCHAR(10) NOT NULL,         -- 'AXQ', 'ETH', 'BTC', 'SOL'
    address      VARCHAR(100) NOT NULL,
    updated_at   TIMESTAMP DEFAULT NOW(),
    UNIQUE (namehash, coin_type)
);

-- ─── Text Records ──────────────────────────────────────────────────────────
CREATE TABLE ans_text_records (
    id           SERIAL PRIMARY KEY,
    namehash     CHAR(66) NOT NULL REFERENCES ans_domains(namehash),
    key          VARCHAR(100) NOT NULL,        -- 'email', 'url', 'avatar', 'zk_did_proof'
    value        TEXT NOT NULL,
    updated_at   TIMESTAMP DEFAULT NOW(),
    UNIQUE (namehash, key)
);

-- ─── Reverse Registry ──────────────────────────────────────────────────────
CREATE TABLE ans_reverse (
    id           SERIAL PRIMARY KEY,
    address      VARCHAR(42) NOT NULL UNIQUE,
    primary_name VARCHAR(253) NOT NULL,        -- Primary ANS name for this address
    updated_at   TIMESTAMP DEFAULT NOW()
);

-- ─── Query Audit Log ───────────────────────────────────────────────────────
CREATE TABLE ans_query_log (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(253) NOT NULL,
    requester_ip INET,
    cache_hit    BOOLEAN DEFAULT FALSE,
    resolved_at  TIMESTAMP DEFAULT NOW()
);

-- ─── Indexes ───────────────────────────────────────────────────────────────
CREATE INDEX idx_domains_name     ON ans_domains(name);
CREATE INDEX idx_domains_owner    ON ans_domains(owner);
CREATE INDEX idx_crypto_namehash  ON ans_crypto_records(namehash);
CREATE INDEX idx_text_namehash    ON ans_text_records(namehash);
CREATE INDEX idx_reverse_address  ON ans_reverse(address);

-- ─── Seed TLDs ─────────────────────────────────────────────────────────────
INSERT INTO ans_tlds (tld, pillar, owner) VALUES
  ('axq', 'Axioledger Hub',    '0x0000000000000000000000000000000000000001'),
  ('vpx', 'Valiprecision',     '0x0000000000000000000000000000000000000002'),
  ('sqx', 'Sequentichain',     '0x0000000000000000000000000000000000000003'),
  ('kpx', 'Kinetoprotocol',    '0x0000000000000000000000000000000000000004'),
  ('vrq', 'Veraciphers',       '0x0000000000000000000000000000000000000005');
```

---

## 7. COREDNS COREFILE

```
# /etc/coredns/Corefile
# CoreDNS v1.11+ — AXIOLEDGER ANS Custom TLD resolver

# ─── AXIOLEDGER Custom TLDs → ANS Resolver ──────────────────────────────────
axq vpx sqx kpx vrq {
    forward . 127.0.0.1:8053 {
        force_tcp
        max_concurrent 500
        health_check 5s
    }
    cache 60
    log . "{remote} [{type}] {name} {class} → {rcode} {size}"
    errors
    prometheus :9153
}

# ─── All other domains → Public Upstream ─────────────────────────────────────
. {
    forward . 1.1.1.1 8.8.8.8 {
        policy sequential
        max_concurrent 1000
        expire 10s
        health_check 5s
    }
    cache 300
    log
    errors
    health :8080
    prometheus :9153
}
```

---

## 8. DOCKER COMPOSE STACK

```yaml
# docker-compose.yml — AXIOLEDGER ANS Infrastructure
# Deploy: docker compose up -d
# Requires: Docker Engine 24+, Docker Compose v2.20+

version: "3.9"

services:

  # ─── CoreDNS — DNS Capture Layer ─────────────────────────────────────────
  coredns:
    image: coredns/coredns:1.11.1
    container_name: axioledger-coredns
    restart: unless-stopped
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "9153:9153"       # Prometheus metrics
    volumes:
      - ./Corefile:/Corefile:ro
    networks:
      - ans-net

  # ─── ANS Resolver — Core Resolution Engine ───────────────────────────────
  ans-resolver:
    build:
      context: ./resolver
      dockerfile: Dockerfile
    container_name: axioledger-ans-resolver
    restart: unless-stopped
    ports:
      - "8053:8053"
    environment:
      - NODE_ENV=production
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://ans_user:${PG_PASSWORD}@postgres:5432/axioledger_ans
      - BLOCKCHAIN_RPC=http://anvil:8545
      - ANS_REGISTRY_ADDRESS=${ANS_REGISTRY_ADDRESS}
      - PUBLIC_RESOLVER_ADDRESS=${PUBLIC_RESOLVER_ADDRESS}
      - LOG_LEVEL=info
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
      anvil:
        condition: service_started
    networks:
      - ans-net

  # ─── Redis — Caching Layer (TTL 60s, target <5ms) ─────────────────────────
  redis:
    image: redis:7.2-alpine
    container_name: axioledger-redis
    restart: unless-stopped
    command: >
      redis-server
        --maxmemory 512mb
        --maxmemory-policy allkeys-lru
        --save ""
        --requirepass ${REDIS_PASSWORD}
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - ans-net

  # ─── PostgreSQL — Off-chain Registry ─────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: axioledger-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: axioledger_ans
      POSTGRES_USER: ans_user
      POSTGRES_PASSWORD: ${PG_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./sql/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql:ro
      - ./sql/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ans_user -d axioledger_ans"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ans-net

  # ─── Foundry Anvil — Local Blockchain Node ───────────────────────────────
  anvil:
    image: ghcr.io/foundry-rs/foundry:latest
    container_name: axioledger-anvil
    restart: unless-stopped
    command: >
      anvil
        --host 0.0.0.0
        --port 8545
        --chain-id 31337
        --block-time 1
        --accounts 10
        --mnemonic "${DEPLOYER_MNEMONIC}"
    ports:
      - "8545:8545"
    networks:
      - ans-net

volumes:
  postgres-data:
    driver: local

networks:
  ans-net:
    driver: bridge
```

### `.env.example`

```bash
# AXIOLEDGER ANS Infrastructure — Environment Variables
PG_PASSWORD=change_me_strong_password_here
REDIS_PASSWORD=change_me_redis_password_here
DEPLOYER_MNEMONIC=test test test test test test test test test test test junk
ANS_REGISTRY_ADDRESS=0x0000000000000000000000000000000000000000
PUBLIC_RESOLVER_ADDRESS=0x0000000000000000000000000000000000000000
ANS_ADMIN_TOKEN=change_me_admin_token_here
```

---

## 9. API GATEWAY ENDPOINTS

**Base URL:** `http://127.0.0.1:8053/api/v1`  
**Auth:** Header `Authorization: Bearer <ANS_ADMIN_TOKEN>` (admin routes only)

### `GET /api/v1/resolve`

Phân giải ANS name → địa chỉ ví đa chuỗi.

```
GET /api/v1/resolve?name=treasury.axq
```

**Response `200`:**
```json
{
  "name": "treasury.axq",
  "namehash": "0xabc...123",
  "owner": "0x892a4F8b2E...d3C1",
  "records": {
    "AXQ": "0xA12B...FF90",
    "ETH": "0x892a4F8b2E...d3C1",
    "BTC": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
    "SOL": "8Zg...AbC"
  },
  "text": {
    "url": "https://axqprotocol.com/treasury",
    "avatar": "ipfs://QmAvatar...",
    "zk_did_proof": "0xproof..."
  },
  "contenthash": "ipfs://QmXoypiz...zN5",
  "ttl": 3600,
  "cache_hit": true,
  "resolved_at": "2026-09-01T10:00:00Z"
}
```

### `POST /api/v1/register` *(Admin)*

Đăng ký tên miền ANS mới.

```json
{
  "name": "alice.axq",
  "owner": "0xABCD...1234",
  "records": {
    "AXQ": "0xABCD...1234",
    "ETH": "0xABCD...1234"
  },
  "text": {
    "email": "alice@example.com",
    "url": "https://alice.io"
  },
  "ttl": 3600
}
```

**Response `201`:**
```json
{
  "name": "alice.axq",
  "namehash": "0xdef...789",
  "tx_hash": "0xonchain...hash",
  "registered_at": "2026-09-01T10:00:00Z"
}
```

### `GET /api/v1/reverse`

Phân giải ngược: địa chỉ ví → primary ANS name.

```
GET /api/v1/reverse?address=0x892a4F8b2E...d3C1
```

**Response `200`:**
```json
{
  "address": "0x892a4F8b2E...d3C1",
  "primary_name": "treasury.axq",
  "verified": true
}
```

### `POST /api/v1/zk-verify`

Xác minh ZK-DID proof qua VERACIPHERS ($VRQ).

```json
{
  "name": "alice.axq",
  "zk_proof": "0xproof...",
  "circuit": "identity_v1"
}
```

**Response `200`:**
```json
{
  "valid": true,
  "identity_tier": "enterprise_validator",
  "compliance_status": "kyc_verified",
  "issuer": "veraciphers.vrq",
  "expires_at": "2026-12-31T00:00:00Z"
}
```

### `GET /api/v1/health`

Health check tất cả dependencies.

**Response `200`:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "dependencies": {
    "redis": "ok",
    "postgres": "ok",
    "blockchain": "ok"
  },
  "uptime_seconds": 86400
}
```

---

## 10. SMART CONTRACTS

### ANSRegistry.sol

```solidity
// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.24;

/**
 * @title ANSRegistry
 * @notice AXIOLEDGER Name Service Registry
 *         Stores owner, resolver, and TTL for each namehash node
 * @dev ENS-compatible (EIP-137) — supports .axq .vpx .sqx .kpx .vrq TLDs
 */
contract ANSRegistry {
    struct Record {
        address owner;
        address resolver;
        uint64  ttl;
    }

    mapping(bytes32 => Record) private records;
    mapping(address => mapping(address => bool)) private operators;

    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    modifier authorised(bytes32 node) {
        address o = records[node].owner;
        require(o == msg.sender || operators[o][msg.sender], "ANS: Not authorised");
        _;
    }

    constructor() {
        records[0x0].owner = msg.sender; // Root node owned by deployer
    }

    function setSubnodeOwner(bytes32 node, bytes32 label, address owner_)
        external authorised(node) returns (bytes32)
    {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        records[subnode].owner = owner_;
        emit NewOwner(node, label, owner_);
        return subnode;
    }

    function setResolver(bytes32 node, address resolver_) external authorised(node) {
        records[node].resolver = resolver_;
        emit NewResolver(node, resolver_);
    }

    function setTTL(bytes32 node, uint64 ttl_) external authorised(node) {
        records[node].ttl = ttl_;
        emit NewTTL(node, ttl_);
    }

    function owner(bytes32 node)    external view returns (address) { return records[node].owner; }
    function resolver(bytes32 node) external view returns (address) { return records[node].resolver; }
    function ttl(bytes32 node)      external view returns (uint64)  { return records[node].ttl; }
    function recordExists(bytes32 node) external view returns (bool) { return records[node].owner != address(0); }
}
```

### Deployment Script (Foundry)

```bash
#!/usr/bin/env bash
# file: /root/core/scripts/deploy-ans-contracts.sh

set -euo pipefail

RPC_URL="${1:-http://localhost:8545}"
PRIVATE_KEY="${DEPLOYER_KEY:?ERROR: DEPLOYER_KEY not set}"

echo "=== Deploying AXIOLEDGER ANS Contracts ==="
echo "  RPC: $RPC_URL"

# 1. Deploy ANSRegistry
echo "  [1/3] Deploying ANSRegistry..."
REGISTRY=$(forge create \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  contracts/ANSRegistry.sol:ANSRegistry \
  --json | python3 -c "import sys,json; print(json.load(sys.stdin)['deployedTo'])")
echo "  Registry → $REGISTRY"

# 2. Deploy PublicResolver
echo "  [2/3] Deploying PublicResolver..."
RESOLVER=$(forge create \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  contracts/PublicResolver.sol:PublicResolver \
  --constructor-args "$REGISTRY" \
  --json | python3 -c "import sys,json; print(json.load(sys.stdin)['deployedTo'])")
echo "  Resolver → $RESOLVER"

# 3. Setup TLD nodes: .axq .vpx .sqx .kpx .vrq
echo "  [3/3] Setting up TLD nodes..."
for TLD in axq vpx sqx kpx vrq; do
  cast send "$REGISTRY" \
    "setSubnodeOwner(bytes32,bytes32,address)" \
    "0x$(python3 -c "print('0'*64)")" \
    "0x$(python3 -c "import hashlib; print(hashlib.new('sha3_256', b'$TLD').hexdigest())")" \
    "$REGISTRY" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" > /dev/null
  echo "  .$TLD → configured"
done

echo ""
echo "=== Deployment Complete ==="
echo "  ANS_REGISTRY_ADDRESS=$REGISTRY"
echo "  PUBLIC_RESOLVER_ADDRESS=$RESOLVER"
echo ""
echo "  Update .env with the above values, then:"
echo "  docker compose up -d"
```

---

## 11. DEPLOYMENT ROADMAP

### Bước 1 — Khởi tạo Database & Môi trường

```bash
git clone https://github.com/axioledger/ans-infrastructure
cd ans-infrastructure
cp .env.example .env
# Edit .env: điền PG_PASSWORD, DEPLOYER_KEY, etc.
docker compose up -d postgres redis
sleep 5
docker compose up -d anvil coredns ans-resolver
docker compose ps  # Verify all healthy
```

### Bước 2 — Deploy Smart Contracts

```bash
bash /root/core/scripts/deploy-ans-contracts.sh http://localhost:8545
# Copy output addresses to .env
docker compose restart ans-resolver
```

### Bước 3 — Kiểm tra Resolution

```bash
# Resolve treasury.axq
curl "http://localhost:8053/api/v1/resolve?name=treasury.axq" | python3 -m json.tool

# Register alice.axq (admin)
curl -X POST "http://localhost:8053/api/v1/register" \
  -H "Authorization: Bearer $ANS_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"alice.axq","owner":"0xABCD...","records":{"AXQ":"0xABCD..."}}'

# Health check
curl "http://localhost:8053/api/v1/health"
```

### Bước 4 — Cấu hình /etc/hosts (Dev)

```bash
# /etc/hosts — ANS entries cho devnode
# (Đã có 44 entries → 192.168.0.47)
# CoreDNS chạy tại 192.168.0.47:53

# Thêm vào /etc/resolv.conf (Linux/WSL):
nameserver 192.168.0.47
search axq vpx sqx kpx vrq
```

---

## 12. IDENTITY REFERENCE TABLE

| Trụ cột | Ticker | Layer | ANS TLD | NPM Scope | GitHub Org | Repo mẫu |
|---|---|---|---|---|---|---|
| **Axioledger** | `$AXQ` | Core Settlement / DAO | `.axq` | `@axioledger/*` | `github.com/axioledger` | `axq-core-contracts` · `axq-ans-sdk` |
| **Valiprecision** | `$VPX` | Consensus & Node Staking | `.vpx` | `@valiprecision/*` | `github.com/valiprecision` | `vpx-node-client` · `vpx-validator-kit` |
| **Sequentichain** | `$SQX` | L2 Sequencing / Rollup | `.sqx` | `@sequentichain/*` | `github.com/sequentichain` | `sqx-rollup-core` · `sqx-sequencer` |
| **Kinetoprotocol** | `$KPX` | DeFi Engine & Liquidity | `.kpx` | `@kinetoprotocol/*` | `github.com/kinetoprotocol` | `kpx-amm-router` · `kpx-rwa-vault` |
| **Veraciphers** | `$VRQ` | ZK-Proof & Privacy DID | `.vrq` | `@veraciphers/*` | `github.com/veraciphers` | `vrq-zk-circuits` · `vrq-did-resolver` |

### ANS Domain Examples (Key Addresses)

| Tên miền ANS | Trụ cột | Mục đích |
|---|---|---|
| `treasury.axq` | AXQ Hub | Treasury DAO address |
| `governance.axq` | AXQ Hub | On-chain voting endpoint |
| `rpc.axq` | AXQ Hub | JSON-RPC Hub node |
| `validator-001.vpx` | VPX | Validator node #1 identity |
| `gov-super-01.vpx` | VPX | Government Super-Validator |
| `staking.vpx` | VPX | Staking pool address |
| `sequencer.sqx` | SQX | AF_XDP Sequencer endpoint |
| `rollup.sqx` | SQX | SVM Rollup state root |
| `pool-usdc-axq.kpx` | KPX | AMM USDC/AXQ pool |
| `rwa-treasury.kpx` | KPX | RWA Treasury vault |
| `bridge.kpx` | KPX | Cross-chain Bridge |
| `did-auth.vrq` | VRQ | ZK-DID authentication |
| `kyc-gate.vrq` | VRQ | Regulator Gateway (5/7 multisig) |
| `scanner.vrq` | VRQ | Supply Chain Scanner service |

---

*ANS Spec v1.0 — AXIOLEDGER Genesis Pact Edition*  
*Tham chiếu: [`idead/Name-Service.md`](../../idead/Name-Service.md) · [`idead/Global.md`](../../idead/Global.md)*
