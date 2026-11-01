package com.axioledger.swift.session;

import com.swift.commons.oauth.connection.constants.OAuthConstants;
import com.swift.commons.oauth.connection.interfaces.OAuthSession;
import com.swift.commons.oauth.connection.interfaces.OAuthToken;
// TokenProvider is a plain interface in this package — no SDK dependency
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * SwiftSessionManager — B1
 *
 * Manages the OAuth2 session lifecycle against SWIFT GPI API.
 * Wraps CloudOAuthSessionImpl from swift-security-sdk v2.17.5-6.
 *
 * Token TTL: DEFAULT_EXPIRY_TIME_MIN = 15 min (from OAuthConstants).
 * Auto-refreshes 2 minutes before expiry.
 *
 * Deployment targets (DP-5):
 *   SANDBOX   → AUDIENCE_SET.SANDBOX_PROD   (Giai đoạn A/B/C)
 *   TEST_SIPN → AUDIENCE_SET.ON_PREMISES_PILOT
 *   PROD_SIPN → AUDIENCE_SET.ON_PREMISES_PROD  (Giai đoạn D — post-TGE only)
 *
 * Thread-safe via AtomicReference + ScheduledExecutorService.
 */
public class SwiftSessionManager implements TokenProvider {

    private static final Logger log = LoggerFactory.getLogger(SwiftSessionManager.class);

    /** Refresh 2 minutes before the 15-min TTL expires. */
    private static final long REFRESH_BEFORE_EXPIRY_SEC = 120L;
    private static final long TOKEN_TTL_SEC = OAuthConstants.DEFAULT_EXPIRY_TIME_MIN * 60L;

    /** GPI Tracker API OAuth2 scope — exposed as constant for tests. */
    public static final String SCOPE_GPI_TRACKER = "swift.apitracker!p";

    private final OAuthSession session;
    private final String scope;
    private final String audience;

    private final AtomicReference<OAuthToken> currentToken = new AtomicReference<>();
    private final ScheduledExecutorService scheduler =
            Executors.newSingleThreadScheduledExecutor(r -> {
                Thread t = new Thread(r, "swift-token-refresh");
                t.setDaemon(true);
                return t;
            });
    private volatile ScheduledFuture<?> refreshTask;

    /**
     * @param session  OAuthSession implementation (CloudOAuthSessionImpl for cloud,
     *                 or on-premises equivalent)
     * @param scope    SWIFT API scope — e.g. "swift.apitracker!p"
     * @param audience AUDIENCE_SET value — use SANDBOX_PROD for Giai đoạn A/B/C
     */
    public SwiftSessionManager(OAuthSession session, String scope, String audience) {
        this.session = session;
        this.scope = scope;
        this.audience = audience;
    }

    /** Convenience factory for SANDBOX (Giai đoạn A/B/C — DP-5). */
    public static SwiftSessionManager forSandbox(OAuthSession session) {
        return new SwiftSessionManager(
                session,
                "swift.apitracker!p",
                OAuthConstants.AUDIENCE_SET.SANDBOX_PROD.getValue()
        );
    }

    /**
     * Initialise the session: obtain the first token and schedule auto-refresh.
     * Call once at application startup.
     */
    public void init() {
        log.info("[SwiftSessionManager] Initialising SWIFT OAuth2 session. audience={}", audience);
        OAuthToken token = session.getToken(scope, audience);
        currentToken.set(token);
        log.info("[SwiftSessionManager] Token acquired. Scheduling refresh in {}s",
                TOKEN_TTL_SEC - REFRESH_BEFORE_EXPIRY_SEC);
        scheduleRefresh();
    }

    /**
     * Returns the current valid Bearer token string.
     * Callers (GpiTrackerClient) use this as "Authorization: Bearer <token>".
     */
    public String getBearerToken() {
        return getValidToken();
    }

    /**
     * Alias for {@link #getBearerToken()} — preferred name used by GpiTrackerClient tests.
     */
    public String getValidToken() {
        OAuthToken token = currentToken.get();
        if (token == null) {
            throw new IllegalStateException("SwiftSessionManager not initialised — call init() first");
        }
        return token.getAccessToken();
    }

    /** Explicitly refresh the token (e.g. after a 401 response from SWIFT API). */
    public synchronized void forceRefresh() {
        log.info("[SwiftSessionManager] Force-refreshing token.");
        OAuthToken old = currentToken.get();
        if (old != null && old.getRefreshToken() != null) {
            OAuthToken refreshed = session.refreshToken(scope, audience, old.getRefreshToken());
            currentToken.set(refreshed);
            log.info("[SwiftSessionManager] Token refreshed successfully.");
        } else {
            // Fall back to full re-auth
            OAuthToken token = session.getToken(scope, audience);
            currentToken.set(token);
            log.info("[SwiftSessionManager] Token re-acquired (no refresh token available).");
        }
        // Reschedule
        if (refreshTask != null) refreshTask.cancel(false);
        scheduleRefresh();
    }

    /** Revoke the current token and shut down the refresh scheduler. */
    public void shutdown() {
        log.info("[SwiftSessionManager] Revoking token and shutting down.");
        if (refreshTask != null) refreshTask.cancel(false);
        scheduler.shutdownNow();
        OAuthToken token = currentToken.get();
        if (token != null) {
            try {
                session.revokeToken(token.getAccessToken(), "access_token");
            } catch (Exception e) {
                log.warn("[SwiftSessionManager] Token revocation failed (non-fatal): {}", e.getMessage());
            }
        }
    }

    // ── private helpers ──────────────────────────────────────────────────────

    private void scheduleRefresh() {
        long delay = TOKEN_TTL_SEC - REFRESH_BEFORE_EXPIRY_SEC;
        refreshTask = scheduler.schedule(() -> {
            try {
                forceRefresh();
            } catch (Exception e) {
                log.error("[SwiftSessionManager] Auto-refresh failed: {}", e.getMessage(), e);
            }
        }, delay, TimeUnit.SECONDS);
    }
}
