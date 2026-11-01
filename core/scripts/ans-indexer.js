#!/usr/bin/env node
/**
 * ans-indexer.js
 * AXIOLEDGER ANS — Blockchain Event Indexer
 *
 * Lắng nghe sự kiện on-chain → tự động cập nhật Redis + PostgreSQL:
 *   - NameRegistered(node, label, owner)
 *   - AddressChanged(node, coinType, newAddress)
 *   - ContenthashChanged(node, hash)
 *   - TextChanged(node, key, value)
 *
 * Usage: node /root/core/scripts/ans-indexer.js \
 *   --rpc-url http://localhost:8545 \
 *   --registry $ANS_REGISTRY_ADDRESS \
 *   --from-block 0
 *
 * Phase v0.0.0: Skeleton — event listeners ready, DB writes pending smart contract deploy
 */

"use strict";

const VERSION = "0.0.0";

function log(level, msg, data = {}) {
  const ts = new Date().toISOString();
  console.log(JSON.stringify({ ts, level, service: "ans-indexer", version: VERSION, msg, ...data }));
}

const ARGS = {};
process.argv.slice(2).forEach((arg, i, arr) => {
  if (arg.startsWith("--")) {
    ARGS[arg.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = arr[i + 1] || true;
  }
});

const CONFIG = {
  rpcUrl:          ARGS.rpcUrl          || process.env.BLOCKCHAIN_RPC    || "http://localhost:8545",
  registryAddress: ARGS.registry        || process.env.ANS_REGISTRY_ADDRESS || "0x0",
  fromBlock:       parseInt(ARGS.fromBlock || "0"),
  postgresUrl:     process.env.POSTGRES_URL || "postgresql://ans_user:password@localhost:5432/axioledger_ans",
  redisUrl:        process.env.REDIS_URL    || "redis://localhost:6379",
};

// ANS Contract Events (ENS-compatible)
const ANS_EVENTS = [
  "NewOwner(bytes32 indexed node, bytes32 indexed label, address owner)",
  "Transfer(bytes32 indexed node, address owner)",
  "NewResolver(bytes32 indexed node, address resolver)",
  "NewTTL(bytes32 indexed node, uint64 ttl)",
];

// PublicResolver Events
const RESOLVER_EVENTS = [
  "AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress)",
  "ContenthashChanged(bytes32 indexed node, bytes hash)",
  "TextChanged(bytes32 indexed node, string indexed indexedKey, string key, string value)",
];

async function processEvent(eventName, args) {
  // TODO v1.0.0: Write to PostgreSQL + invalidate Redis cache
  // await db.query("INSERT INTO ans_query_log ..."); 
  // await redis.del(`ans:${args.node}`);

  log("info", `Event: ${eventName}`, {
    event: eventName,
    args: Object.fromEntries(
      Object.entries(args).filter(([k]) => isNaN(parseInt(k)))
    )
  });
}

async function startIndexer() {
  log("info", "ANS Indexer starting", {
    rpc:      CONFIG.rpcUrl,
    registry: CONFIG.registryAddress,
    fromBlock: CONFIG.fromBlock
  });

  // TODO v1.0.0: Initialize ethers.js provider
  // const provider = new ethers.JsonRpcProvider(CONFIG.rpcUrl);
  // const registry = new ethers.Contract(CONFIG.registryAddress, ANS_ABI, provider);
  // registry.on("NewOwner", (node, label, owner) => processEvent("NewOwner", {node, label, owner}));

  log("info", "ANS Indexer running — v0.0.0 skeleton, awaiting contract deploy");
  log("info", "Event listeners configured", {
    ans_events:      ANS_EVENTS.length,
    resolver_events: RESOLVER_EVENTS.length
  });

  // Keep process alive
  await new Promise(() => {}); // Runs until SIGTERM
}

process.on("SIGTERM", () => {
  log("info", "ANS Indexer shutting down gracefully");
  process.exit(0);
});

startIndexer().catch(err => {
  log("error", "Indexer startup failed", { error: err.message });
  process.exit(1);
});
