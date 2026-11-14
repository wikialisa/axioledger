"use strict";
/**
 * features.ts — Feature flags cho các external service chưa có API key.
 *
 * Đọc từ biến môi trường FEATURE_* (mặc định false — tắt an toàn).
 * Khi có key thật, đặt FEATURE_XYZ=true trong .env để bật.
 *
 * Cách dùng trong service:
 *   import { features } from "config";
 *   if (!features.VIETQR) return;          // skip silently
 *   if (!features.TWILIO) throw new Error("SMS disabled"); // hoặc throw
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.features = void 0;
exports.requireFeature = requireFeature;
exports.checkFeature = checkFeature;
function flag(key) {
    const val = process.env[key];
    if (val === undefined || val === "")
        return false;
    return val.trim().toLowerCase() === "true" || val.trim() === "1";
}
exports.features = {
    /** Ethereum/EVM RPC qua Alchemy — cần ALCHEMY_API_KEY */
    ALCHEMY: flag("FEATURE_ALCHEMY"),
    /** On-chain deposit listener (TRON/BTC) — cần TATUM_API_KEY */
    TATUM: flag("FEATURE_TATUM"),
    /** VietQR deposit initiation — cần VIETQR_API_KEY */
    VIETQR: flag("FEATURE_VIETQR"),
    /** NAPAS liên ngân hàng — cần NAPAS_API_KEY */
    NAPAS: flag("FEATURE_NAPAS"),
    /** Cloud storage S3 (ảnh KYC, media) — cần AWS_ACCESS_KEY_ID */
    AWS_S3: flag("FEATURE_AWS_S3"),
    /** SMS OTP — cần TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN */
    TWILIO: flag("FEATURE_TWILIO"),
    /** Chainalysis AML screening — cần AML_PROVIDER_API_KEY */
    AML: flag("FEATURE_AML"),
    /** AI trading signals — cần AI_SIGNAL_API_KEY */
    AI_SIGNAL: flag("FEATURE_AI_SIGNAL"),
    /** Dune Analytics PoR — cần DUNE_API_KEY */
    DUNE: flag("FEATURE_DUNE"),
    /** Telegram bot alerts — cần TELEGRAM_BOT_TOKEN */
    TELEGRAM_ALERT: flag("FEATURE_TELEGRAM_ALERT"),
    /** Discord bot alerts — cần DISCORD_BOT_TOKEN */
    DISCORD_ALERT: flag("FEATURE_DISCORD_ALERT"),
};
/**
 * Guard — throw nếu feature bị tắt.
 *
 * @example
 *   requireFeature("TWILIO", "SMS OTP service");
 */
function requireFeature(key, label) {
    if (!exports.features[key]) {
        throw new Error(`Feature "${label ?? key}" is disabled. ` +
            `Set FEATURE_${key}=true in .env to enable.`);
    }
}
/**
 * Guard — log warn và return false nếu feature tắt (không throw).
 * Dùng cho background jobs / workers có thể skip gracefully.
 *
 * @example
 *   if (!checkFeature("DUNE")) return;
 */
function checkFeature(key, label) {
    if (!exports.features[key]) {
        console.warn(`[features] "${label ?? key}" is disabled (FEATURE_${key}=false). Skipping.`);
        return false;
    }
    return true;
}
