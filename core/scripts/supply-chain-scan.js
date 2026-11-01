#!/usr/bin/env node
/**
 * supply-chain-scan.js
 * AXIOLEDGER VRQ — Supply Chain Scanner
 *
 * Cron: */15 * * * * root /usr/bin/node /root/core/scripts/supply-chain-scan.js >> /root/logs/security.log 2>&1
 *
 * Quét DApp/npm packages phát hiện Typosquatting và mã độc
 * - Kiểm tra known malicious package list
 * - So sánh checksum packages với npm registry
 * - Phát hiện bất thường (unexpected network calls, file writes)
 * - Phase v1.0.0+: AI behavior prediction model
 */

"use strict";

const VERSION = "0.0.0";

function log(level, msg, data = {}) {
  const ts = new Date().toISOString();
  console.log(JSON.stringify({ ts, level, service: "supply-chain-scan", version: VERSION, msg, ...data }));
}

// Known malicious / typosquatting patterns (seed list — expanded via VRQ network)
const TYPOSQUAT_PATTERNS = [
  // Axioledger ecosystem
  { pattern: /axioledg[e3]r/i,     reason: "Axioledger typosquat" },
  { pattern: /axiol[e3]dger/i,     reason: "Axioledger typosquat" },
  { pattern: /valiprecisi[o0]n/i,  reason: "Valiprecision typosquat" },
  { pattern: /s[e3]quentichain/i,  reason: "Sequentichain typosquat" },
  { pattern: /kin[e3]toprotocol/i, reason: "Kinetoprotocol typosquat" },
  { pattern: /v[e3]raciphers/i,    reason: "Veraciphers typosquat" },
  // Common DeFi typosquats
  { pattern: /@metamask-/i,        reason: "MetaMask scope squatting" },
  { pattern: /0xethers/i,          reason: "Ethers.js typosquat" },
  { pattern: /web3-utils-safe/i,   reason: "Web3 utils typosquat" },
  { pattern: /hardhat-typosquat/i, reason: "Hardhat typosquat" },
];

// Suspicious file patterns in package.json scripts
const SUSPICIOUS_SCRIPTS = [
  /curl.*\|.*sh/,
  /wget.*\|.*bash/,
  /base64.*-d.*\|/,
  /eval\s*\(/,
  /require\s*\(\s*['"]child_process['"]\s*\)/,
];

async function scanPackage(packageName, version = "latest") {
  // TODO v1.0.0: Fetch from npm registry and analyze
  // const res = await fetch(`https://registry.npmjs.org/${packageName}/${version}`);
  // const pkg = await res.json();
  // return analyzePackage(pkg);

  log("debug", "scanPackage() — v0.0.0 skeleton", { packageName, version });
  return { status: "skipped_v0", threat_level: "unknown" };
}

function checkTyposquat(name) {
  for (const { pattern, reason } of TYPOSQUAT_PATTERNS) {
    if (pattern.test(name)) {
      return { flagged: true, reason };
    }
  }
  return { flagged: false };
}

function checkSuspiciousScripts(scripts = {}) {
  const findings = [];
  for (const [scriptName, scriptContent] of Object.entries(scripts)) {
    for (const pattern of SUSPICIOUS_SCRIPTS) {
      if (pattern.test(scriptContent)) {
        findings.push({ script: scriptName, pattern: pattern.toString() });
      }
    }
  }
  return findings;
}

async function main() {
  log("info", "Supply Chain Scanner — starting scan", {
    patterns: TYPOSQUAT_PATTERNS.length,
    scan_type: "scheduled_15min"
  });

  // Phase v0.0.0: Scan local package.json files if present
  const targets = [
    "/root/core/sdk/package.json",
  ];

  let total_scanned = 0;
  let total_flagged = 0;

  for (const target of targets) {
    try {
      const fs = require("fs");
      if (!fs.existsSync(target)) continue;

      const pkg = JSON.parse(fs.readFileSync(target, "utf8"));
      total_scanned++;

      // Check name typosquat
      if (pkg.name) {
        const typo = checkTyposquat(pkg.name);
        if (typo.flagged) {
          log("warn", "TYPOSQUAT DETECTED", { file: target, name: pkg.name, reason: typo.reason });
          total_flagged++;
        }
      }

      // Check dependencies
      const deps = { ...pkg.dependencies, ...pkg.devDependencies };
      for (const depName of Object.keys(deps)) {
        const typo = checkTyposquat(depName);
        if (typo.flagged) {
          log("warn", "SUSPICIOUS DEPENDENCY", { file: target, dep: depName, reason: typo.reason });
          total_flagged++;
        }
      }

      // Check scripts
      if (pkg.scripts) {
        const findings = checkSuspiciousScripts(pkg.scripts);
        if (findings.length > 0) {
          log("warn", "SUSPICIOUS SCRIPTS", { file: target, findings });
          total_flagged += findings.length;
        }
      }

    } catch (err) {
      log("error", "Failed to scan target", { target, error: err.message });
    }
  }

  const status = total_flagged > 0 ? "THREATS_DETECTED" : "CLEAN";
  log("info", "Supply Chain Scan complete", {
    scanned: total_scanned,
    flagged: total_flagged,
    status
  });

  if (total_flagged > 0) {
    process.exit(2); // Non-zero exit triggers cron alert
  }
}

main().catch(err => {
  console.error(JSON.stringify({ ts: new Date().toISOString(), level: "error", service: "supply-chain-scan", error: err.message }));
  process.exit(1);
});
