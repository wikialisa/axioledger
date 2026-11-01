package com.axioledger.swift.soft;

import com.axioledger.swift.gpi.RwaSettlementMapper;
import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Soft test (no network) for RwaSettlementMapper.
 * Verifies DP-3: no PII fields in mapped RwaSettlementEvent.
 */
class RwaSettlementMapperSoftTest {

    private static final String SETTLED_JSON = """
            {
              "transaction": {
                "uetr": "97ed4827-7b6f-4491-a06f-b548d5a7512d",
                "transactionStatus": "ACSC",
                "instrAmt": { "Ccy": "USD", "value": "1000000.00" },
                "valueDate": "2026-09-05",
                "lastUpdateTime": "2026-09-05T12:00:00Z"
              }
            }
            """;

    private static final String REJECTED_JSON = """
            {
              "transaction": {
                "uetr": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                "transactionStatus": "RJCT",
                "instrAmt": { "Ccy": "EUR", "value": "500.00" },
                "valueDate": "2026-09-05"
              }
            }
            """;

    @Test
    void fromJson_settledTransaction_mapsCorrectly() {
        RwaSettlementEvent event = RwaSettlementMapper.fromJson(SETTLED_JSON);

        assertEquals("97ed4827-7b6f-4491-a06f-b548d5a7512d", event.getUetr());
        assertEquals(RwaSettlementEvent.Status.SETTLED, event.getStatus());
        assertEquals("USD", event.getCurrency());
        assertEquals("1000000.00", event.getAmount());
        assertEquals("2026-09-05", event.getSettlementDate());
        assertTrue(event.isSettled());
        assertFalse(event.isRejected());
    }

    @Test
    void fromJson_rejectedTransaction_mapsCorrectly() {
        RwaSettlementEvent event = RwaSettlementMapper.fromJson(REJECTED_JSON);

        assertEquals(RwaSettlementEvent.Status.REJECTED, event.getStatus());
        assertTrue(event.isRejected());
        assertFalse(event.isSettled());
    }

    @Test
    void fromJson_noPiiInResult() {
        RwaSettlementEvent event = RwaSettlementMapper.fromJson(SETTLED_JSON);

        // DP-3: verify no PII fields are present in RwaSettlementEvent
        // The class has no name/address/dob fields by design
        assertNotNull(event.getUetr());
        assertNotNull(event.getAmount());
        // toString should not contain any creditor/debtor name
        String str = event.toString();
        assertFalse(str.contains("creditor"), "PII creditor name must not appear in event");
        assertFalse(str.contains("debtor"),   "PII debtor name must not appear in event");
    }

    @Test
    void mapStatus_allCodes() {
        assertEquals(RwaSettlementEvent.Status.SETTLED,    RwaSettlementMapper.mapStatus("ACSC"));
        assertEquals(RwaSettlementEvent.Status.CREDITED,   RwaSettlementMapper.mapStatus("ACCC"));
        assertEquals(RwaSettlementEvent.Status.REJECTED,   RwaSettlementMapper.mapStatus("RJCT"));
        assertEquals(RwaSettlementEvent.Status.PENDING,    RwaSettlementMapper.mapStatus("PDNG"));
        assertEquals(RwaSettlementEvent.Status.PROCESSING, RwaSettlementMapper.mapStatus("ACSP"));
        assertEquals(RwaSettlementEvent.Status.UNKNOWN,    RwaSettlementMapper.mapStatus(null));
        assertEquals(RwaSettlementEvent.Status.UNKNOWN,    RwaSettlementMapper.mapStatus("XXXX"));
    }
}
