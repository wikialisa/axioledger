#!/usr/bin/env node
/**
 * integrity-check.js
 * AXIOLEDGER Security — File Integrity Monitoring
 *
 * Cron: 0 0 * * * root /usr/bin/node /root/core/scripts/integrity-check.js >> /root/logs/security.log 2>&1
 *
 * Quét toàn vẹn tệp tin /root — phục vụ Legal Audit Trail
 * Thuật toán: SHA-256 checksum mỗi file quan trọng
 * So sánh với baseline snapshot → cảnh báo nếu có thay đổi bất thường
 *
 * Alert channels (configure via environment variables):
 *   ALERT_WEBHOOK_URL   — Generic HTTP POST webhook (e.g. Slack, Teams, custom endpoint)
 *   ALERT_DISCORD_URL   — Discord webhook URL
 *   ALERT_PAGERDUTY_KEY — PagerDuty Events API v2 integration key (triggers P1 incident)
 */

"use strict";

const crypto = require("crypto");
const fs     = require("fs");
const path   = require("path");
const https  = require("https");
const http   = require("http");

const VERSION   = "0.1.0";
const SCAN_ROOT = process.env.SCAN_ROOT || "/root";
const BASELINE  = process.env.BASELINE_FILE || "/root/logs/integrity-baseline.json";

// ── Alert channel configuration ──────────────────────────────────────────────

const ALERT_WEBHOOK_URL   = process.env.ALERT_WEBHOOK_URL   || null;
const ALERT_DISCORD_URL   = process.env.ALERT_DISCORD_URL   || null;
const ALERT_PAGERDUTY_KEY = process.env.ALERT_PAGERDUTY_KEY || null;

// Files and directories to monitor
const MONITOR_PATHS = [
  "/root/core/github/bootstrap.sh",
  "/root/core/github/modal.sh",
  "/root/core/github/w1-create-repo.sh",
  "/root/core/github/w2-security-patch.sh",
  "/root/core/github/w3-branch-protection.sh",
  "/root/core/github/w4-rotate-secrets.sh",
  "/root/core/github/w5-projects.sh",
  "/root/core/github/w6-trigger-actions.sh",
  "/root/core/github/w7-audit.sh",
  "/root/core/api/api-schema-v0.0.0.md",
  "/root/core/api/ans-service-spec.md",
  "/root/ssl/gpia/root-ca/gpia-root.crt",
  "/root/ssl/gpia/gateway/gateway.crt",
  "/etc/nginx/sites-available/axioledger-ecosystem.conf",
];

// ── Logging ───────────────────────────────────────────────────────────────────

function log(level, msg, data = {}) {
  const ts = new Date().toISOString();
  console.log(JSON.stringify({ ts, level, service: "integrity-check", version: VERSION, msg, ...data }));
}

// ── File hashing ──────────────────────────────────────────────────────────────

function sha256File(filePath) {
  try {
    const content = fs.readFileSync(filePath);
    return crypto.createHash("sha256").update(content).digest("hex");
  } catch {
    return null;
  }
}

// ── Baseline I/O ──────────────────────────────────────────────────────────────

function loadBaseline() {
  try {
    return JSON.parse(fs.readFileSync(BASELINE, "utf8"));
  } catch {
    return null;
  }
}

function saveBaseline(snapshot) {
  fs.mkdirSync(path.dirname(BASELINE), { recursive: true });
  fs.writeFileSync(BASELINE, JSON.stringify(snapshot, null, 2), "utf8");
}

// ── HTTP helper ───────────────────────────────────────────────────────────────

/**
 * POST a JSON body to a URL. Resolves with the status code.
 * Non-2xx responses do NOT reject — alerting must never crash the monitor.
 */
function postJson(url, body) {
  return new Promise((resolve) => {
    const payload = JSON.stringify(body);
    const parsed  = new URL(url);
    const lib     = parsed.protocol === "https:" ? https : http;
    const options = {
      hostname: parsed.hostname,
      port:     parsed.port || (parsed.protocol === "https:" ? 443 : 80),
      path:     parsed.pathname + parsed.search,
      method:   "POST",
      headers:  { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(payload) },
    };
    const req = lib.request(options, (res) => resolve(res.statusCode));
    req.on("error", (err) => {
      log("warn", "Alert HTTP request failed", { url, error: err.message });
      resolve(null);
    });
    req.setTimeout(8000, () => { req.destroy(); resolve(null); });
    req.write(payload);
    req.end();
  });
}

// ── Alert dispatch ────────────────────────────────────────────────────────────

/**
 * Send a RED alert to all configured channels.
 * @param {object[]} alerts  Array of { type, path, prev?, curr? }
 */
async function dispatchAlerts(alerts) {
  const summary = `🚨 AXIOLEDGER FIM ALERT — ${alerts.length} integrity violation(s) detected`;
  const detail  = alerts.map(a => `[${a.type}] ${a.path}`).join("\n");
  const ts      = new Date().toISOString();

  const dispatched = [];

  // ── Generic webhook (Slack-compatible JSON) ──────────────────────────────
  if (ALERT_WEBHOOK_URL) {
    const body = {
      text: summary,
      attachments: [{
        color:  "danger",
        title:  "File Integrity Monitor",
        text:   detail,
        footer: `integrity-check v${VERSION} • ${ts}`,
        fields: alerts.map(a => ({ title: a.type, value: a.path, short: false })),
      }],
    };
    const status = await postJson(ALERT_WEBHOOK_URL, body);
    dispatched.push({ channel: "webhook", status });
    log("info", "Webhook alert dispatched", { status });
  }

  // ── Discord webhook ──────────────────────────────────────────────────────
  if (ALERT_DISCORD_URL) {
    const body = {
      username: "AXIOLEDGER FIM",
      content:  summary,
      embeds: [{
        title:       "File Integrity Violations",
        description: detail,
        color:       15158332, // red
        footer:      { text: `integrity-check v${VERSION} • ${ts}` },
        fields:      alerts.map(a => ({ name: a.type, value: a.path, inline: false })),
      }],
    };
    const status = await postJson(ALERT_DISCORD_URL, body);
    dispatched.push({ channel: "discord", status });
    log("info", "Discord alert dispatched", { status });
  }

  // ── PagerDuty Events API v2 ───────────────────────────────────────────────
  if (ALERT_PAGERDUTY_KEY) {
    const body = {
      routing_key:  ALERT_PAGERDUTY_KEY,
      event_action: "trigger",
      payload: {
        summary:   summary,
        source:    "integrity-check.js",
        severity:  "critical",
        timestamp: ts,
        custom_details: { violations: alerts },
      },
      dedup_key: `fim-alert-${ts.slice(0, 10)}`, // one incident per day max
    };
    const status = await postJson("https://events.pagerduty.com/v2/enqueue", body);
    dispatched.push({ channel: "pagerduty", status });
    log("info", "PagerDuty alert dispatched", { status });
  }

  if (dispatched.length === 0) {
    log("warn", "No alert channels configured — set ALERT_WEBHOOK_URL, ALERT_DISCORD_URL, or ALERT_PAGERDUTY_KEY");
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  log("info", "File Integrity Monitor — starting scan", { paths: MONITOR_PATHS.length });

  const current_snapshot = {};
  for (const fp of MONITOR_PATHS) {
    const hash = sha256File(fp);
    current_snapshot[fp] = { sha256: hash, exists: hash !== null };
  }

  const baseline = loadBaseline();

  if (!baseline) {
    log("info", "No baseline found — creating initial snapshot");
    saveBaseline({ created_at: new Date().toISOString(), files: current_snapshot });
    log("info", "Baseline created", { files: Object.keys(current_snapshot).length });
    return;
  }

  // Compare
  const alerts = [];
  for (const [fp, curr] of Object.entries(current_snapshot)) {
    const prev = baseline.files[fp];
    if (!prev) {
      alerts.push({ type: "NEW_FILE", path: fp });
    } else if (prev.exists && !curr.exists) {
      alerts.push({ type: "FILE_DELETED", path: fp });
    } else if (curr.exists && prev.sha256 !== curr.sha256) {
      alerts.push({ type: "HASH_CHANGED", path: fp, prev: prev.sha256, curr: curr.sha256 });
    }
  }

  if (alerts.length === 0) {
    log("info", "Integrity check PASSED — all files unchanged", { files_checked: MONITOR_PATHS.length });
  } else {
    for (const alert of alerts) {
      log("warn", "INTEGRITY ALERT", alert);
    }
    log("warn", "Integrity check FLAGGED", { alerts: alerts.length });
    await dispatchAlerts(alerts);
  }

  // Update baseline with current snapshot
  saveBaseline({ created_at: new Date().toISOString(), files: current_snapshot });
}

main().catch(err => {
  console.error(JSON.stringify({ ts: new Date().toISOString(), level: "error", service: "integrity-check", error: err.message }));
  process.exit(1);
});
