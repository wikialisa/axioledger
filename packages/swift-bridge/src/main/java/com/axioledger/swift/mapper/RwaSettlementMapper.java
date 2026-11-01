package com.axioledger.swift.mapper;

import com.axioledger.swift.gpi.GpiTrackerClient.ChangedTransactionsPage;
import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Maps raw GPI Tracker API JSON (OAS v5.0.5) to {@link RwaSettlementEvent} domain objects.
 *
 * <p>Counterpart fields referenced from the SWIFT OpenAPI SDK models:
 * <ul>
 *   <li>{@code CreditTransferTransaction40} — instructed amount + currency</li>
 *   <li>{@code PaymentEvent13}              — tracker event type + timestamp</li>
 *   <li>{@code PaymentTransaction121}       — transaction status + last agent</li>
 *   <li>{@code TransactionIndividualStatus5Code} — ACSC / ACCC / RJCT / PDNG</li>
 * </ul>
 *
 * <p><b>PII exclusion:</b> Fields that carry personal information
 * ({@code cdtrAcct}, {@code dbtrAcct}, {@code initgPty}, {@code cdtrNm}, etc.)
 * are deliberately NOT mapped here. They must be processed off-chain by
 * {@link com.axioledger.swift.vrq.SwiftVrqAmlChecker} (DP-3).
 */
public class RwaSettlementMapper {

    private static final Logger log = LoggerFactory.getLogger(RwaSettlementMapper.class);

    /**
     * Maps the {@code ReadPaymentTransactionDetailsResponse1} JSON for a single UETR.
     *
     * <p>The response wraps a {@code PaymentTransaction121} array; each entry produces one
     * {@link RwaSettlementEvent}.
     *
     * @param uetr the SWIFT UETR (injected — not present in every API response body)
     * @param json parsed response body
     * @return list of events; empty if the response contains no transaction legs
     */
    public List<RwaSettlementEvent> mapTransactionDetails(String uetr, JsonObject json) {
        if (json == null || !json.has("transaction")) {
            log.warn("mapTransactionDetails: no 'transaction' array for UETR={}", uetr);
            return Collections.emptyList();
        }

        JsonArray transactions = json.getAsJsonArray("transaction");
        List<RwaSettlementEvent> events = new ArrayList<>(transactions.size());

        for (JsonElement txEl : transactions) {
            JsonObject tx = txEl.getAsJsonObject();
            try {
                events.add(mapTransaction(uetr, tx));
            } catch (Exception e) {
                log.error("Failed to map transaction leg for UETR={}: {}", uetr, e.getMessage());
            }
        }
        return Collections.unmodifiableList(events);
    }

    /**
     * Maps the paged {@code changed-transactions} response body.
     *
     * @param json parsed response body
     * @return paged result including next-page token (null when last page)
     */
    public ChangedTransactionsPage mapChangedTransactionsPage(JsonObject json) {
        List<RwaSettlementEvent> events = new ArrayList<>();

        if (json != null && json.has("payments")) {
            JsonArray payments = json.getAsJsonArray("payments");
            for (JsonElement pmtEl : payments) {
                JsonObject pmt = pmtEl.getAsJsonObject();
                String uetr = getString(pmt, "uetr");
                if (uetr == null) continue;

                if (pmt.has("transaction")) {
                    for (JsonElement txEl : pmt.getAsJsonArray("transaction")) {
                        try {
                            events.add(mapTransaction(uetr, txEl.getAsJsonObject()));
                        } catch (Exception e) {
                            log.error("Changed-tx map failed for UETR={}: {}", uetr, e.getMessage());
                        }
                    }
                }
            }
        }

        String nextPageToken = (json != null && json.has("next")) ? getString(json, "next") : null;
        return new ChangedTransactionsPage(events, nextPageToken);
    }

    // ── Private ───────────────────────────────────────────────────────────────

    /**
     * Maps a single {@code PaymentTransaction121} JSON object.
     *
     * <p>PII fields (debtor, creditor account details, party names) are skipped.
     */
    private RwaSettlementEvent mapTransaction(String uetr, JsonObject tx) {
        String statusCode = resolveStatusCode(tx);

        // Amount and currency from CreditTransferTransaction40.instdAmt
        BigDecimal amount   = null;
        String     currency = null;
        if (tx.has("instdAmt")) {
            JsonObject instdAmt = tx.getAsJsonObject("instdAmt");
            amount   = getBigDecimal(instdAmt, "value");
            currency = getString(instdAmt, "ccy");
        }

        // Tracker event timestamp from PaymentEvent13
        Instant eventTimestamp = null;
        if (tx.has("trackerEvt")) {
            JsonArray trackerEvts = tx.getAsJsonArray("trackerEvt");
            if (!trackerEvts.isEmpty()) {
                JsonObject latestEvt = trackerEvts.get(trackerEvts.size() - 1).getAsJsonObject();
                String ts = getString(latestEvt, "trackerEvtCrtnDt");
                if (ts != null) {
                    try { eventTimestamp = Instant.parse(ts); } catch (Exception ignored) {}
                }
            }
        }

        // Last agent BIC from PaymentTransaction121.instgAgt / instdAgt
        String lastAgentBic = null;
        if (tx.has("instdAgt")) {
            lastAgentBic = resolveFinInstnBic(tx.getAsJsonObject("instdAgt"));
        }

        return RwaSettlementEvent.builder(uetr)
                .statusCode(statusCode)
                .amount(amount)
                .currency(currency)
                .trackerEventTimestamp(eventTimestamp)
                .lastAgentBic(lastAgentBic)
                // vrqAmlProofHash is populated later by SwiftVrqAmlChecker (DP-3)
                .build();
    }

    private String resolveStatusCode(JsonObject tx) {
        // TransactionIndividualStatus5Code lives under tx.txSts.cd or tx.sts
        if (tx.has("txSts") && tx.getAsJsonObject("txSts").has("cd")) {
            return getString(tx.getAsJsonObject("txSts"), "cd");
        }
        if (tx.has("sts")) return getString(tx, "sts");
        return "PDNG"; // default to Pending when absent
    }

    private String resolveFinInstnBic(JsonObject finInstn) {
        if (finInstn == null) return null;
        if (finInstn.has("finInstnId")) {
            JsonObject id = finInstn.getAsJsonObject("finInstnId");
            return getString(id, "bicFI");
        }
        return getString(finInstn, "bicFI");
    }

    // ── JSON helpers ──────────────────────────────────────────────────────────

    private static String getString(JsonObject obj, String key) {
        JsonElement el = obj.get(key);
        return (el != null && !el.isJsonNull()) ? el.getAsString() : null;
    }

    private static BigDecimal getBigDecimal(JsonObject obj, String key) {
        JsonElement el = obj.get(key);
        if (el == null || el.isJsonNull()) return null;
        try { return el.getAsBigDecimal(); } catch (Exception e) { return null; }
    }
}
