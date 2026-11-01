# valiprecision-node — VPX Oracle ($VPX)

**AXIOLEDGER · `valiprecision` pillar · ~120,000 LOC target**

Off-chain price aggregation daemon that pushes validated prices to the `VPXOracleFeed` smart contract on AXIOLEDGER.

## Status

✅ **v1.0.0 — Implemented & tested.** See the live implementation at [`valiprecision/vpx-node-client`](https://github.com/valiprecision/vpx-node-client).

## Architecture

```
valiprecision-node/
├── src/
│   ├── oracle-node.js          # Main daemon (node-cron, 60s cycle)
│   ├── feeds/
│   │   ├── price-feed.js       # Binance + CoinGecko + Kraken median aggregator
│   │   └── on-chain-pusher.js  # Push to VPXOracleFeed (retry + heartbeat)
│   └── utils/
│       └── logger.js           # Winston structured JSON logging
├── src/__tests__/              # Jest unit tests (9 tests, ~90% coverage)
└── contracts/
    └── VPXOracleFeed.sol       # On-chain feed contract
```

## Supported Assets

| Symbol | Sources | Notes |
|--------|---------|-------|
| `ETH` | Binance, CoinGecko, Kraken | |
| `BTC` | Binance, CoinGecko, Kraken | |
| `AXQ` | Binance, CoinGecko | Mock until CEX listing |

## Push Conditions

| Condition | Threshold |
|-----------|-----------|
| Price deviation | > 0.1% |
| Heartbeat interval | Every 5 minutes |

## Roadmap (Phase 5+)

- [ ] Expand to 50+ assets
- [ ] Add cross-validation with additional CEX/DEX sources
- [ ] Implement TWAP (Time-Weighted Average Price) for manipulation resistance
- [ ] P2P oracle network with on-chain aggregation (Nakamoto Coefficient target: > 50)
- [ ] AF_XDP NIC bypass for sub-millisecond price ingestion (sequentichain integration)
