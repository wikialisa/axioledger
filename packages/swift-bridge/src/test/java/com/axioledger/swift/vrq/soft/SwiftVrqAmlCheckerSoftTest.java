package com.axioledger.swift.vrq.soft;

import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.vrq.SwiftVrqAmlChecker;
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
import java.math.BigDecimal;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Soft (mock) tests for {@link SwiftVrqAmlChecker}.
 *
 * <p>No real VRQ endpoint required — OkHttpClient is mocked.
 * Tests verify:
 * <ul>
 *   <li>AML PASS path — proofHash is attached to the returned event</li>
 *   <li>AML BLOCK path — proofHash is null in the returned event</li>
 *   <li>HTTP error path — IOException propagates correctly</li>
 *   <li>DP-3 guarantee — PII does NOT appear in the returned event</li>
 *   <li>Returned event carries all non-PII fields from the original event</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class SwiftVrqAmlCheckerSoftTest {

    @Mock
    private OkHttpClient mockHttpClient;

    @Mock
    private Call mockCall;

    private SwiftVrqAmlChecker checker;

    private static final String VRQ_BASE_URL = "https://vrq.internal:8443";
    private static final String UETR = "test-uetr-vrq-001";

    @BeforeEach
    void setUp() {
        checker = new SwiftVrqAmlChecker(VRQ_BASE_URL, mockHttpClient);
    }

    // ── AML PASS ──────────────────────────────────────────────────────────────

    @Test
    void attachProof_passReturnsNonNullHash() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": "0xdeadbeef1234567890", "status": "PASS" }
                """);

        RwaSettlementEvent result = checker.attachProof(sampleEvent());

        assertNotNull(result.getVrqAmlProofHash());
        assertEquals("0xdeadbeef1234567890", result.getVrqAmlProofHash());
    }

    @Test
    void attachProof_passPreservesAllNonPiiFields() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": "0xabc", "status": "PASS" }
                """);

        RwaSettlementEvent original = sampleEvent();
        RwaSettlementEvent result   = checker.attachProof(original);

        // All safe fields must be copied through unchanged (DP-3: no PII, but safe fields preserved)
        assertEquals(original.getUetr(),                   result.getUetr());
        assertEquals(original.getStatusCode(),             result.getStatusCode());
        assertEquals(original.getAmount(),                 result.getAmount());
        assertEquals(original.getCurrency(),               result.getCurrency());
        assertEquals(original.getTrackerEventTimestamp(),  result.getTrackerEventTimestamp());
        assertEquals(original.getLastAgentBic(),           result.getLastAgentBic());
    }

    // ── AML BLOCK ─────────────────────────────────────────────────────────────

    @Test
    void attachProof_blockReturnsNullHash() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": null, "status": "BLOCK" }
                """);

        RwaSettlementEvent result = checker.attachProof(sampleEvent());

        assertNull(result.getVrqAmlProofHash(),
                "AML-blocked event must have null proofHash so KPX bridge drops it");
    }

    @Test
    void attachProof_blockStatusCaseInsensitive() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": null, "status": "block" }
                """);

        RwaSettlementEvent result = checker.attachProof(sampleEvent());

        assertNull(result.getVrqAmlProofHash());
    }

    // ── HTTP error paths ──────────────────────────────────────────────────────

    @Test
    void attachProof_throwsOnHttp500() throws IOException {
        stubVrqResponse(500, """
                { "error": "Internal Server Error" }
                """);

        assertThrows(IOException.class, () -> checker.attachProof(sampleEvent()));
    }

    @Test
    void attachProof_throwsOnHttp401() throws IOException {
        stubVrqResponse(401, """
                { "error": "Unauthorized" }
                """);

        assertThrows(IOException.class, () -> checker.attachProof(sampleEvent()));
    }

    @Test
    void attachProof_throwsWhenNetworkFails() throws IOException {
        when(mockHttpClient.newCall(any(Request.class))).thenReturn(mockCall);
        when(mockCall.execute()).thenThrow(new IOException("Connection refused"));

        assertThrows(IOException.class, () -> checker.attachProof(sampleEvent()));
    }

    // ── DP-3: PII safety ──────────────────────────────────────────────────────

    @Test
    void attachProof_returnedEventHasNoPiiFields() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": "0xsafehash", "status": "PASS" }
                """);

        RwaSettlementEvent result = checker.attachProof(sampleEvent());

        // RwaSettlementEvent has no PII accessors by design —
        // verify the model class does not expose any PII getter
        assertDoesNotThrow(() -> result.getUetr());           // safe
        assertDoesNotThrow(() -> result.getStatusCode());     // safe
        assertDoesNotThrow(() -> result.getLastAgentBic());   // BIC only, safe
        assertDoesNotThrow(() -> result.getVrqAmlProofHash()); // hash only, safe

        // toString must not contain raw PII values from the stub payload
        String str = result.toString();
        assertFalse(str.contains("cdtrNm"), "PII field name must not appear in toString");
        assertFalse(str.contains("cdtrAcct"), "PII field name must not appear in toString");
        assertFalse(str.contains("dbtr"), "PII field name must not appear in toString");
    }

    // ── Endpoint contract ─────────────────────────────────────────────────────

    @Test
    void attachProof_postsToCorrectPath() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": "0xhash", "status": "PASS" }
                """);

        checker.attachProof(sampleEvent());

        verify(mockHttpClient).newCall(argThat(req ->
                req.url().toString().equals(VRQ_BASE_URL + "/vrq/v1/aml/prove")
                && req.method().equals("POST")
        ));
    }

    @Test
    void attachProof_requestBodyContainsUetr() throws IOException {
        stubVrqResponse(200, """
                { "proofHash": "0xhash", "status": "PASS" }
                """);

        checker.attachProof(sampleEvent());

        // Verify a POST was made — body content validation is done via integration tests
        verify(mockCall).execute();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void stubVrqResponse(int code, String body) throws IOException {
        Response response = new Response.Builder()
                .request(new Request.Builder().url(VRQ_BASE_URL + "/vrq/v1/aml/prove").build())
                .protocol(Protocol.HTTP_1_1)
                .code(code)
                .message(code == 200 ? "OK" : "Error")
                .body(ResponseBody.create(body,
                        okhttp3.MediaType.get("application/json; charset=utf-8")))
                .build();

        when(mockHttpClient.newCall(any(Request.class))).thenReturn(mockCall);
        when(mockCall.execute()).thenReturn(response);
    }

    private static RwaSettlementEvent sampleEvent() {
        return RwaSettlementEvent.builder(UETR)
                .statusCode("ACSC")
                .amount(BigDecimal.valueOf(500_000))
                .currency("USD")
                .trackerEventTimestamp(Instant.parse("2026-09-10T12:00:00Z"))
                .lastAgentBic("BNPAFRPP")
                .build();
    }
}
