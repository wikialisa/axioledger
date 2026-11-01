package com.axioledger.swift.kpx;

import com.axioledger.swift.gpi.GpiTrackerClient;
import com.axioledger.swift.gpi.GpiTrackerClient.ChangedTransactionsPage;
import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.vrq.SwiftVrqAmlChecker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.List;
import java.util.function.Consumer;

/**
 * SwiftKpxBridge — B4
 *
 * Bridges SWIFT GPI settlement confirmations into KinetoProtocol ($KPX)
 * liquidity pool events.
 *
 * Workflow (per UETR):
 *   1. Fetch transaction details from GpiTrackerClient
 *   2. For each SETTLED leg → call SwiftVrqAmlChecker.attachProof()
 *   3. If proofHash non-null (AML PASS) → fire kpxSettlementCallback
 *   4. If proofHash null  (AML BLOCK)   → drop silently (logged)
 *   5. If REJECTED → trigger kpxRejectionCallback (no AML needed)
 *
 * Workflow (delta sync):
 *   syncChangedTransactions(fromDateTime) → polls pages until no more,
 *   processing each SETTLED event through the AML gate.
 *
 * DP-5: This class is safe to instantiate in Phase B/C.
 * kpxSettlementCallback is a no-op stub until Phase D (post-TGE).
 *
 * v0.2.0 — processUetr() + syncChangedTransactions() with AML gate.
 */
public class SwiftKpxBridge {

    private static final Logger log = LoggerFactory.getLogger(SwiftKpxBridge.class);

    private final GpiTrackerClient                gpiClient;
    private final SwiftVrqAmlChecker              amlChecker;
    /** Callback invoked when a settlement passes AML — connects to KPX on-chain layer. */
    private final Consumer<RwaSettlementEvent>    kpxSettlementCallback;

    public SwiftKpxBridge(GpiTrackerClient gpiClient,
                          SwiftVrqAmlChecker amlChecker,
                          Consumer<RwaSettlementEvent> kpxSettlementCallback) {
        this.gpiClient              = gpiClient;
        this.amlChecker             = amlChecker;
        this.kpxSettlementCallback  = kpxSettlementCallback;
    }

    /**
     * Process all transaction legs for a given UETR.
     *
     * <p>Only SETTLED legs that pass the AML gate are forwarded to {@code kpxSettlementCallback}.
     * REJECTED legs are logged. PENDING legs are silently skipped.
     *
     * @param uetr SWIFT UETR
     * @return number of events successfully forwarded to the callback
     */
    public int processUetr(String uetr) {
        List<RwaSettlementEvent> events;
        try {
            events = gpiClient.getTransactionDetails(uetr);
        } catch (IOException e) {
            log.error("[SwiftKpxBridge] Failed to fetch details for UETR={}: {}", uetr, e.getMessage());
            return 0;
        }

        int forwarded = 0;
        for (RwaSettlementEvent event : events) {
            try {
                forwarded += routeWithAml(event);
            } catch (Exception e) {
                log.error("[SwiftKpxBridge] Error routing UETR={} leg: {}", uetr, e.getMessage());
            }
        }
        return forwarded;
    }

    /**
     * Poll changed transactions from {@code fromDateTime} and process all pages.
     *
     * @param fromDateTime ISO-8601 datetime, e.g. "2026-09-01T00:00:00Z"
     * @return total number of events forwarded to the callback across all pages
     */
    public int syncChangedTransactions(String fromDateTime) {
        int total = 0;
        String nextPageToken = null;

        do {
            ChangedTransactionsPage page;
            try {
                page = gpiClient.getChangedTransactions(fromDateTime, nextPageToken);
            } catch (IOException e) {
                log.error("[SwiftKpxBridge] Polling failed (from={}, page={}): {}",
                        fromDateTime, nextPageToken, e.getMessage());
                break;
            }

            for (RwaSettlementEvent event : page.getEvents()) {
                try {
                    total += routeWithAml(event);
                } catch (Exception e) {
                    log.warn("[SwiftKpxBridge] Skipping event UETR={}: {}", event.getUetr(), e.getMessage());
                }
            }

            nextPageToken = page.getNextPageToken();
        } while (nextPageToken != null);

        log.info("[SwiftKpxBridge] syncChangedTransactions complete. from={} total={}", fromDateTime, total);
        return total;
    }

    // ── private helpers ───────────────────────────────────────────────────────

    /**
     * Route a single event through the AML gate.
     * Returns 1 if the event was forwarded, 0 otherwise.
     */
    private int routeWithAml(RwaSettlementEvent event) throws IOException {
        if (event.isRejected()) {
            log.warn("[SwiftKpxBridge] REJECTED UETR={} — no AML needed, logged only.", event.getUetr());
            return 0;
        }

        if (!event.isSettled()) {
            log.debug("[SwiftKpxBridge] Status={} UETR={} — skipping (not settled).",
                    event.getStatusCode(), event.getUetr());
            return 0;
        }

        // AML gate: attach VRQ proof hash
        RwaSettlementEvent checked = amlChecker.attachProof(event);

        if (checked.getVrqAmlProofHash() == null) {
            log.warn("[SwiftKpxBridge] AML BLOCKED UETR={} — event dropped.", event.getUetr());
            return 0;
        }

        log.info("[SwiftKpxBridge] SETTLED+AML_PASS UETR={} amount={} {} proofHash={}",
                checked.getUetr(), checked.getAmount(), checked.getCurrency(),
                checked.getVrqAmlProofHash());

        try {
            kpxSettlementCallback.accept(checked);
        } catch (Exception e) {
            log.error("[SwiftKpxBridge] Consumer threw for UETR={}: {}", checked.getUetr(), e.getMessage());
        }
        return 1;
    }
}
