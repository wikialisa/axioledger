package com.axioledger.banking.auth;

import com.axioledger.banking.config.SwiftBankingConfig;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.KeyStore;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicReference;

/**
 * OAuth2 + mTLS authentication service against the SWIFT API Gateway.
 *
 * <h3>v0.2.0 — Auth Phase</h3>
 * <p>Implements the full handshake required before any GPI or Tracker API call:
 * <ol>
 *   <li>Build an {@link OkHttpClient} with the mTLS client certificate loaded from
 *       {@code keys/client.crt} + {@code keys/client.key} (PEM format)</li>
 *   <li>POST to the SWIFT OAuth2 token endpoint with {@code client_credentials} grant</li>
 *   <li>Cache the Bearer token and proactively refresh 60 seconds before expiry</li>
 * </ol>
 *
 * <h3>Security rules</h3>
 * <ul>
 *   <li>{@code clientId} and {@code clientSecret} are injected from environment variables
 *       {@code SWIFT_CLIENT_ID} / {@code SWIFT_CLIENT_SECRET} — never commit plaintext</li>
 *   <li>Certificate files live under {@code /mnt/q/core/banking/swift-gateway/keys/}
 *       with {@code chmod 600} — only the service user can read them</li>
 *   <li>The sandbox endpoint ({@code sandbox.swift.com}) is used for v0.1.0 / v0.2.0;
 *       the production endpoint is locked until v1.1.0 Mainnet Gate G3</li>
 * </ul>
 *
 * <h3>Gate condition for v0.2.0 complete</h3>
 * <pre>
 *   [ ] POST /oauth2/v1/token → HTTP 200
 *   [ ] Response contains access_token with expires_in ≥ 840 seconds (14 min)
 *   [ ] OkHttpClient presents client.crt successfully (mTLS handshake accepted)
 * </pre>
 */
@Service
public class SwiftAuthService {

    private static final Logger log = LoggerFactory.getLogger(SwiftAuthService.class);

    /** Refresh token this many seconds before expiry to avoid 401s under load. */
    private static final long REFRESH_BEFORE_EXPIRY_SECONDS = 60L;

    /** OAuth2 scope for GPI Tracker API. */
    private static final String SCOPE_GPI_TRACKER = "swift.apitracker!p";

    private final SwiftBankingConfig config;
    private final AtomicReference<TokenEntry> tokenRef = new AtomicReference<>();

    /** Lazily initialised — built once mTLS certs are confirmed present. */
    private volatile OkHttpClient mtlsClient;

    public SwiftAuthService(SwiftBankingConfig config) {
        this.config = config;
    }

    /** Test constructor — allows pre-built OkHttpClient injection (no real certs needed). */
    SwiftAuthService(SwiftBankingConfig config, OkHttpClient testClient) {
        this.config     = config;
        this.mtlsClient = testClient;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Returns a valid Bearer token string, refreshing proactively when near expiry.
     *
     * @return non-null, non-expired access token value
     * @throws IOException on SWIFT token endpoint failure
     */
    public String getBearerToken() throws IOException {
        TokenEntry current = tokenRef.get();
        if (current == null || current.isExpiringSoon()) {
            synchronized (this) {
                current = tokenRef.get();
                if (current == null || current.isExpiringSoon()) {
                    current = fetchNewToken();
                    tokenRef.set(current);
                    log.info("SWIFT Bearer token acquired — expiresAt={}", current.expiresAt);
                }
            }
        }
        return current.accessToken;
    }

    /**
     * Returns the OkHttpClient configured with the mTLS client certificate.
     * This client must be used for all requests to the SWIFT MGW / API.
     *
     * @throws IOException if certificate files cannot be read
     */
    public OkHttpClient getMtlsClient() throws IOException {
        if (mtlsClient == null) {
            synchronized (this) {
                if (mtlsClient == null) {
                    mtlsClient = buildMtlsClient();
                    log.info("mTLS OkHttpClient initialised — cert={}", config.getSwift().getAuth().getCertPath());
                }
            }
        }
        return mtlsClient;
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private TokenEntry fetchNewToken() throws IOException {
        SwiftBankingConfig.Swift.Auth auth = config.getSwift().getAuth();
        String tokenUrl = config.getSwift().getConnectivity().getEndpoint() + "/token";

        assertCredentialsPresent(auth);

        FormBody body = new FormBody.Builder()
                .add("grant_type",    "client_credentials")
                .add("client_id",     auth.getClientId())
                .add("client_secret", auth.getClientSecret())
                .add("scope",         SCOPE_GPI_TRACKER)
                .build();

        Request request = new Request.Builder()
                .url(tokenUrl)
                .post(body)
                .header("Accept", "application/json")
                .build();

        try (Response response = getMtlsClient().newCall(request).execute()) {
            if (!response.isSuccessful()) {
                String errBody = response.body() != null ? response.body().string() : "(empty)";
                throw new IOException("SWIFT OAuth2 token request failed — HTTP "
                        + response.code() + ": " + errBody);
            }

            String raw = response.body() != null ? response.body().string() : "{}";
            return parseTokenResponse(raw);
        }
    }

    TokenEntry parseTokenResponse(String json) {
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();

        if (!obj.has("access_token") || obj.get("access_token").isJsonNull()) {
            throw new IllegalArgumentException("Token response missing access_token");
        }

        String accessToken = obj.get("access_token").getAsString();
        long expiresIn = obj.has("expires_in") && !obj.get("expires_in").isJsonNull()
                ? obj.get("expires_in").getAsLong()
                : 900L; // SWIFT default TTL = 15 min

        return new TokenEntry(accessToken, expiresIn);
    }

    /**
     * Builds an OkHttpClient that presents the SWIFT mTLS client certificate on every
     * TLS handshake.
     *
     * <p>Certificate format: PKCS12 keystore at {@code keys/client.p12}, or PEM pair
     * ({@code client.crt} + {@code client.key}) converted to a JKS/PKCS12 via
     * {@code openssl pkcs12 -export}.
     *
     * <p>For v0.1.0 / v0.2.0 Sandbox only: the SWIFT Sandbox CA is included in
     * {@code keys/swift-ca.crt} (imported into the truststore).
     */
    private OkHttpClient buildMtlsClient() throws IOException {
        SwiftBankingConfig.Swift.Auth auth = config.getSwift().getAuth();

        try {
            // Load client keystore (PKCS12 expected — convert PEM pair with openssl if needed)
            KeyStore keyStore = KeyStore.getInstance("PKCS12");
            String keystorePassword = System.getenv("SWIFT_KEYSTORE_PASSWORD");
            if (keystorePassword == null) keystorePassword = "";

            try (FileInputStream fis = new FileInputStream(auth.getCertPath())) {
                keyStore.load(fis, keystorePassword.toCharArray());
            }

            KeyManagerFactory kmf = KeyManagerFactory.getInstance(
                    KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(keyStore, keystorePassword.toCharArray());

            // Load SWIFT CA truststore
            KeyStore trustStore = KeyStore.getInstance("JKS");
            String trustPassword = System.getenv("SWIFT_TRUSTSTORE_PASSWORD");
            if (trustPassword == null) trustPassword = "changeit";

            try (FileInputStream fis = new FileInputStream(auth.getCaPath())) {
                trustStore.load(fis, trustPassword.toCharArray());
            }

            TrustManagerFactory tmf = TrustManagerFactory.getInstance(
                    TrustManagerFactory.getDefaultAlgorithm());
            tmf.init(trustStore);

            SSLContext sslContext = SSLContext.getInstance("TLS");
            sslContext.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

            X509TrustManager trustManager = (X509TrustManager) tmf.getTrustManagers()[0];

            return new OkHttpClient.Builder()
                    .sslSocketFactory(sslContext.getSocketFactory(), trustManager)
                    .connectTimeout(Duration.ofSeconds(10))
                    .readTimeout(Duration.ofSeconds(30))
                    .build();

        } catch (Exception e) {
            throw new IOException("Failed to build mTLS client — check cert paths and passwords: "
                    + e.getMessage(), e);
        }
    }

    private void assertCredentialsPresent(SwiftBankingConfig.Swift.Auth auth) {
        if (auth.getClientId() == null || auth.getClientId().isBlank()) {
            throw new IllegalStateException(
                    "SWIFT_CLIENT_ID not set — export the environment variable before starting");
        }
        if (auth.getClientSecret() == null || auth.getClientSecret().isBlank()) {
            throw new IllegalStateException(
                    "SWIFT_CLIENT_SECRET not set — export the environment variable before starting");
        }
    }

    // ── Internal token cache ──────────────────────────────────────────────────

    static final class TokenEntry {
        final String accessToken;
        final Instant expiresAt;

        TokenEntry(String accessToken, long expiresInSeconds) {
            this.accessToken = accessToken;
            this.expiresAt   = Instant.now().plusSeconds(expiresInSeconds);
        }

        boolean isExpiringSoon() {
            return Instant.now().isAfter(expiresAt.minusSeconds(REFRESH_BEFORE_EXPIRY_SECONDS));
        }
    }
}
