package com.axioledger.swift.session;

/**
 * TokenProvider — interface dùng bởi GpiTrackerClient để lấy Bearer token.
 *
 * Tách biệt GpiTrackerClient khỏi SWIFT Security SDK (Phase A gate).
 * Implementations:
 *   - SwiftSessionManager (dùng SWIFT OAuth SDK — Phase A+, excluded from compile until SDK installed)
 *   - Test mock (any lambda/mock returning a fixed token string)
 */
public interface TokenProvider {
    /** Returns the current valid Bearer token. Must not return null. */
    String getValidToken();

    /** Force-refresh the token (e.g. after HTTP 401). */
    void forceRefresh();
}
