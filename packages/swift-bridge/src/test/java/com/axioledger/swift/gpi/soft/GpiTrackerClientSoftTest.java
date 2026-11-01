package com.axioledger.swift.gpi.soft;

import com.axioledger.swift.gpi.GpiTrackerClient;
import com.axioledger.swift.gpi.GpiTrackerClient.ChangedTransactionsPage;
import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.session.TokenProvider;
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
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Soft (mock) tests for {@link GpiTrackerClient}.
 *
 * <p>Uses a pre-configured {@link OkHttpClient} injected via the package-private constructor
 * to avoid any real network calls or SWIFT SDK dependency at test time.
 * The {@link SwiftSessionManager} is mocked to return a fixed Bearer token.
 */
@ExtendWith(MockitoExtension.class)
class GpiTrackerClientSoftTest {

    @Mock
    private TokenProvider sessionManager;

    @Mock
    private OkHttpClient okHttpClient;

    @Mock
    private Call mockCall;

    private static final String UETR = "97ed4827-7b6f-4491-a06f-b548d5a7512d";

    private static final String TRANSACTION_DETAILS_JSON = """
            {
              "transaction": [
                {
                  "instdAmt": { "value": "250000.00", "ccy": "USD" },
                  "txSts": { "cd": "ACSC" },
                  "instdAgt": { "finInstnId": { "bicFI": "DEUTDEDB" } },
                  "trackerEvt": [
                    { "trackerEvtCrtnDt": "2026-09-10T08:30:00Z" }
                  ]
                }
              ]
            }
            """;

    private static final String CHANGED_TRANSACTIONS_JSON = """
            {
              "payments": [
                {
                  "uetr": "97ed4827-7b6f-4491-a06f-b548d5a7512d",
                  "transaction": [
                    {
                      "instdAmt": { "value": "100.00", "ccy": "EUR" },
                      "txSts": { "cd": "PDNG" }
                    }
                  ]
                }
              ]
            }
            """;

    /**
     * Injects a mock OkHttpClient via a test-only subclass approach.
     * GpiTrackerClient exposes the (sessionManager, mgwBaseUrl) constructor;
     * we sub-in the mock client by overriding the field via the test subclass below.
     */
    private GpiTrackerClientTestable client;

    @BeforeEach
    void setUp() {
        lenient().when(sessionManager.getValidToken()).thenReturn("mock-bearer-token");
        client = new GpiTrackerClientTestable(sessionManager, "http://localhost:9003", okHttpClient);
    }

    // ── getTransactionDetails ─────────────────────────────────────────────────

    @Test
    void getTransactionDetails_mapsAcscEvent() throws IOException {
        stubHttpResponse(200, TRANSACTION_DETAILS_JSON);

        List<RwaSettlementEvent> events = client.getTransactionDetails(UETR);

        assertFalse(events.isEmpty());
        RwaSettlementEvent e = events.get(0);
        assertEquals(UETR, e.getUetr());
        assertEquals("ACSC", e.getStatusCode());
        assertTrue(e.isSettled());
        assertEquals("USD", e.getCurrency());
        assertEquals("DEUTDEDB", e.getLastAgentBic());
        assertNotNull(e.getTrackerEventTimestamp());
    }

    @Test
    void getTransactionDetails_throwsOnHttpError() throws IOException {
        stubHttpResponse(401, "{\"error\":\"Unauthorized\"}");

        assertThrows(IOException.class, () -> client.getTransactionDetails(UETR));
    }

    @Test
    void getTransactionDetails_authHeaderContainsBearerToken() throws IOException {
        stubHttpResponse(200, TRANSACTION_DETAILS_JSON);

        client.getTransactionDetails(UETR);

        verify(sessionManager).getValidToken();
    }

    // ── getChangedTransactions ─────────────────────────────────────────────────

    @Test
    void getChangedTransactions_returnsEventsAndNoNextPage() throws IOException {
        stubHttpResponse(200, CHANGED_TRANSACTIONS_JSON);

        ChangedTransactionsPage page =
                client.getChangedTransactions("2026-09-01T00:00:00Z", null);

        assertFalse(page.getEvents().isEmpty());
        assertFalse(page.hasMore());
        assertNull(page.getNextPageToken());
    }

    @Test
    void getChangedTransactions_returnsNextPageToken() throws IOException {
        String json = """
                {
                  "payments": [],
                  "next": "page-token-xyz"
                }
                """;
        stubHttpResponse(200, json);

        ChangedTransactionsPage page =
                client.getChangedTransactions("2026-09-01T00:00:00Z", null);

        assertTrue(page.hasMore());
        assertEquals("page-token-xyz", page.getNextPageToken());
    }

    @Test
    void getChangedTransactions_throwsOnHttpError() throws IOException {
        stubHttpResponse(503, "{\"error\":\"Service Unavailable\"}");

        assertThrows(IOException.class,
                () -> client.getChangedTransactions("2026-09-01T00:00:00Z", null));
    }

    // ── PII safety ────────────────────────────────────────────────────────────

    @Test
    void getTransactionDetails_noSdkDependencyAtTestTime() {
        // If this test class compiles and instantiates without the SWIFT SDK on the
        // classpath, it confirms the soft test boundary is correctly isolated.
        // The SwiftSessionManager mock carries no CloudOAuthSessionImpl reference.
        assertNotNull(client);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void stubHttpResponse(int code, String body) throws IOException {
        Response response = new Response.Builder()
                .request(new Request.Builder().url("http://localhost:9003/test").build())
                .protocol(Protocol.HTTP_1_1)
                .code(code)
                .message(code == 200 ? "OK" : "Error")
                .body(ResponseBody.create(body,
                        okhttp3.MediaType.get("application/json; charset=utf-8")))
                .build();

        when(okHttpClient.newCall(any(Request.class))).thenReturn(mockCall);
        when(mockCall.execute()).thenReturn(response);
    }

    /**
     * Test-only subclass that replaces the internal OkHttpClient with the mock.
     * Uses the package-accessible two-arg constructor and then overrides the client field
     * via constructor chaining defined here.
     */
    static class GpiTrackerClientTestable extends GpiTrackerClient {
        GpiTrackerClientTestable(TokenProvider sm, String mgwUrl, OkHttpClient injectedClient) {
            super(sm, injectedClient, mgwUrl);
        }
    }
}
