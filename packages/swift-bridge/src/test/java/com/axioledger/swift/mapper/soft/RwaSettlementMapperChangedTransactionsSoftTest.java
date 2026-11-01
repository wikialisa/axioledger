package com.axioledger.swift.mapper.soft;

import com.axioledger.swift.gpi.GpiTrackerClient.ChangedTransactionsPage;
import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.mapper.RwaSettlementMapper;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Soft tests for {@link RwaSettlementMapper} — changed-transactions paging path.
 *
 * <p>Complements {@link RwaSettlementMapperSoftTest} which covers the single-UETR path.
 * Tests here focus on the paged changed-transactions response and multi-leg mapping.
 */
class RwaSettlementMapperChangedTransactionsSoftTest {

    private final RwaSettlementMapper mapper = new RwaSettlementMapper();

    // ── mapChangedTransactionsPage ────────────────────────────────────────────

    @Test
    void mapChangedTransactionsPage_mapsMultiplePayments() {
        JsonObject json = JsonParser.parseString("""
                {
                  "payments": [
                    {
                      "uetr": "uetr-001",
                      "transaction": [
                        { "instdAmt": { "value": "1000.00", "ccy": "USD" },
                          "txSts": { "cd": "ACSC" } }
                      ]
                    },
                    {
                      "uetr": "uetr-002",
                      "transaction": [
                        { "instdAmt": { "value": "2000.00", "ccy": "EUR" },
                          "txSts": { "cd": "RJCT" } }
                      ]
                    }
                  ]
                }
                """).getAsJsonObject();

        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(json);

        assertEquals(2, page.getEvents().size());
        assertFalse(page.hasMore());

        RwaSettlementEvent e1 = page.getEvents().get(0);
        assertEquals("uetr-001", e1.getUetr());
        assertEquals("ACSC", e1.getStatusCode());
        assertTrue(e1.isSettled());

        RwaSettlementEvent e2 = page.getEvents().get(1);
        assertEquals("uetr-002", e2.getUetr());
        assertEquals("RJCT", e2.getStatusCode());
        assertTrue(e2.isRejected());
    }

    @Test
    void mapChangedTransactionsPage_nextPageTokenPresent() {
        JsonObject json = JsonParser.parseString("""
                {
                  "payments": [],
                  "next": "cursor-abc-123"
                }
                """).getAsJsonObject();

        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(json);

        assertTrue(page.hasMore());
        assertEquals("cursor-abc-123", page.getNextPageToken());
        assertTrue(page.getEvents().isEmpty());
    }

    @Test
    void mapChangedTransactionsPage_noNextTokenWhenLastPage() {
        JsonObject json = JsonParser.parseString("""
                { "payments": [] }
                """).getAsJsonObject();

        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(json);

        assertFalse(page.hasMore());
        assertNull(page.getNextPageToken());
    }

    @Test
    void mapChangedTransactionsPage_skipsPaymentsWithNoUetr() {
        JsonObject json = JsonParser.parseString("""
                {
                  "payments": [
                    {
                      "transaction": [
                        { "instdAmt": { "value": "500.00", "ccy": "GBP" },
                          "txSts": { "cd": "ACSC" } }
                      ]
                    }
                  ]
                }
                """).getAsJsonObject();

        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(json);

        assertTrue(page.getEvents().isEmpty(), "Payment without UETR must be skipped");
    }

    @Test
    void mapChangedTransactionsPage_handlesNullInput() {
        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(null);

        assertTrue(page.getEvents().isEmpty());
        assertFalse(page.hasMore());
    }

    @Test
    void mapChangedTransactionsPage_handlesEmptyJsonObject() {
        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(new JsonObject());

        assertTrue(page.getEvents().isEmpty());
        assertFalse(page.hasMore());
    }

    @Test
    void mapChangedTransactionsPage_multipleLegsPerPayment() {
        JsonObject json = JsonParser.parseString("""
                {
                  "payments": [
                    {
                      "uetr": "uetr-multi",
                      "transaction": [
                        { "instdAmt": { "value": "100.00", "ccy": "USD" },
                          "txSts": { "cd": "PDNG" } },
                        { "instdAmt": { "value": "100.00", "ccy": "USD" },
                          "txSts": { "cd": "ACSC" } }
                      ]
                    }
                  ]
                }
                """).getAsJsonObject();

        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(json);

        assertEquals(2, page.getEvents().size(), "Each transaction leg becomes one event");
        assertEquals("PDNG", page.getEvents().get(0).getStatusCode());
        assertEquals("ACSC", page.getEvents().get(1).getStatusCode());
    }

    @Test
    void mapChangedTransactionsPage_noPiiInAnyEvent() {
        JsonObject json = JsonParser.parseString("""
                {
                  "payments": [
                    {
                      "uetr": "uetr-pii-check",
                      "transaction": [
                        {
                          "instdAmt": { "value": "999.00", "ccy": "CHF" },
                          "txSts": { "cd": "ACSC" },
                          "cdtrNm": "Sensitive Creditor Name",
                          "cdtrAcct": { "id": { "iban": "CH5604835012345678009" } },
                          "dbtrNm": "Sensitive Debtor Name"
                        }
                      ]
                    }
                  ]
                }
                """).getAsJsonObject();

        ChangedTransactionsPage page = mapper.mapChangedTransactionsPage(json);
        List<RwaSettlementEvent> events = page.getEvents();

        assertFalse(events.isEmpty());
        for (RwaSettlementEvent e : events) {
            String str = e.toString();
            assertFalse(str.contains("Sensitive Creditor Name"), "cdtrNm must not leak");
            assertFalse(str.contains("Sensitive Debtor Name"),   "dbtrNm must not leak");
            assertFalse(str.contains("CH5604835012345678009"),    "IBAN must not leak");
        }
    }

    // ── mapTransactionDetails — additional status codes ────────────────────────

    @Test
    void mapTransactionDetails_acccIsSettled() {
        JsonObject json = JsonParser.parseString("""
                {
                  "transaction": [
                    { "instdAmt": { "value": "50.00", "ccy": "USD" },
                      "txSts": { "cd": "ACCC" } }
                  ]
                }
                """).getAsJsonObject();

        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("uetr-accc", json);
        assertEquals(1, events.size());
        assertTrue(events.get(0).isSettled(), "ACCC must be treated as settled");
    }

    @Test
    void mapTransactionDetails_rjctIsRejected() {
        JsonObject json = JsonParser.parseString("""
                {
                  "transaction": [
                    { "instdAmt": { "value": "50.00", "ccy": "USD" },
                      "sts": "RJCT" }
                  ]
                }
                """).getAsJsonObject();

        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("uetr-rjct", json);
        assertEquals(1, events.size());
        assertTrue(events.get(0).isRejected());
        assertFalse(events.get(0).isSettled());
    }

    @Test
    void mapTransactionDetails_lastAgentBicFlatStructure() {
        // Some GPI responses put bicFI directly on instdAgt without finInstnId nesting
        JsonObject json = JsonParser.parseString("""
                {
                  "transaction": [
                    {
                      "instdAmt": { "value": "1.00", "ccy": "USD" },
                      "txSts": { "cd": "ACSC" },
                      "instdAgt": { "bicFI": "SOGEFRPP" }
                    }
                  ]
                }
                """).getAsJsonObject();

        List<RwaSettlementEvent> events = mapper.mapTransactionDetails("uetr-flat-bic", json);
        assertEquals("SOGEFRPP", events.get(0).getLastAgentBic());
    }
}
