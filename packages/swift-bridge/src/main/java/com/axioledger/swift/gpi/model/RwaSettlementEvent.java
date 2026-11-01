package com.axioledger.swift.gpi.model;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Objects;

/**
 * RwaSettlementEvent — AXQ domain model
 *
 * Represents a SWIFT GPI settlement event mapped into the Axioledger
 * RWA Treasury domain. This object is safe for on-chain hashing.
 *
 * DP-3 GUARANTEE: This class contains NO PII fields (no creditor/debtor
 * names, addresses, or national IDs). Those are stripped by RwaSettlementMapper
 * before construction and handled exclusively off-chain by SwiftVrqAmlChecker.
 *
 * On-chain usage: hash(uetr + statusCode + amount + currency + trackerEventTimestamp)
 * is stored on L1 as the settlement proof anchor.
 *
 * v0.2.0 — builder pattern, statusCode string (ISO TransactionIndividualStatus5Code),
 *           vrqAmlProofHash field attached by SwiftVrqAmlChecker (DP-3).
 */
public class RwaSettlementEvent {

    /** Unique End-to-end Transaction Reference — stored on L1. */
    private final String uetr;

    /**
     * ISO TransactionIndividualStatus5Code: ACSC, ACCC, RJCT, PDNG, ACSP, etc.
     * Stored as a String rather than enum so unknown codes don't throw at parse time.
     */
    private final String statusCode;

    /** ISO 4217 currency code, e.g. "USD", "EUR". */
    private final String currency;

    /** Settlement amount — BigDecimal to avoid floating-point precision loss. */
    private final BigDecimal amount;

    /** Last tracker event timestamp from PaymentEvent13.trackerEvtCrtnDt. */
    private final Instant trackerEventTimestamp;

    /**
     * Last agent BIC from instdAgt (safe, non-PII — BIC identifies an institution, not a person).
     * Never null when populated; may be null for single-leg payments.
     */
    private final String lastAgentBic;

    /**
     * ZK-proof hash attached by SwiftVrqAmlChecker (DP-3).
     * Null until attachProof() is called. Null after AML block.
     * Only non-null events may reach the KPX on-chain layer.
     */
    private final String vrqAmlProofHash;

    /** Local receipt timestamp (not from SWIFT — for internal audit log). */
    private final Instant receivedAt;

    private RwaSettlementEvent(Builder b) {
        this.uetr                  = b.uetr;
        this.statusCode            = b.statusCode;
        this.currency              = b.currency;
        this.amount                = b.amount;
        this.trackerEventTimestamp = b.trackerEventTimestamp;
        this.lastAgentBic          = b.lastAgentBic;
        this.vrqAmlProofHash       = b.vrqAmlProofHash;
        this.receivedAt            = Instant.now();
    }

    // ── Builder ───────────────────────────────────────────────────────────────

    public static Builder builder(String uetr) {
        return new Builder(uetr);
    }

    public static final class Builder {
        private final String uetr;
        private String     statusCode            = "PDNG";
        private String     currency;
        private BigDecimal amount;
        private Instant    trackerEventTimestamp;
        private String     lastAgentBic;
        private String     vrqAmlProofHash;

        private Builder(String uetr) {
            Objects.requireNonNull(uetr, "UETR must not be null");
            this.uetr = uetr;
        }

        public Builder statusCode(String statusCode)                       { this.statusCode = statusCode; return this; }
        public Builder currency(String currency)                           { this.currency = currency; return this; }
        public Builder amount(BigDecimal amount)                           { this.amount = amount; return this; }
        public Builder trackerEventTimestamp(Instant trackerEventTimestamp){ this.trackerEventTimestamp = trackerEventTimestamp; return this; }
        public Builder lastAgentBic(String lastAgentBic)                   { this.lastAgentBic = lastAgentBic; return this; }
        public Builder vrqAmlProofHash(String vrqAmlProofHash)             { this.vrqAmlProofHash = vrqAmlProofHash; return this; }

        public RwaSettlementEvent build() {
            return new RwaSettlementEvent(this);
        }
    }

    // ── Accessors ─────────────────────────────────────────────────────────────

    public String     getUetr()                  { return uetr; }
    public String     getStatusCode()            { return statusCode; }
    public String     getCurrency()              { return currency; }
    public BigDecimal getAmount()                { return amount; }
    public Instant    getTrackerEventTimestamp() { return trackerEventTimestamp; }
    public String     getLastAgentBic()          { return lastAgentBic; }
    public String     getVrqAmlProofHash()       { return vrqAmlProofHash; }
    public Instant    getReceivedAt()            { return receivedAt; }

    // ── Convenience status helpers ────────────────────────────────────────────

    /** ACSC or ACCC = fully settled / credited at destination. */
    public boolean isSettled() {
        return "ACSC".equalsIgnoreCase(statusCode) || "ACCC".equalsIgnoreCase(statusCode);
    }

    public boolean isRejected() {
        return "RJCT".equalsIgnoreCase(statusCode);
    }

    public boolean isPending() {
        return "PDNG".equalsIgnoreCase(statusCode) || "ACSP".equalsIgnoreCase(statusCode);
    }

    // ── Object contract ───────────────────────────────────────────────────────

    @Override
    public String toString() {
        return "RwaSettlementEvent{uetr='" + uetr + "', statusCode='" + statusCode
                + "', amount=" + amount + " " + currency
                + ", trackerTs=" + trackerEventTimestamp
                + ", lastAgentBic='" + lastAgentBic + "'}";
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof RwaSettlementEvent)) return false;
        RwaSettlementEvent that = (RwaSettlementEvent) o;
        return Objects.equals(uetr, that.uetr) && Objects.equals(statusCode, that.statusCode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(uetr, statusCode);
    }
}
