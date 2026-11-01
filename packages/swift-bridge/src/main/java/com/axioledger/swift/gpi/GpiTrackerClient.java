package com.axioledger.swift.gpi;

import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.mapper.RwaSettlementMapper;
import com.axioledger.swift.session.TokenProvider;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * GpiTrackerClient — B2
 *
 * Wraps the 4 GPI Tracker v5.0.5 endpoints confirmed in OAS specs:
 *   GET  /payments/{uetr}/transactions          → getTransactionDetails(uetr)
 *   GET  /payments/changed-transactions         → getChangedTransactions(from, page)
 *   POST /payments/{uetr}/cancellations         → cancelTransaction(uetr, json)
 *   GET  /payments/{uetr}/transaction-cancellation-status
 *
 * Routes requests through SWIFT Microgateway (MGW) at localhost:9003 (DP-4).
 * Auth: Bearer token from SwiftSessionManager via getValidToken() (auto-refreshed, 15 min TTL).
 *
 * On HTTP 401: triggers SwiftSessionManager.forceRefresh() and retries once.
 *
 * v0.2.0 — returns typed List<RwaSettlementEvent> / ChangedTransactionsPage
 */
public class GpiTrackerClient {

    private static final Logger log = LoggerFactory.getLogger(GpiTrackerClient.class);
    private static final String MEDIA_JSON = "application/json";

    /** MGW base URL — port 9003 per config-swift-mgw.yaml (DP-4 dedicated server). */
    private static final String DEFAULT_MGW_BASE = "http://localhost:9003";

    private final TokenProvider sessionManager;
    private final OkHttpClient httpClient;
    private final RwaSettlementMapper mapper;
    private final String mgwBaseUrl;

    public GpiTrackerClient(TokenProvider sessionManager, OkHttpClient httpClient) {
        this(sessionManager, httpClient, DEFAULT_MGW_BASE);
    }

    public GpiTrackerClient(TokenProvider sessionManager,
                            OkHttpClient httpClient,
                            String mgwBaseUrl) {
        this.sessionManager = sessionManager;
        this.httpClient     = httpClient;
        this.mapper         = new RwaSettlementMapper();
        this.mgwBaseUrl     = mgwBaseUrl;
    }

    // ── Endpoint 1: GET /payments/{uetr}/transactions ────────────────────────

    /**
     * Retrieve GPI transaction details by UETR.
     * Maps JSON response through {@link RwaSettlementMapper}.
     *
     * @param uetr Unique End-to-end Transaction Reference (UUID format)
     * @return List of {@link RwaSettlementEvent}; empty if no transaction legs
     */
    public List<RwaSettlementEvent> getTransactionDetails(String uetr) throws IOException {
        String url  = mgwBaseUrl + "/payments/" + uetr + "/transactions";
        String json = executeGet(url);
        JsonObject body = JsonParser.parseString(json).getAsJsonObject();
        return mapper.mapTransactionDetails(uetr, body);
    }

    // ── Endpoint 2: GET /payments/changed-transactions ───────────────────────

    /**
     * Delta query — sync changed transactions since last poll.
     * Returns a typed page result including the next-page token.
     *
     * @param fromDateTime  ISO-8601 datetime string, e.g. "2026-09-05T00:00:00Z"
     * @param nextPageToken Pagination token from previous response, or null
     * @return {@link ChangedTransactionsPage}
     */
    public ChangedTransactionsPage getChangedTransactions(String fromDateTime,
                                                         String nextPageToken) throws IOException {
        HttpUrl.Builder urlBuilder = Objects.requireNonNull(
                HttpUrl.parse(mgwBaseUrl + "/payments/changed-transactions")).newBuilder();
        if (fromDateTime != null)  urlBuilder.addQueryParameter("fromDateTime", fromDateTime);
        if (nextPageToken != null) urlBuilder.addQueryParameter("nextPageToken", nextPageToken);

        String json = executeGet(urlBuilder.build().toString());
        JsonObject body = JsonParser.parseString(json).getAsJsonObject();
        return mapper.mapChangedTransactionsPage(body);
    }

    // ── Endpoint 3: POST /payments/{uetr}/cancellations ──────────────────────

    /**
     * Request cancellation of a GPI payment.
     *
     * @param uetr            UETR of the payment to cancel
     * @param cancellationJson JSON body matching CancelTransactionRequest2 schema
     * @return Raw JSON string of CancellationResponse1
     */
    public String cancelTransaction(String uetr, String cancellationJson) throws IOException {
        String url = mgwBaseUrl + "/payments/" + uetr + "/cancellations";
        return executePost(url, cancellationJson);
    }

    // ── Endpoint 4: GET /payments/{uetr}/transaction-cancellation-status ─────

    /**
     * Check cancellation status.
     *
     * @param uetr UETR of the cancellation request
     * @return Raw JSON string of TransactionCancellationStatusRequest2
     */
    public String getTransactionCancellationStatus(String uetr) throws IOException {
        String url = mgwBaseUrl + "/payments/" + uetr + "/transaction-cancellation-status";
        return executeGet(url);
    }

    // ── HTTP helpers ─────────────────────────────────────────────────────────

    private String executeGet(String url) throws IOException {
        Request request = new Request.Builder()
                .url(url)
                .header("Authorization", "Bearer " + sessionManager.getValidToken())
                .header("Accept", MEDIA_JSON)
                .get()
                .build();
        return executeWithRetry(request);
    }

    private String executePost(String url, String jsonBody) throws IOException {
        RequestBody body = RequestBody.create(
                jsonBody,
                okhttp3.MediaType.parse(MEDIA_JSON + "; charset=utf-8"));
        Request request = new Request.Builder()
                .url(url)
                .header("Authorization", "Bearer " + sessionManager.getValidToken())
                .header("Accept", MEDIA_JSON)
                .post(body)
                .build();
        return executeWithRetry(request);
    }

    /** Execute with one retry on 401 (token expired mid-flight). */
    private String executeWithRetry(Request request) throws IOException {
        try (Response response = httpClient.newCall(request).execute()) {
            if (response.code() == 401) {
                log.warn("[GpiTrackerClient] HTTP 401 — forcing token refresh and retrying.");
                sessionManager.forceRefresh();
                Request retryRequest = request.newBuilder()
                        .header("Authorization", "Bearer " + sessionManager.getValidToken())
                        .build();
                try (Response retryResponse = httpClient.newCall(retryRequest).execute()) {
                    return extractBody(retryResponse);
                }
            }
            return extractBody(response);
        }
    }

    private String extractBody(Response response) throws IOException {
        if (!response.isSuccessful()) {
            String errorBody = response.body() != null ? response.body().string() : "(empty)";
            throw new IOException("[GpiTrackerClient] HTTP " + response.code()
                    + " from SWIFT API: " + errorBody);
        }
        return response.body() != null ? response.body().string() : "";
    }

    // ── Paged result type ─────────────────────────────────────────────────────

    /**
     * Typed page result for {@code changed-transactions}.
     */
    public static final class ChangedTransactionsPage {
        private final List<RwaSettlementEvent> events;
        private final String nextPageToken;

        public ChangedTransactionsPage(List<RwaSettlementEvent> events, String nextPageToken) {
            this.events        = Collections.unmodifiableList(events);
            this.nextPageToken = nextPageToken;
        }

        public List<RwaSettlementEvent> getEvents()        { return events; }
        public String                   getNextPageToken() { return nextPageToken; }
        public boolean                  hasMore()          { return nextPageToken != null; }
    }
}
