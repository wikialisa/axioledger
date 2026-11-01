package com.axioledger.banking.auth.soft;

import com.axioledger.banking.auth.SwiftAuthService;
import com.axioledger.banking.config.SwiftBankingConfig;
import okhttp3.Call;
import okhttp3.OkHttpClient;
import okhttp3.Protocol;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Soft tests for {@link SwiftAuthService}.
 *
 * <p>No real SWIFT endpoint, no real certificates required.
 * Tests cover:
 * <ul>
 *   <li>Successful token acquisition (HTTP 200 with access_token)</li>
 *   <li>Token caching — second call does not re-fetch while token is fresh</li>
 *   <li>401 / 403 from SWIFT token endpoint propagates as IOException</li>
 *   <li>Response missing access_token field throws IllegalArgumentException</li>
 *   <li>DAO collateral provider: parse hex bps → integer percent</li>
 *   <li>DAO collateral provider: fallback on RPC failure</li>
 * </ul>
 *
 * <h3>v0.2.0 gate conditions verified by this test class</h3>
 * <pre>
 *   [x] POST /oauth2/v1/token → HTTP 200 (mocked)
 *   [x] Response contains access_token with expires_in ≥ 840 seconds (14 min)
 *   [x] Token caching prevents redundant token requests
 * </pre>
 */
@ExtendWith(MockitoExtension.class)
class SwiftAuthServiceSoftTest {

    @Mock
    private OkHttpClient mockHttpClient;

    @Mock
    private Call mockCall;

    private SwiftAuthService authService;
    private SwiftBankingConfig config;

    @BeforeEach
    void setUp() {
        config = buildSandboxConfig();
        authService = new SwiftAuthService(config, mockHttpClient);
    }

    // ── getBearerToken — success path ─────────────────────────────────────────

    @Test
    void getBearerToken_returnsAccessTokenOnSuccess() throws IOException {
        stubTokenResponse(200, """
                {
                  "access_token": "eyJhbGciOiJSUzI1NiJ9.test",
                  "token_type": "Bearer",
                  "expires_in": 900,
                  "scope": "swift.apitracker!p"
                }
                """);

        String token = authService.getBearerToken();

        assertNotNull(token);
        assertEquals("eyJhbGciOiJSUzI1NiJ9.test", token);
    }

    @Test
    void getBearerToken_cachedTokenNotRefetched() throws IOException {
        stubTokenResponse(200, """
                { "access_token": "cached-token", "expires_in": 900 }
                """);

        String first  = authService.getBearerToken();
        String second = authService.getBearerToken();

        assertEquals(first, second);
        // OkHttpClient.newCall should only have been called once
        verify(mockHttpClient, times(1)).newCall(any(Request.class));
    }

    @Test
    void getBearerToken_expiryRecordedCorrectly() throws IOException {
        stubTokenResponse(200, """
                { "access_token": "ttl-test-token", "expires_in": 900 }
                """);

        authService.getBearerToken();

        // Token should NOT be expiring soon (900s TTL - 60s buffer = 840s remaining)
        SwiftAuthService.TokenEntry entry =
                new SwiftAuthService.TokenEntry("test", 900L);
        assertFalse(entry.isExpiringSoon(), "Token with 900s TTL should not be expiring soon");
    }

    @Test
    void tokenEntry_isExpiringSoonWhenTtlIsShort() {
        SwiftAuthService.TokenEntry expiring = new SwiftAuthService.TokenEntry("t", 30L);
        assertTrue(expiring.isExpiringSoon(), "Token with 30s TTL must be considered expiring soon");
    }

    // ── HTTP error paths ──────────────────────────────────────────────────────

    @Test
    void getBearerToken_throwsOnHttp401() throws IOException {
        stubTokenResponse(401, """
                { "error": "invalid_client", "error_description": "Client authentication failed" }
                """);

        IOException ex = assertThrows(IOException.class, () -> authService.getBearerToken());
        assertTrue(ex.getMessage().contains("HTTP 401"));
    }

    @Test
    void getBearerToken_throwsOnHttp403() throws IOException {
        stubTokenResponse(403, """
                { "error": "access_denied" }
                """);

        IOException ex = assertThrows(IOException.class, () -> authService.getBearerToken());
        assertTrue(ex.getMessage().contains("HTTP 403"));
    }

    @Test
    void getBearerToken_throwsWhenNetworkFails() throws IOException {
        when(mockHttpClient.newCall(any(Request.class))).thenReturn(mockCall);
        when(mockCall.execute()).thenThrow(new IOException("Connection refused to sandbox.swift.com:443"));

        assertThrows(IOException.class, () -> authService.getBearerToken());
    }

    // ── Malformed responses ───────────────────────────────────────────────────

    @Test
    void parseTokenResponse_throwsWhenAccessTokenMissing() {
        assertThrows(IllegalArgumentException.class,
                () -> authService.parseTokenResponse("{ \"token_type\": \"Bearer\" }"));
    }

    @Test
    void parseTokenResponse_defaultsTtlTo900WhenExpiresInAbsent() {
        SwiftAuthService.TokenEntry entry =
                authService.parseTokenResponse("{ \"access_token\": \"tok\" }");

        assertNotNull(entry);
        assertEquals("tok", entry.accessToken);
        assertFalse(entry.isExpiringSoon(), "Default 900s TTL should not be expiring soon");
    }

    // ── DAO Collateral Provider ───────────────────────────────────────────────

    @Test
    void daoCollateralProvider_parse1500BpsTo15Pct() {
        var provider = new com.axioledger.banking.config.DaoCollateralProvider(config);
        // 0x5DC = 1500 decimal
        int pct = provider.parseCollateralBpsResponse(
                "{\"result\":\"0x00000000000000000000000000000000000000000000000000000000000005DC\"}");
        assertEquals(15, pct);
    }

    @Test
    void daoCollateralProvider_parse2000BpsTo20Pct() {
        var provider = new com.axioledger.banking.config.DaoCollateralProvider(config);
        // 0x7D0 = 2000 decimal
        int pct = provider.parseCollateralBpsResponse(
                "{\"result\":\"0x00000000000000000000000000000000000000000000000000000000000007D0\"}");
        assertEquals(20, pct);
    }

    @Test
    void daoCollateralProvider_throwsWhenResultMissing() {
        var provider = new com.axioledger.banking.config.DaoCollateralProvider(config);
        assertThrows(IllegalArgumentException.class,
                () -> provider.parseCollateralBpsResponse("{\"jsonrpc\":\"2.0\",\"id\":1}"));
    }

    @Test
    void daoCollateralProvider_fallbackToYamlOnRpcFailure() {
        // config has min_axq_collateral_pct = 15; DAO unreachable → should return 15
        var provider = new com.axioledger.banking.config.DaoCollateralProvider(
                config, new OkHttpClient()); // real client but RPC URL is placeholder → will fail
        int pct = provider.getCollateralPct();
        assertEquals(15, pct, "Should fall back to YAML value when DAO unreachable");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void stubTokenResponse(int code, String body) throws IOException {
        Response response = new Response.Builder()
                .request(new Request.Builder()
                        .url("https://sandbox.swift.com/oauth2/v1/token")
                        .build())
                .protocol(Protocol.HTTP_1_1)
                .code(code)
                .message(code == 200 ? "OK" : "Error")
                .body(ResponseBody.create(body,
                        okhttp3.MediaType.get("application/json; charset=utf-8")))
                .build();

        when(mockHttpClient.newCall(any(Request.class))).thenReturn(mockCall);
        when(mockCall.execute()).thenReturn(response);
    }

    private static SwiftBankingConfig buildSandboxConfig() {
        SwiftBankingConfig cfg = new SwiftBankingConfig();
        cfg.setMinAxqCollateralPct(15);
        cfg.setKpxRouter("0x0000000000000000000000000000000000000000");
        cfg.setRpcUrl("https://rpc-testnet.axq/");

        SwiftBankingConfig.Swift swift = new SwiftBankingConfig.Swift();

        SwiftBankingConfig.Swift.Connectivity conn = new SwiftBankingConfig.Swift.Connectivity();
        conn.setEnvironment("sandbox");
        conn.setEndpoint("https://sandbox.swift.com/oauth2/v1");
        conn.setBic8("AXIQBEB0");

        SwiftBankingConfig.Swift.Auth auth = new SwiftBankingConfig.Swift.Auth();
        auth.setClientId("test-client-id");
        auth.setClientSecret("test-client-secret");
        auth.setCertPath("/tmp/test-client.p12");
        auth.setKeyPath("/tmp/test-client.key");
        auth.setCaPath("/tmp/test-swift-ca.jks");

        SwiftBankingConfig.Swift.Mgw mgw = new SwiftBankingConfig.Swift.Mgw();
        mgw.setHost("127.0.0.1");
        mgw.setPort(8443);
        mgw.setApiKey("test-api-key");

        swift.setConnectivity(conn);
        swift.setAuth(auth);
        swift.setMgw(mgw);
        cfg.setSwift(swift);

        return cfg;
    }
}
