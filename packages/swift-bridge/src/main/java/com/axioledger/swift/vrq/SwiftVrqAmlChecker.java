package com.axioledger.swift.vrq;

import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * SwiftVrqAmlChecker — B5
 *
 * Handles AML compliance by bridging SWIFT identity data with
 * Veraciphers ($VRQ) ZK-DID proof generation.
 *
 * DP-3 CRITICAL MANDATE (from Cố vấn Đặc biệt 2026-09-03):
 * ─────────────────────────────────────────────────────────
 * ALL PII fields from SWIFT GPI (creditor/debtor name, address,
 * national ID, date of birth) MUST be processed ENTIRELY OFF-CHAIN
 * through this class. The only artefact allowed on-chain is the
 * ZK-proof hash returned by the VRQ circuit.
 *
 * Flow:
 *   1. Receive RwaSettlementEvent (contains UETR, amount, currency — NO PII)
 *   2. POST to VRQ AML endpoint /vrq/v1/aml/prove with uetr + settlement hash
 *   3. Receive ZK proof hash (no PII in request or response)
 *   4. Return new RwaSettlementEvent with vrqAmlProofHash set (null = AML blocked)
 *
 * GDPR compliance: No PII is sent to the VRQ endpoint — only safe settlement fields.
 *
 * v0.2.0 — HTTP-based VRQ endpoint integration; constructor takes (vrqBaseUrl, httpClient).
 */
public class SwiftVrqAmlChecker {

    private static final Logger log = LoggerFactory.getLogger(SwiftVrqAmlChecker.class);

    private static final String PROVE_PATH  = "/vrq/v1/aml/prove";
    private static final String MEDIA_JSON  = "application/json";

    private final String       vrqBaseUrl;
    private final OkHttpClient httpClient;

    /**
     * @param vrqBaseUrl   Base URL of the VRQ AML service, e.g. "https://vrq.internal:8443"
     * @param httpClient   OkHttpClient — may be mTLS-configured for production
     */
    public SwiftVrqAmlChecker(String vrqBaseUrl, OkHttpClient httpClient) {
        this.vrqBaseUrl  = vrqBaseUrl;
        this.httpClient  = httpClient;
    }

    /**
     * Attach a VRQ AML proof hash to the given settlement event.
     *
     * <p>Posts the UETR and safe settlement fields to the VRQ AML proof endpoint.
     * Returns a new {@link RwaSettlementEvent} with {@code vrqAmlProofHash} set:
     * <ul>
     *   <li>Non-null hash → AML PASS — event is safe to forward to KPX bridge</li>
     *   <li>Null hash     → AML BLOCK — SwiftKpxBridge must drop this event</li>
     * </ul>
     *
     * @param event Settlement event (no PII fields — DP-3 guaranteed by RwaSettlementMapper)
     * @return new event with vrqAmlProofHash populated (or null if blocked)
     * @throws IOException if the VRQ endpoint is unreachable or returns a non-2xx status
     */
    public RwaSettlementEvent attachProof(RwaSettlementEvent event) throws IOException {
        String proofHash = callVrqAmlProve(event);

        return RwaSettlementEvent.builder(event.getUetr())
                .statusCode(event.getStatusCode())
                .amount(event.getAmount())
                .currency(event.getCurrency())
                .trackerEventTimestamp(event.getTrackerEventTimestamp())
                .lastAgentBic(event.getLastAgentBic())
                .vrqAmlProofHash(proofHash)
                .build();
    }

    // ── Private ───────────────────────────────────────────────────────────────

    /**
     * POST to VRQ /vrq/v1/aml/prove.
     * Request body contains only safe non-PII fields (uetr, amount, currency).
     *
     * @return proof hash string if PASS, null if BLOCK
     * @throws IOException on HTTP error or network failure
     */
    private String callVrqAmlProve(RwaSettlementEvent event) throws IOException {
        // Build request body — safe fields only (DP-3)
        JsonObject payload = new JsonObject();
        payload.addProperty("uetr",     event.getUetr());
        payload.addProperty("amount",   event.getAmount() != null ? event.getAmount().toPlainString() : "0");
        payload.addProperty("currency", event.getCurrency());

        RequestBody body = RequestBody.create(
                payload.toString(),
                MediaType.parse(MEDIA_JSON + "; charset=utf-8"));

        Request request = new Request.Builder()
                .url(vrqBaseUrl + PROVE_PATH)
                .post(body)
                .header("Accept",       MEDIA_JSON)
                .header("Content-Type", MEDIA_JSON)
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                String errBody = response.body() != null ? response.body().string() : "(empty)";
                throw new IOException("[SwiftVrqAmlChecker] VRQ AML endpoint returned HTTP "
                        + response.code() + ": " + errBody);
            }

            String respJson = response.body() != null ? response.body().string() : "{}";
            return parseProofHash(respJson);
        }
    }

    /**
     * Parse the VRQ response.
     * Returns null if status is BLOCK (or proofHash is null/absent).
     */
    private String parseProofHash(String json) {
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();

        // status field: "PASS" or "BLOCK" (case-insensitive per test contract)
        String status = obj.has("status") && !obj.get("status").isJsonNull()
                ? obj.get("status").getAsString()
                : "BLOCK";

        if ("block".equalsIgnoreCase(status)) {
            log.warn("[SwiftVrqAmlChecker] AML BLOCK — proofHash will be null.");
            return null;
        }

        // PASS: extract proofHash
        if (obj.has("proofHash") && !obj.get("proofHash").isJsonNull()) {
            String hash = obj.get("proofHash").getAsString();
            log.info("[SwiftVrqAmlChecker] AML PASS — proofHash={}", hash);
            return hash;
        }

        // proofHash absent or null despite PASS status — treat as block
        log.warn("[SwiftVrqAmlChecker] AML PASS but proofHash null — treating as BLOCK.");
        return null;
    }
}
