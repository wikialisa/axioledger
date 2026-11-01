package com.axioledger.swift.soft;

import com.axioledger.swift.vrq.SwiftVrqAmlChecker;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Soft test for SwiftVrqAmlChecker.
 * Verifies DP-3: PII cleared after proof generation, only hash on-chain.
 */
class SwiftVrqAmlCheckerSoftTest {

    @Test
    void check_approved_returnsZkProofHashOnly() {
        SwiftVrqAmlChecker checker = new SwiftVrqAmlChecker(
                pii -> "0xdeadbeef1234567890abcdef",   // mock ZK proof generator
                bic -> true                              // mock SWIFT screener — cleared
        );

        Map<String, String> pii = new HashMap<>();
        pii.put("name", "John Doe");
        pii.put("address", "123 Main St");
        pii.put("dob", "1990-01-01");

        SwiftVrqAmlChecker.AmlCheckResult result = checker.check(pii, "DEUTDEDB");

        assertTrue(result.isApproved());
        assertEquals("0xdeadbeef1234567890abcdef", result.getZkProofHash());
        assertNull(result.getReason());

        // DP-3: PII map must be cleared after check
        assertTrue(pii.isEmpty(), "PII map must be cleared after proof generation (DP-3)");
    }

    @Test
    void check_swiftFlagged_returnsRejected() {
        SwiftVrqAmlChecker checker = new SwiftVrqAmlChecker(
                pii -> "0xaabbccdd",
                bic -> false   // SWIFT screening flagged
        );

        SwiftVrqAmlChecker.AmlCheckResult result =
                checker.check(new HashMap<>(), "SANCTIONED_BIC");

        assertFalse(result.isApproved());
        assertEquals(SwiftVrqAmlChecker.AmlCheckResult.Outcome.REJECTED, result.getOutcome());
        assertEquals("SWIFT_NETWORK_FLAGGED", result.getReason());
        // ZK proof hash still present (generated before screening)
        assertEquals("0xaabbccdd", result.getZkProofHash());
    }

    @Test
    void check_zkProofFailure_returnsFailed() {
        SwiftVrqAmlChecker checker = new SwiftVrqAmlChecker(
                pii -> { throw new RuntimeException("ZK circuit error"); },
                bic -> true
        );

        SwiftVrqAmlChecker.AmlCheckResult result =
                checker.check(new HashMap<>(), "DEUTDEDB");

        assertEquals(SwiftVrqAmlChecker.AmlCheckResult.Outcome.FAILED, result.getOutcome());
        assertNull(result.getZkProofHash());
        assertEquals("ZK_PROOF_GENERATION_FAILED", result.getReason());
    }
}
