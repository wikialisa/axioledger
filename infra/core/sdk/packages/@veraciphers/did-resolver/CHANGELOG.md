# @veraciphers/did-resolver

## 0.1.0

### Minor Changes

- Initial pre-release: v0.1.0 for all Core SDK packages across 5 protocol scopes.

  This is the first versioned release of the AXIOLEDGER Core SDK monorepo, establishing
  baseline semver anchors for all 15 packages. All packages exit placeholder `v0.0.0`
  and enter the active development track at `v0.1.0`.

  Packages included:

  **@axioledger scope:**

  - `ans-sdk` — ANS Resolver SDK for querying .axq .vpx .sqx .kpx .vrq domains
  - `core` — AXIOLEDGER core protocol primitives
  - `treasury-client` — Treasury management client

  **@kinetoprotocol scope:**

  - `amm` — KPX AMM Pool SDK with concentrated liquidity and anti-slippage
  - `bridge-sdk` — Cross-chain bridge SDK
  - `rwa-vault` — Real-world asset vault integration

  **@sequentichain scope:**

  - `rollup-kit` — L2 rollup utilities (Phase 3 — frozen, placeholder)
  - `sequencer` — Sequencer node client (Phase 3 — frozen, placeholder)
  - `svm-adapter` — SVM adapter layer (Phase 3 — frozen, placeholder)

  **@valiprecision scope:**

  - `consensus-lib` — Oracle consensus library
  - `node-client` — VPX node HTTP client
  - `validator-kit` — Validator tooling

  **@veraciphers scope:**

  - `did-resolver` — DID resolution for VRQ identities
  - `supply-scanner` — Supply chain integrity scanner
  - `zk-proof` — ZK proof generation and verification utilities

  Note: @sequentichain packages are versioned but remain functionally frozen pending
  Phase 3 activation (awaiting $AXQ stable on Sepolia).
