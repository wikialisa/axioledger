package com.axioledger.swift.soft;

import com.axioledger.swift.session.SwiftSessionManager;
import com.swift.commons.oauth.connection.interfaces.OAuthSession;
import com.swift.commons.oauth.connection.interfaces.OAuthToken;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Soft test (mock) for SwiftSessionManager.
 * Does NOT require SWIFT credentials — runs in CI (Giai đoạn A/B/C).
 */
@ExtendWith(MockitoExtension.class)
class SwiftSessionManagerSoftTest {

    @Mock private OAuthSession mockSession;
    @Mock private OAuthToken mockToken;

    private SwiftSessionManager manager;

    @BeforeEach
    void setUp() {
        when(mockToken.getAccessToken()).thenReturn("mock-bearer-token-abc123");
        when(mockToken.getRefreshToken()).thenReturn("mock-refresh-token-xyz");
        when(mockSession.getToken(anyString(), anyString())).thenReturn(mockToken);

        manager = new SwiftSessionManager(
                mockSession,
                "swift.apitracker!p",
                "sandbox.swift.com/oauth2/v1/token"
        );
    }

    @Test
    void init_shouldAcquireToken() {
        manager.init();
        assertNotNull(manager.getBearerToken());
        assertEquals("mock-bearer-token-abc123", manager.getBearerToken());
        verify(mockSession, times(1)).getToken("swift.apitracker!p", "sandbox.swift.com/oauth2/v1/token");
    }

    @Test
    void getBearerToken_beforeInit_shouldThrow() {
        assertThrows(IllegalStateException.class, () -> manager.getBearerToken());
    }

    @Test
    void forceRefresh_shouldUseRefreshToken() {
        OAuthToken refreshedToken = mock(OAuthToken.class);
        when(refreshedToken.getAccessToken()).thenReturn("refreshed-token-999");
        when(mockSession.refreshToken(anyString(), anyString(), anyString())).thenReturn(refreshedToken);

        manager.init();
        manager.forceRefresh();

        assertEquals("refreshed-token-999", manager.getBearerToken());
        verify(mockSession, times(1)).refreshToken(anyString(), anyString(), eq("mock-refresh-token-xyz"));
    }

    @Test
    void shutdown_shouldRevokeToken() {
        manager.init();
        manager.shutdown();
        verify(mockSession, times(1)).revokeToken("mock-bearer-token-abc123", "access_token");
    }

    @Test
    void forSandbox_factory_shouldUseSandboxAudience() {
        SwiftSessionManager sandbox = SwiftSessionManager.forSandbox(mockSession);
        sandbox.init();
        verify(mockSession).getToken(
                eq("swift.apitracker!p"),
                contains("sandbox.swift.com")
        );
    }
}
