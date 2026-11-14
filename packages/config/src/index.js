"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MAIL_CONFIG = exports.EVM_CONTRACTS = exports.SEEDS = exports.PROGRAM_IDS = exports.DEFAULT_API_ENDPOINT = exports.TRON_NILE_TESTNET = exports.TRON_FULL_HOST = exports.APPCHAIN_RPC_MAINNET = exports.APPCHAIN_RPC_LOCAL = exports.SOLANA_RPC_MAINNET = exports.SOLANA_RPC_DEVNET = exports.checkFeature = exports.requireFeature = exports.features = void 0;
// ─── Feature Flags ────────────────────────────────────────────────────────────
var features_js_1 = require("./features.js");
Object.defineProperty(exports, "features", { enumerable: true, get: function () { return features_js_1.features; } });
Object.defineProperty(exports, "requireFeature", { enumerable: true, get: function () { return features_js_1.requireFeature; } });
Object.defineProperty(exports, "checkFeature", { enumerable: true, get: function () { return features_js_1.checkFeature; } });
// ─── RPC Endpoints ────────────────────────────────────────────────────────────
exports.SOLANA_RPC_DEVNET = "https://api.devnet.solana.com";
exports.SOLANA_RPC_MAINNET = "https://api.mainnet-beta.solana.com";
/** App-Chain Genesis (EVM, Chain ID: 1337 local / 1 mainnet) */
exports.APPCHAIN_RPC_LOCAL = "http://localhost:8545";
exports.APPCHAIN_RPC_MAINNET = "https://rpc.${BRAND_DOMAIN}";
exports.TRON_FULL_HOST = "https://api.trongrid.io";
exports.TRON_NILE_TESTNET = "https://nile.trongrid.io";
exports.DEFAULT_API_ENDPOINT = "https://dev-api.${BRAND_DOMAIN}";
// ─── Solana Program IDs ───────────────────────────────────────────────────────
exports.PROGRAM_IDS = {
    P2P_ESCROW: "ESCRw1111111111111111111111111111111111111111",
    MINT_GOVERNANCE: "MINTg1111111111111111111111111111111111111111",
    AMM_SWAP: "AMMSw1111111111111111111111111111111111111111",
    TREASURY_RBS: "TRBSr1111111111111111111111111111111111111111",
};
// ─── Seed PDA prefixes ────────────────────────────────────────────────────────
exports.SEEDS = {
    ESCROW_VAULT: Buffer.from("escrow_vault"),
    ORDER_STATE: Buffer.from("order_state"),
    MINT_AUTHORITY: Buffer.from("mint_authority"),
    TREASURY_VAULT: Buffer.from("treasury_vault"),
};
// ─── App-Chain (EVM) contract addresses ──────────────────────────────────────
exports.EVM_CONTRACTS = {
    AXVN_TOKEN: "0x0000000000000000000000000000000000000001",
    PROOF_RESERVE: "0x0000000000000000000000000000000000000002",
};
// ─── Stalwart Mail Server ─────────────────────────────────────────────────────
exports.MAIL_CONFIG = {
    SMTP_HOST: process.env["SMTP_HOST"] ?? "mail.${BRAND_DOMAIN}",
    SMTP_PORT: Number(process.env["SMTP_PORT"] ?? 587),
    SMTP_SECURE: process.env["SMTP_SECURE"] === "true",
    SMTP_USER: process.env["SMTP_USER"] ?? "no-reply@${BRAND_DOMAIN}",
    SMTP_PASS: process.env["SMTP_PASS"] ?? "",
    EMAIL_FROM: process.env["EMAIL_FROM"] ?? "AXVN System <no-reply@${BRAND_DOMAIN}>",
};
