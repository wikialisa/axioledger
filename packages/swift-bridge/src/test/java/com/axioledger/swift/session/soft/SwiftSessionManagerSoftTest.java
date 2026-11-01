package com.axioledger.swift.session.soft;

import com.axioledger.swift.session.SwiftSessionManager;
import com.swift.commons.oauth.connection.constants.OAuthConstants;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Soft (mock) tests for {@link SwiftSessionManager}.
 *
 * <p>No real SWIFT credentials or network connectivity required.
 * Tests cover compile-time constants and SDK-independent logic only,
 * since the actual token fetch requires live credentials (Phase A hard test).
 */
class SwiftSessionManagerSoftTest {

    @Test
    void scopeConstant_isCorrect() {
        assertEquals("swift.apitracker!p", SwiftSessionManager.SCOPE_GPI_TRACKER);
    }

    @Test
    void audienceSet_sandboxProdHasCorrectUrl() {
        // Verify that SANDBOX_PROD resolves to the expected SWIFT Sandbox token URL
        String audience = OAuthConstants.AUDIENCE_SET.SANDBOX_PROD.getValue();
        assertTrue(audience.contains("sandbox.swift.com"),
                "SANDBOX_PROD audience must point to sandbox.swift.com, got: " + audience);
    }

    @Test
    void audienceSet_onPremisesProdIsLocked() {
        // Verify ON_PREMISES_PROD is distinct from sandbox — used to gate DP-5 enforcement
        String prod    = OAuthConstants.AUDIENCE_SET.ON_PREMISES_PROD.getValue();
        String sandbox = OAuthConstants.AUDIENCE_SET.SANDBOX_PROD.getValue();
        assertNotEquals(prod, sandbox,
                "ON_PREMISES_PROD and SANDBOX_PROD must be different audience values");
        assertTrue(prod.contains("swiftnet.sipn"),
                "ON_PREMISES_PROD must point to swiftnet.sipn, got: " + prod);
    }
}
