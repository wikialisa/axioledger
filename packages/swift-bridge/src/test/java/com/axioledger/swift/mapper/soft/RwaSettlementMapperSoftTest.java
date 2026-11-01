package com.axioledger.swift.mapper.soft;

import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.mapper.RwaSettlementMapper;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Soft (mock) tests for {@link RwaSettlementMapper}.
 *
 * <p>Validates JSON → domain model mapping without any network dependency.
 * Covers the PII-exclusion guarantee (DP-3): no PII fields must appear in the output.
 */
class RwaSettlementMapperSoftTest {

    private final RwaSettlementMapper mapper = new RwaSettlementMapper();

    private static final String SAMPLE_TRANSACTION_DETAILS = """
            {
              "transaction": [
                {
                  "instdAmt": { "value": "1000000.00", "ccy": "USD" },
                  "txSts": { "cd": "ACSC" },
                  "instdAgt": { "finInstnId": { "bicFI": "CHASUS33" } },
                  "trackerEvt": [
                    { "trackerEvtCrtnDt": "2026-09-05T10:00:00Z" }
                  ],
                  "cdtrNm": "Test Creditor",
                  "cdtrAcct": { "id": { "iban": "GB29NWBK60161331926819" } }
                }
              ]
            }
            """;

    @Test
    void mapTransactionDetails_populatesRequiredFields() {
        JsonObject json = JsonParser.parseString(SAMPLE_TRANSACTION_DETAILS).getAsJsonObject();
        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("test-uetr-001", json);

        assertFalse(events.isEmpty(), "Should produce at least one event");
        RwaSettlementEvent e = events.get(0);

        assertEquals("test-uetr-001", e.getUetr());
        assertEquals("ACSC", e.getStatusCode());
        assertTrue(e.isSettled());
        assertNotNull(e.getAmount());
        assertEquals("USD", e.getCurrency());
        assertEquals("CHASUS33", e.getLastAgentBic());
        assertNotNull(e.getTrackerEventTimestamp());
    }

    @Test
    void mapTransactionDetails_noPiiInEvent() {
        JsonObject json = JsonParser.parseString(SAMPLE_TRANSACTION_DETAILS).getAsJsonObject();
        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("test-uetr-002", json);

        assertFalse(events.isEmpty());
        RwaSettlementEvent e = events.get(0);

        // DP-3: PII fields must NOT be accessible via RwaSettlementEvent
        // The event model has no cdtrNm / cdtrAcct / dbtr fields by design
        String eventString = e.toString();
        assertFalse(eventString.contains("GB29NWBK"), "IBAN must not appear in event toString");
        assertFalse(eventString.contains("Test Creditor"), "Creditor name must not appear");
    }

    @Test
    void mapTransactionDetails_handlesEmptyResponse() {
        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("test-uetr-003", new JsonObject());
        assertTrue(events.isEmpty(), "Empty JSON object should yield no events");
    }

    @Test
    void mapTransactionDetails_defaultsToPendingWhenStatusAbsent() {
        JsonObject json = JsonParser.parseString("""
                { "transaction": [{ "instdAmt": { "value": "500.00", "ccy": "EUR" } }] }
                """).getAsJsonObject();
        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("test-uetr-004", json);
        assertEquals("PDNG", events.get(0).getStatusCode());
    }
}
