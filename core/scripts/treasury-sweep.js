#!/usr/bin/env node
/**
 * treasury-sweep.js
 * AXIOLEDGER — Automated Treasury Fee Sweep
 *
 * Gom phí giao dịch định kỳ từ các vault vào R&D Treasury bằng cách
 * gọi hàm chuyển token qua viem WalletClient.
 *
 * Chạy thủ công:   node treasury-sweep.js
 * Chạy qua cron:   0 0 * * 0 /usr/bin/node /root/core/scripts/treasury-sweep.js >> /root/logs/treasury-sweep.log 2>&1
 *                  (mỗi Chủ nhật lúc 00:00 UTC)
 *
 * Required environment variables:
 *   AXQ_RPC_URL          RPC endpoint (e.g. http://127.0.0.1:8545)
 *   SWEEP_PRIVATE_KEY    Private key of sweep operator (hex, no 0x prefix)
 *                        → Must be set via secret manager — NEVER hardcode
 *   AXQ_TOKEN_ADDRESS    AXQToken contract address
 *   SWEEP_TARGET         Destination address (rdTreasuryVault)
 *   SWEEP_SOURCES        Comma-separated addresses to sweep FROM
 *
 * Optional:
 *   SWEEP_MIN_BALANCE    Minimum token balance (wei) to trigger sweep (default: 1e18 = 1 AXQ)
 *   AXQ_HEALTH_LOG       Log file (default: /root/logs/treasury-sweep.log)
 *   AXQ_ALERT_WEBHOOK    Slack/Discord webhook for notifications
 *   SWEEP_DRY_RUN        If "true", simulate but do not send transactions
 */

'use strict';

const https = require('https');
const http  = require('http');
const fs    = require('fs');
const path  = require('path');

// ── Config ────────────────────────────────────────────────────────────────────

const CFG = {
  rpcUrl:     process.env.AXQ_RPC_URL       || 'http://127.0.0.1:8545',
  privateKey: process.env.SWEEP_PRIVATE_KEY || null,
  tokenAddr:  process.env.AXQ_TOKEN_ADDRESS || null,
  target:     process.env.SWEEP_TARGET      || null,
  sources:    (process.env.SWEEP_SOURCES    || '').split(',').map(s => s.trim()).filter(Boolean),
  minBalance: BigInt(process.env.SWEEP_MIN_BALANCE || String(1n * 10n ** 18n)),
  logFile:    process.env.AXQ_HEALTH_LOG    || '/root/logs/treasury-sweep.log',
  webhook:    process.env.AXQ_ALERT_WEBHOOK || null,
  dryRun:     process.env.SWEEP_DRY_RUN === 'true',
};

// ── Logger ────────────────────────────────────────────────────────────────────

function log(level, msg, data = {}) {
  const extra = Object.keys(data).length ? ' ' + JSON.stringify(data) : '';
  const line  = `[${new Date().toISOString()}] [${level}] ${msg}${extra}`;
  console.log(line);
  try {
    fs.mkdirSync(path.dirname(CFG.logFile), { recursive: true });
    fs.appendFileSync(CFG.logFile, line + '\n');
  } catch (_) { /* non-fatal */ }
}

// ── JSON-RPC helper ───────────────────────────────────────────────────────────

let _rpcId = 1;
function rpcCall(method, params = []) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ jsonrpc: '2.0', method, params, id: _rpcId++ });
    const url  = new URL(CFG.rpcUrl);
    const lib  = url.protocol === 'https:' ? https : http;
    const req  = lib.request({
      hostname: url.hostname,
      port:     url.port || (url.protocol === 'https:' ? 443 : 80),
      path:     url.pathname,
      method:   'POST',
      headers:  { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      timeout:  10_000,
    }, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try {
          const j = JSON.parse(d);
          if (j.error) reject(new Error(`RPC: ${JSON.stringify(j.error)}`));
          else resolve(j.result);
        } catch (e) { reject(e); }
      });
    });
    req.on('timeout', () => { req.destroy(); reject(new Error('RPC timeout')); });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Minimal ABI encoding ──────────────────────────────────────────────────────
// We use raw eth_call / eth_sendRawTransaction to avoid runtime dependencies.
// ABI: balanceOf(address) → uint256
//      transfer(address,uint256) → bool

function padHex(hex, bytes) {
  return hex.replace('0x', '').padStart(bytes * 2, '0');
}

function encodeBalanceOf(account) {
  // keccak256("balanceOf(address)") = 0x70a08231
  return '0x70a08231' + padHex(account, 32);
}

function encodeTransfer(to, amount) {
  // keccak256("transfer(address,uint256)") = 0xa9059cbb
  return '0xa9059cbb' + padHex(to, 32) + padHex(amount.toString(16), 32);
}

async function getBalance(tokenAddr, account) {
  const result = await rpcCall('eth_call', [{
    to:   tokenAddr,
    data: encodeBalanceOf(account),
  }, 'latest']);
  return BigInt(result || '0x0');
}

// ── Webhook alert ─────────────────────────────────────────────────────────────

function sendAlert(message) {
  if (!CFG.webhook) return Promise.resolve();
  const body = JSON.stringify({ text: `💰 *AXIOLEDGER Treasury Sweep*\n${message}` });
  return new Promise((resolve) => {
    try {
      const url = new URL(CFG.webhook);
      const lib = url.protocol === 'https:' ? https : http;
      const req = lib.request({ hostname: url.hostname, port: url.port, path: url.pathname,
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      }, (res) => { res.resume(); resolve(); });
      req.on('error', () => resolve());
      req.write(body);
      req.end();
    } catch (_) { resolve(); }
  });
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  log('INFO', '--- Treasury sweep start ---', {
    rpc: CFG.rpcUrl,
    target: CFG.target,
    sources: CFG.sources.length,
    dryRun: CFG.dryRun,
  });

  // ── Validate config ───────────────────────────────────────────────────────
  const missing = [];
  if (!CFG.privateKey) missing.push('SWEEP_PRIVATE_KEY');
  if (!CFG.tokenAddr)  missing.push('AXQ_TOKEN_ADDRESS');
  if (!CFG.target)     missing.push('SWEEP_TARGET');
  if (CFG.sources.length === 0) missing.push('SWEEP_SOURCES');

  if (missing.length > 0) {
    log('ERROR', `Missing required environment variables: ${missing.join(', ')}`);
    log('ERROR', 'Set via secret manager — never hardcode private keys in source');
    process.exit(1);
  }

  if (CFG.dryRun) {
    log('WARN', 'DRY RUN mode — transactions will NOT be sent');
  }

  // ── Load viem dynamically (optional — fallback to raw RPC if not available) ─
  let sendTransaction;
  try {
    // Use viem if available (matches SDK dependency)
    const { createWalletClient, createPublicClient, http: viemHttp,
            privateKeyToAccount, parseUnits } = require('viem');
    const { sepolia, mainnet } = require('viem/chains');

    const account = privateKeyToAccount(`0x${CFG.privateKey}`);
    const chainId = parseInt(await rpcCall('eth_chainId'), 16);
    const chain   = chainId === 1 ? mainnet : sepolia;

    const walletClient = createWalletClient({ account, chain, transport: viemHttp(CFG.rpcUrl) });

    sendTransaction = async (from, to, amount) => {
      if (CFG.dryRun) {
        log('INFO', `[DRY RUN] Would transfer ${amount} tokens from ${from} to ${to}`);
        return '0x0000000000000000000000000000000000000000000000000000000000000000';
      }
      // Note: transfer() is called FROM the operator's account, which must have
      // an allowance set by `from`, OR `from` must be the operator itself.
      // For vault sweeps, the operator wallet IS the vault controller.
      const ABI = [{ name: 'transfer', type: 'function', stateMutability: 'nonpayable',
        inputs: [{ name: 'to', type: 'address' }, { name: 'amount', type: 'uint256' }],
        outputs: [{ name: '', type: 'bool' }] }];
      return walletClient.writeContract({
        address:      CFG.tokenAddr,
        abi:          ABI,
        functionName: 'transfer',
        args:         [to, amount],
        account,
      });
    };

    log('INFO', `Using viem WalletClient. Operator: ${account.address}`);
  } catch (e) {
    // viem not installed — use raw eth_sendRawTransaction
    // Production note: implement proper tx signing with ethereumjs-tx or similar
    log('WARN', `viem not available (${e.message}) — raw RPC signing not implemented`);
    log('WARN', 'Install viem: pnpm add viem   or run from packages/axq-sdk context');
    process.exit(1);
  }

  // ── Sweep loop ────────────────────────────────────────────────────────────
  let totalSwept = 0n;
  const results  = [];

  for (const source of CFG.sources) {
    log('INFO', `Checking source: ${source}`);

    let balance;
    try {
      balance = await getBalance(CFG.tokenAddr, source);
    } catch (e) {
      log('ERROR', `Failed to read balance for ${source}: ${e.message}`);
      results.push({ source, status: 'ERROR', error: e.message });
      continue;
    }

    log('INFO', `Balance of ${source}: ${balance} wei (${Number(balance) / 1e18} AXQ)`);

    if (balance < CFG.minBalance) {
      log('INFO', `Balance below minimum (${CFG.minBalance} wei) — skipping`);
      results.push({ source, status: 'SKIP', balance: balance.toString() });
      continue;
    }

    try {
      const txHash = await sendTransaction(source, CFG.target, balance);
      log('INFO', `Swept ${balance} wei from ${source} → ${CFG.target}`, { txHash });
      totalSwept += balance;
      results.push({ source, status: 'SWEPT', amount: balance.toString(), txHash });
    } catch (e) {
      log('ERROR', `Transfer from ${source} failed: ${e.message}`);
      results.push({ source, status: 'FAILED', error: e.message });
    }
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  const swept   = results.filter(r => r.status === 'SWEPT').length;
  const skipped = results.filter(r => r.status === 'SKIP').length;
  const failed  = results.filter(r => r.status === 'FAILED' || r.status === 'ERROR').length;

  const summary = `Sweep complete. Swept: ${swept} | Skipped: ${skipped} | Failed: ${failed} | Total: ${Number(totalSwept) / 1e18} AXQ`;
  log('INFO', summary);

  if (swept > 0 || failed > 0) {
    const emoji = failed > 0 ? '⚠️' : '✅';
    await sendAlert(`${emoji} ${summary}\nTarget: ${CFG.target}`);
  }

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  log('ERROR', `Unhandled error: ${e.message}`);
  process.exit(1);
});
