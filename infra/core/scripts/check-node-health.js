#!/usr/bin/env node
/**
 * check-node-health.js
 * AXIOLEDGER — Node Health Monitor & Self-Healing Agent
 *
 * Kiểm tra trạng thái RPC endpoint định kỳ. Nếu node bị treo hoặc không
 * phản hồi, tự động kích hoạt restart qua systemctl (production) hoặc
 * script cục bộ (development/localnet).
 *
 * Chạy thủ công:   node check-node-health.js
 * Chạy qua cron:   * * * * * /usr/bin/node /root/core/scripts/check-node-health.js >> /root/logs/node-health.log 2>&1
 *
 * Environment variables (override defaults):
 *   AXQ_RPC_URL          RPC endpoint (default: http://127.0.0.1:8545)
 *   AXQ_CHAIN_ID         Expected chain ID (default: 31337 = Anvil localnet)
 *   AXQ_BLOCK_STALE_SEC  Seconds before a non-advancing block is "stale" (default: 60)
 *   AXQ_RESTART_CMD      Shell command to restart node (default: systemctl restart axq-node)
 *   AXQ_HEALTH_LOG       Log file path (default: /root/logs/node-health.log)
 *   AXQ_ALERT_WEBHOOK    Optional Slack/Discord webhook URL for critical alerts
 */

'use strict';

const http    = require('http');
const https   = require('https');
const { execSync } = require('child_process');
const fs      = require('fs');
const path    = require('path');

// ── Config ────────────────────────────────────────────────────────────────────

const CFG = {
  rpcUrl:       process.env.AXQ_RPC_URL        || 'http://127.0.0.1:8545',
  chainId:      parseInt(process.env.AXQ_CHAIN_ID || '31337', 10),
  staleSec:     parseInt(process.env.AXQ_BLOCK_STALE_SEC || '60', 10),
  restartCmd:   process.env.AXQ_RESTART_CMD    || 'systemctl restart axq-node',
  logFile:      process.env.AXQ_HEALTH_LOG     || '/root/logs/node-health.log',
  alertWebhook: process.env.AXQ_ALERT_WEBHOOK  || null,
  timeoutMs:    5_000,   // 5-second RPC timeout
  maxRestarts:  3,       // stop auto-restarting after N attempts in a run
};

// State persisted across cron invocations via a small JSON file
const STATE_FILE = path.join(path.dirname(CFG.logFile), '.node-health-state.json');

// ── Logger ───────────────────────────────────────────────────────────────────

function log(level, msg) {
  const line = `[${new Date().toISOString()}] [${level}] ${msg}`;
  console.log(line);
  try {
    fs.mkdirSync(path.dirname(CFG.logFile), { recursive: true });
    fs.appendFileSync(CFG.logFile, line + '\n');
  } catch (_) { /* non-fatal */ }
}

// ── Persistent state ─────────────────────────────────────────────────────────

function loadState() {
  try { return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); }
  catch (_) { return { lastBlock: null, lastBlockAt: null, restartCount: 0, lastRestartAt: null }; }
}

function saveState(state) {
  try { fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2)); }
  catch (e) { log('WARN', `Cannot write state file: ${e.message}`); }
}

// ── RPC helper ───────────────────────────────────────────────────────────────

/**
 * Make a JSON-RPC call.
 * Returns parsed result or throws on timeout / HTTP error / RPC error.
 */
function rpcCall(method, params = []) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ jsonrpc: '2.0', method, params, id: 1 });
    const url  = new URL(CFG.rpcUrl);
    const lib  = url.protocol === 'https:' ? https : http;

    const req = lib.request({
      hostname: url.hostname,
      port:     url.port || (url.protocol === 'https:' ? 443 : 80),
      path:     url.pathname,
      method:   'POST',
      headers:  { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      timeout:  CFG.timeoutMs,
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.error) reject(new Error(`RPC error: ${JSON.stringify(json.error)}`));
          else resolve(json.result);
        } catch (e) { reject(new Error(`RPC parse error: ${e.message}`)); }
      });
    });

    req.on('timeout', () => { req.destroy(); reject(new Error(`RPC timeout after ${CFG.timeoutMs}ms`)); });
    req.on('error',   (e) => reject(new Error(`RPC connection error: ${e.message}`)));
    req.write(body);
    req.end();
  });
}

// ── Alert ─────────────────────────────────────────────────────────────────────

async function sendAlert(message) {
  if (!CFG.alertWebhook) return;
  try {
    const body = JSON.stringify({ text: `🚨 *AXIOLEDGER Node Health*\n${message}` });
    const url  = new URL(CFG.alertWebhook);
    const lib  = url.protocol === 'https:' ? https : http;
    await new Promise((resolve) => {
      const req = lib.request({ hostname: url.hostname, port: url.port, path: url.pathname,
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      }, (res) => { res.resume(); resolve(); });
      req.on('error', () => resolve());
      req.write(body);
      req.end();
    });
  } catch (_) { /* alert failure must not crash health check */ }
}

// ── Restart ───────────────────────────────────────────────────────────────────

function restartNode(state) {
  if (state.restartCount >= CFG.maxRestarts) {
    log('ERROR', `Max restart attempts (${CFG.maxRestarts}) reached — manual intervention required`);
    sendAlert(`Node at ${CFG.rpcUrl} unresponsive. Max restarts reached. MANUAL ACTION REQUIRED.`);
    return;
  }

  state.restartCount++;
  state.lastRestartAt = new Date().toISOString();

  log('WARN', `Attempting node restart (attempt ${state.restartCount}/${CFG.maxRestarts}): ${CFG.restartCmd}`);
  try {
    execSync(CFG.restartCmd, { stdio: 'pipe', timeout: 15_000 });
    log('INFO', `Restart command executed successfully`);
    sendAlert(`Node restarted (attempt ${state.restartCount}). RPC: ${CFG.rpcUrl}`);
  } catch (e) {
    log('ERROR', `Restart command failed: ${e.message}`);
    sendAlert(`Node restart FAILED: ${e.message}`);
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  log('INFO', `--- Health check start | RPC: ${CFG.rpcUrl} | staleThreshold: ${CFG.staleSec}s ---`);

  const state = loadState();
  let healthy = true;

  // ── Check 1: Liveness — can we reach the RPC? ────────────────────────────
  let chainId;
  try {
    chainId = parseInt(await rpcCall('eth_chainId'), 16);
    log('INFO', `RPC reachable. chainId: ${chainId} (expected: ${CFG.chainId})`);
  } catch (e) {
    log('ERROR', `RPC unreachable: ${e.message}`);
    healthy = false;
    restartNode(state);
    saveState(state);
    process.exit(1);
  }

  // ── Check 2: Chain ID mismatch ────────────────────────────────────────────
  if (chainId !== CFG.chainId) {
    log('ERROR', `Chain ID mismatch: got ${chainId}, expected ${CFG.chainId}`);
    sendAlert(`Chain ID mismatch at ${CFG.rpcUrl}: ${chainId} ≠ ${CFG.chainId}. Possible wrong network.`);
    healthy = false;
  }

  // ── Check 3: Block progression — detect stalled chain ────────────────────
  let blockHex;
  try {
    blockHex = await rpcCall('eth_blockNumber');
  } catch (e) {
    log('ERROR', `eth_blockNumber failed: ${e.message}`);
    healthy = false;
    restartNode(state);
    saveState(state);
    process.exit(1);
  }

  const currentBlock = parseInt(blockHex, 16);
  const now          = Date.now();

  if (state.lastBlock !== null && currentBlock === state.lastBlock) {
    const staleMs = now - new Date(state.lastBlockAt).getTime();
    const staleSec = Math.floor(staleMs / 1000);
    if (staleSec > CFG.staleSec) {
      log('WARN', `Block ${currentBlock} unchanged for ${staleSec}s (threshold: ${CFG.staleSec}s) — node may be stalled`);
      sendAlert(`Block stall detected at ${CFG.rpcUrl}. Block ${currentBlock} stuck for ${staleSec}s.`);
      healthy = false;
      restartNode(state);
    } else {
      log('INFO', `Block ${currentBlock} unchanged for ${staleSec}s — within threshold`);
    }
  } else {
    if (state.lastBlock !== null) {
      log('INFO', `Block advanced: ${state.lastBlock} → ${currentBlock}`);
    } else {
      log('INFO', `First check. Current block: ${currentBlock}`);
    }
    state.lastBlock   = currentBlock;
    state.lastBlockAt = new Date(now).toISOString();
    // Reset restart counter on healthy block advance
    state.restartCount = 0;
  }

  // ── Check 4: Peer count (optional — skip for Anvil single-node) ──────────
  try {
    const peerHex = await rpcCall('net_peerCount');
    const peers   = parseInt(peerHex, 16);
    if (peers === 0 && CFG.chainId !== 31337) {
      log('WARN', `Zero peers on non-local chain — node may be isolated`);
      sendAlert(`Zero peers detected at ${CFG.rpcUrl}. Check network connectivity.`);
    } else {
      log('INFO', `Peer count: ${peers}`);
    }
  } catch (_) {
    // net_peerCount unsupported on some clients — non-fatal
    log('INFO', `net_peerCount not supported (non-fatal)`);
  }

  saveState(state);

  if (healthy) {
    log('INFO', `Health check PASSED — block ${currentBlock}`);
    process.exit(0);
  } else {
    log('ERROR', `Health check FAILED`);
    process.exit(1);
  }
}

main().catch((e) => {
  log('ERROR', `Unhandled error: ${e.message}`);
  process.exit(1);
});
