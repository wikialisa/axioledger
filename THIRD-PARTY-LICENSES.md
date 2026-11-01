# Third-Party Licenses — AXIOLEDGER Monorepo

This document lists all third-party software included in or used by the AXIOLEDGER monorepo, along with their respective licenses.

---

## JavaScript / TypeScript Packages

### viem `^2.17.0`
- **License:** MIT
- **Repository:** https://github.com/wevm/viem
- **Used by:** `packages/axq-sdk`, `apps/axiopass-wallet`, `apps/axq-governance-ui`

### Next.js `^15.x`
- **License:** MIT
- **Repository:** https://github.com/vercel/next.js
- **Used by:** `apps/axiopass-wallet`, `apps/axq-governance-ui`

### React `^18.x` / React DOM
- **License:** MIT
- **Repository:** https://github.com/facebook/react
- **Used by:** `apps/axiopass-wallet`, `apps/axq-governance-ui`, `design-system`

### TypeScript `^5.x`
- **License:** Apache-2.0
- **Repository:** https://github.com/microsoft/TypeScript
- **Used by:** all TypeScript packages and apps

### Storybook `^8.x`
- **License:** MIT
- **Repository:** https://github.com/storybookjs/storybook
- **Used by:** `design-system`

### Vite `^5.x`
- **License:** MIT
- **Repository:** https://github.com/vitejs/vite
- **Used by:** `design-system`

### Jest `^29.x` / `@testing-library/*`
- **License:** MIT
- **Repository:** https://github.com/jestjs/jest
- **Used by:** `design-system`, `packages/axq-sdk`

### Turborepo
- **License:** MIT
- **Repository:** https://github.com/vercel/turborepo
- **Used by:** monorepo build orchestration (`turbo.json`)

### pnpm
- **License:** MIT
- **Repository:** https://github.com/pnpm/pnpm
- **Used by:** monorepo package management

---

## Java / Maven Packages (`packages/swift-bridge`)

### OkHttp3 `4.12.0` (com.squareup.okhttp3)
- **License:** Apache-2.0
- **Repository:** https://github.com/square/okhttp

### Gson `2.9.1` (com.google.code.gson)
- **License:** Apache-2.0
- **Repository:** https://github.com/google/gson

### SLF4J `2.0.0` / Reload4j `1.2.22`
- **License:** MIT (SLF4J) / Apache-2.0 (Reload4j)
- **Repository:** https://www.slf4j.org / https://github.com/qos-ch/reload4j

### Swagger Annotations `2.1.13` (io.swagger.core.v3)
- **License:** Apache-2.0
- **Repository:** https://github.com/swagger-api/swagger-core

### JAXB API `2.3.0` (javax.xml.bind)
- **License:** CDDL-1.1 / GPL-2.0-with-classpath-exception
- **Repository:** https://github.com/javaee/jaxb-v2

### JUnit Jupiter `5.10.2`
- **License:** EPL-2.0
- **Repository:** https://github.com/junit-team/junit5

### Mockito `5.11.0`
- **License:** MIT
- **Repository:** https://github.com/mockito/mockito

---

## Solidity / Smart Contract Libraries

### OpenZeppelin Contracts `v5.7.0`
- **License:** MIT
- **Repository:** https://github.com/OpenZeppelin/openzeppelin-contracts
- **Used by:** `smart-contracts/axioledger-system`

### forge-std `v1.16.2`
- **License:** MIT
- **Repository:** https://github.com/foundry-rs/forge-std
- **Used by:** `smart-contracts/axioledger-system` (test/dev only)

---

## SWIFT SDK Notice

The `packages/swift-bridge/` module integrates with the **SWIFT Security SDK** (proprietary, `com.swift.commons.oauth:swift-security-sdk:2.17.5-6`). This SDK is **not redistributed** in this repository and must be installed separately via SWIFT's developer portal. Its use is governed by the SWIFT Developer License Agreement.

---

*Generated: 2026-09-03 — AXIOLEDGER Core Engineering*
