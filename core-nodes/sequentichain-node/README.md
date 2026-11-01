# sequentichain-node — SQX Layer-2 Sequencer ($SQX)

**AXIOLEDGER · `sequentichain` pillar · ~150,000 LOC target**

> ❄️ **STATUS: FROZEN — Phase 3 (resumes after KPX L1 stabilisation)**
>
> Per the Parallel Execution Roadmap, sequentichain development is intentionally paused until `kinetoprotocol/kpx-amm-router` is fully operational on Layer 1. Resources are focused 100% on L1 DeFi stability.

## Architecture (Planned)

```
sequentichain-node/
├── src/
│   ├── sequencer/          # Transaction ordering + block production
│   ├── rollup/             # SVM Rollup execution engine
│   ├── bridge/             # L1 ↔ L2 message bridge
│   ├── network/            # P2P node communication
│   └── afxdp/              # AF_XDP NIC bypass (600k TPS path)
├── circuits/               # ZK state transition proofs
└── contracts/              # L1 bridge + rollup verifier contracts
```

## Target Performance (Phase 7 KPIs)

| Metric | Target |
|--------|--------|
| Throughput | > 600,000 TPS |
| Soft confirmation latency | < 100ms |
| Nakamoto Coefficient | > 50 |
| Validator cost | < 0.1 $AXQ/day |

## Dependencies

- `valiprecision-node` — price oracle feed for sequencer gas pricing
- `smart-contracts/vrq-circuits` — ZK state transition verifier
- `smart-contracts/kpx-liquidity` — cross-chain bridge contract

## Activation Criteria

sequentichain development resumes when:
1. ✅ `KPXRouterGateway` deployed and verified on Mainnet
2. ✅ VPX Oracle network has ≥ 10 independent validators
3. ✅ $AXQ TGE completed, DAO governance active
