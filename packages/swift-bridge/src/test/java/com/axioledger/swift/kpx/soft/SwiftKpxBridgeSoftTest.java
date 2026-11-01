package com.axioledger.swift.kpx.soft;

import com.axioledger.swift.gpi.GpiTrackerClient;
import com.axioledger.swift.gpi.GpiTrackerClient.ChangedTransactionsPage;
import com.axioledger.swift.gpi.model.RwaSettlementEvent;
import com.axioledger.swift.kpx.SwiftKpxBridge;
import com.axioledger.swift.vrq.SwiftVrqAmlChecker;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Soft (mock) tests for {@link SwiftKpxBridge}.
 *
 * <p>All SWIFT I/O is mocked — no network, no SDK, no credentials required.
 * Tests cover the AML gate logic: only events with a non-null proof hash reach the consumer.
 */
@ExtendWith(MockitoExtension.class)
class SwiftKpxBridgeSoftTest {

    @Mock
    private GpiTrackerClient gpiClient;

    @Mock
    private SwiftVrqAmlChecker amlChecker;

    private List<RwaSettlementEvent> captured;
    private Consumer<RwaSettlementEvent> consumer;

    private SwiftKpxBridge bridge;

    private static final String UETR_1 = "uetr-settled-pass";
    private static final String UETR_2 = "uetr-settled-block";
    private static final String UETR_3 = "uetr-pending";

    @BeforeEach
    void setUp() {
        captured = new ArrayList<>();
        consumer = captured::add;
        bridge   = new SwiftKpxBridge(gpiClient, amlChecker, consumer);
    }

    // ── processUetr ───────────────────────────────────────────────────────────

    @Test
    void processUetr_forwardsSettledEventWithProof() throws IOException {
        RwaSettlementEvent settled  = acscEvent(UETR_1, null);
        RwaSettlementEvent withProof = acscEvent(UETR_1, "0xabc123");

        when(gpiClient.getTransactionDetails(UETR_1)).thenReturn(List.of(settled));
        when(amlChecker.attachProof(settled)).thenReturn(withProof);

        int forwarded = bridge.processUetr(UETR_1);

        assertEquals(1, forwarded);
        assertEquals(1, captured.size());
        assertEquals("0xabc123", captured.get(0).getVrqAmlProofHash());
    }

    @Test
    void processUetr_dropsEventWhenAmlBlocks() throws IOException {
        RwaSettlementEvent settled = acscEvent(UETR_2, null);
        RwaSettlementEvent blocked = acscEvent(UETR_2, null); // null hash = AML block

        when(gpiClient.getTransactionDetails(UETR_2)).thenReturn(List.of(settled));
        when(amlChecker.attachProof(settled)).thenReturn(blocked);

        int forwarded = bridge.processUetr(UETR_2);

        assertEquals(0, forwarded);
        assertTrue(captured.isEmpty(), "Blocked event must not reach consumer");
    }

    @Test
    void processUetr_skipsPendingEvents() throws IOException {
        RwaSettlementEvent pending = pendingEvent(UETR_3);

        when(gpiClient.getTransactionDetails(UETR_3)).thenReturn(List.of(pending));

        int forwarded = bridge.processUetr(UETR_3);

        assertEquals(0, forwarded);
        verifyNoInteractions(amlChecker);
        assertTrue(captured.isEmpty());
    }

    @Test
    void processUetr_continuesWhenAmlCheckerThrows() throws IOException {
        RwaSettlementEvent settled = acscEvent(UETR_1, null);

        when(gpiClient.getTransactionDetails(UETR_1)).thenReturn(List.of(settled));
        when(amlChecker.attachProof(any())).thenThrow(new IOException("VRQ unreachable"));

        // Must not propagate the IOException — bridge swallows per-event errors
        int forwarded = bridge.processUetr(UETR_1);

        assertEquals(0, forwarded);
        assertTrue(captured.isEmpty());
    }

    @Test
    void processUetr_returnsZeroForEmptyList() throws IOException {
        when(gpiClient.getTransactionDetails(UETR_1)).thenReturn(List.of());

        int forwarded = bridge.processUetr(UETR_1);

        assertEquals(0, forwarded);
    }

    // ── syncChangedTransactions ───────────────────────────────────────────────

    @Test
    void syncChangedTransactions_pagesUntilNoMore() throws IOException {
        RwaSettlementEvent ev1 = acscEvent(UETR_1, null);
        RwaSettlementEvent ev1Proof = acscEvent(UETR_1, "0xhash1");

        ChangedTransactionsPage page1 = new ChangedTransactionsPage(List.of(ev1), "page-2");
        ChangedTransactionsPage page2 = new ChangedTransactionsPage(List.of(), null);

        when(gpiClient.getChangedTransactions("2026-09-01T00:00:00Z", null)).thenReturn(page1);
        when(gpiClient.getChangedTransactions("2026-09-01T00:00:00Z", "page-2")).thenReturn(page2);
        when(amlChecker.attachProof(ev1)).thenReturn(ev1Proof);

        int total = bridge.syncChangedTransactions("2026-09-01T00:00:00Z");

        assertEquals(1, total);
        assertEquals(1, captured.size());
        verify(gpiClient, times(2)).getChangedTransactions(any(), any());
    }

    @Test
    void syncChangedTransactions_countsAcrossMultiplePages() throws IOException {
        RwaSettlementEvent ev1 = acscEvent("uetr-a", null);
        RwaSettlementEvent ev2 = acscEvent("uetr-b", null);
        RwaSettlementEvent ev1Proof = acscEvent("uetr-a", "0xh1");
        RwaSettlementEvent ev2Proof = acscEvent("uetr-b", "0xh2");

        ChangedTransactionsPage page1 = new ChangedTransactionsPage(List.of(ev1), "page-2");
        ChangedTransactionsPage page2 = new ChangedTransactionsPage(List.of(ev2), null);

        when(gpiClient.getChangedTransactions(any(), eq(null))).thenReturn(page1);
        when(gpiClient.getChangedTransactions(any(), eq("page-2"))).thenReturn(page2);
        when(amlChecker.attachProof(ev1)).thenReturn(ev1Proof);
        when(amlChecker.attachProof(ev2)).thenReturn(ev2Proof);

        int total = bridge.syncChangedTransactions("2026-09-05T00:00:00Z");

        assertEquals(2, total);
        assertEquals(2, captured.size());
    }

    // ── Consumer error isolation ──────────────────────────────────────────────

    @Test
    void processUetr_consumerExceptionDoesNotHaltOtherEvents() throws IOException {
        RwaSettlementEvent ev1 = acscEvent("uetr-a", null);
        RwaSettlementEvent ev2 = acscEvent("uetr-b", null);
        RwaSettlementEvent ev1Proof = acscEvent("uetr-a", "0xh1");
        RwaSettlementEvent ev2Proof = acscEvent("uetr-b", "0xh2");

        when(gpiClient.getTransactionDetails("uetr-a"))
                .thenReturn(List.of(ev1, ev2));
        when(amlChecker.attachProof(ev1)).thenReturn(ev1Proof);
        when(amlChecker.attachProof(ev2)).thenReturn(ev2Proof);

        AtomicInteger count = new AtomicInteger();
        SwiftKpxBridge faultyBridge = new SwiftKpxBridge(gpiClient, amlChecker, event -> {
            if (count.incrementAndGet() == 1) throw new RuntimeException("consumer failure");
        });

        // Should not throw — bridge wraps consumer errors per event
        assertDoesNotThrow(() -> faultyBridge.processUetr("uetr-a"));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static RwaSettlementEvent acscEvent(String uetr, String proofHash) {
        return RwaSettlementEvent.builder(uetr)
                .statusCode("ACSC")
                .amount(BigDecimal.valueOf(1_000_000))
                .currency("USD")
                .trackerEventTimestamp(Instant.now())
                .lastAgentBic("CHASUS33")
                .vrqAmlProofHash(proofHash)
                .build();
    }

    private static RwaSettlementEvent pendingEvent(String uetr) {
        return RwaSettlementEvent.builder(uetr)
                .statusCode("PDNG")
                .amount(BigDecimal.valueOf(500))
                .currency("EUR")
                .build();
    }
}
