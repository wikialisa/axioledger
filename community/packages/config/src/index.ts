// ─── Feature Flags ────────────────────────────────────────────────────────────
export { features, requireFeature, checkFeature } from "./features.js";
export type { FeatureKey } from "./features.js";

// ─── RPC Endpoints ────────────────────────────────────────────────────────────

export const SOLANA_RPC_DEVNET  = process.env["SOLANA_RPC_DEVNET"]  ?? "https://api.devnet.solana.com";
export const SOLANA_RPC_MAINNET = process.env["SOLANA_RPC_MAINNET"] ?? "https://api.mainnet-beta.solana.com";

/** App-Chain Genesis (EVM) — set APPCHAIN_RPC in .env */
export const APPCHAIN_RPC_LOCAL   = process.env["APPCHAIN_RPC"]     ?? "http://localhost:8545";
export const APPCHAIN_RPC_MAINNET = process.env["APPCHAIN_RPC_MAINNET"] ?? "https://rpc.your-project.vn";

export const TRON_FULL_HOST  = process.env["TRON_FULL_HOST"]  ?? "https://api.trongrid.io";
export const TRON_NILE_TESTNET = "https://nile.trongrid.io";

export const DEFAULT_API_ENDPOINT = process.env["DEFAULT_API_ENDPOINT"] ?? "https://dev-api.your-project.vn";

// ─── Solana Program IDs ───────────────────────────────────────────────────────
// Set via env before `anchor build` (see scripts/set-program-ids.sh).
// Defaults to system program (all-ones) so the build never silently uses
// a wrong address — any unset ID will fail on-chain validation.

const FALLBACK = "11111111111111111111111111111111";

export const PROGRAM_IDS = {
  P2P_ESCROW:      process.env["PROGRAM_ID_P2P_ESCROW"]      ?? FALLBACK,
  MINT_GOVERNANCE: process.env["PROGRAM_ID_MINT_GOVERNANCE"]  ?? FALLBACK,
  AMM_SWAP:        process.env["PROGRAM_ID_AMM_SWAP"]         ?? FALLBACK,
  TREASURY_RBS:    process.env["PROGRAM_ID_TREASURY_RBS"]     ?? FALLBACK,
  SWIFT_BRIDGE:    process.env["PROGRAM_ID_SWIFT_BRIDGE"]     ?? FALLBACK,
} as const;

// ─── Seed PDA prefixes ────────────────────────────────────────────────────────

export const SEEDS = {
  ESCROW_VAULT:   Buffer.from("escrow_vault"),
  ORDER_STATE:    Buffer.from("order_state"),
  MINT_AUTHORITY: Buffer.from("mint_authority"),
  TREASURY_VAULT: Buffer.from("treasury_vault"),
} as const;

// ─── App-Chain (EVM) contract addresses ──────────────────────────────────────
// Set via .env or packages/contracts/exports/addresses.json after deployment.

export const EVM_CONTRACTS = {
  AXVN_TOKEN:    process.env["EVM_AXVN_TOKEN"]    ?? "0x0000000000000000000000000000000000000000",
  PROOF_RESERVE: process.env["EVM_PROOF_RESERVE"] ?? "0x0000000000000000000000000000000000000000",
  SWIFT_BRIDGE:  process.env["EVM_SWIFT_BRIDGE"]  ?? "0x0000000000000000000000000000000000000000",
} as const;

// ─── Stalwart Mail Server ─────────────────────────────────────────────────────

export const MAIL_CONFIG = {
  SMTP_HOST:   process.env["SMTP_HOST"]  ?? "mail.your-project.vn",
  SMTP_PORT:   Number(process.env["SMTP_PORT"] ?? 587),
  SMTP_SECURE: process.env["SMTP_SECURE"] === "true",
  SMTP_USER:   process.env["SMTP_USER"]  ?? "no-reply@your-project.vn",
  SMTP_PASS:   process.env["SMTP_PASS"]  ?? "",
  EMAIL_FROM:  process.env["EMAIL_FROM"] ?? "Your Organisation Full Name <no-reply@your-project.vn>",
} as const;
