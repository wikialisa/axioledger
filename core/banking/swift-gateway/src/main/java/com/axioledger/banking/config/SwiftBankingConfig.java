package com.axioledger.banking.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Externalised configuration for the AXIO Banking Translator Service.
 *
 * <p>All values are bound from {@code application.yml} (profile-specific overrides allowed).
 * Sensitive values ({@code clientId}, {@code clientSecret}, {@code apiKey}) must be supplied
 * via environment variables — never committed in plaintext (see {@code application.yml} comments).
 *
 * <h3>Cố vấn Chỉ thị — Dynamic Collateral Ratio</h3>
 * <p>The AXQ collateral percentage is NOT hardcoded. {@link #getEffectiveCollateralPct()}
 * follows a three-tier resolution order:
 * <ol>
 *   <li>Treasury DAO on-chain parameter (fetched live by {@link DaoCollateralProvider})</li>
 *   <li>{@code axioledger.min_axq_collateral_pct} from {@code application.yml} (operator override)</li>
 *   <li>Hardcoded fallback {@code 15} — only if DAO unreachable AND no YAML value set</li>
 * </ol>
 * This design allows the Treasury DAO to adjust the ratio without a service re-deploy.
 */
@Component
@ConfigurationProperties(prefix = "axioledger")
public class SwiftBankingConfig {

    // ── SWIFT connectivity ─────────────────────────────────────────────────────

    private Swift swift = new Swift();

    // ── AXIOLEDGER / KPX ──────────────────────────────────────────────────────

    /** KPXRouterGateway.sol contract address on the active network. */
    private String kpxRouter;

    /** Base URL for Veraciphers VRQ compliance API. */
    private String vrqApi;

    /** JSON-RPC endpoint for the active AXQ chain. */
    private String rpcUrl;

    /**
     * Operator-level minimum collateral percentage (YAML override).
     * {@code 0} means "use DAO value exclusively" — no YAML floor.
     * Defaults to 15 if not set (matches v0.0.0 spec baseline).
     */
    private int minAxqCollateralPct = 15;

    // ── Accessors ──────────────────────────────────────────────────────────────

    public Swift getSwift()              { return swift; }
    public String getKpxRouter()         { return kpxRouter; }
    public String getVrqApi()            { return vrqApi; }
    public String getRpcUrl()            { return rpcUrl; }
    public int getMinAxqCollateralPct()  { return minAxqCollateralPct; }

    public void setSwift(Swift v)               { this.swift = v; }
    public void setKpxRouter(String v)          { this.kpxRouter = v; }
    public void setVrqApi(String v)             { this.vrqApi = v; }
    public void setRpcUrl(String v)             { this.rpcUrl = v; }
    public void setMinAxqCollateralPct(int v)   { this.minAxqCollateralPct = v; }

    // ── Nested: Swift ──────────────────────────────────────────────────────────

    public static class Swift {
        private Connectivity connectivity = new Connectivity();
        private Auth auth = new Auth();
        private Mgw mgw = new Mgw();

        public Connectivity getConnectivity() { return connectivity; }
        public Auth getAuth()                 { return auth; }
        public Mgw getMgw()                   { return mgw; }

        public void setConnectivity(Connectivity v) { this.connectivity = v; }
        public void setAuth(Auth v)                 { this.auth = v; }
        public void setMgw(Mgw v)                   { this.mgw = v; }

        public static class Connectivity {
            /** {@code sandbox} or {@code live} — live locked until v1.1.0 */
            private String environment = "sandbox";
            /** BIC8 registered under Kineto SPV (DP-1) */
            private String bic8;
            private String endpoint;

            public String getEnvironment() { return environment; }
            public String getBic8()        { return bic8; }
            public String getEndpoint()    { return endpoint; }

            public void setEnvironment(String v) { this.environment = v; }
            public void setBic8(String v)        { this.bic8 = v; }
            public void setEndpoint(String v)    { this.endpoint = v; }
        }

        public static class Auth {
            private String type = "oauth2";
            /** Injected from ${SWIFT_CLIENT_ID} — never commit plaintext */
            private String clientId;
            /** Injected from ${SWIFT_CLIENT_SECRET} — never commit plaintext */
            private String clientSecret;
            private String certPath;
            private String keyPath;
            private String caPath;

            public String getType()         { return type; }
            public String getClientId()     { return clientId; }
            public String getClientSecret() { return clientSecret; }
            public String getCertPath()     { return certPath; }
            public String getKeyPath()      { return keyPath; }
            public String getCaPath()       { return caPath; }

            public void setType(String v)         { this.type = v; }
            public void setClientId(String v)     { this.clientId = v; }
            public void setClientSecret(String v) { this.clientSecret = v; }
            public void setCertPath(String v)     { this.certPath = v; }
            public void setKeyPath(String v)      { this.keyPath = v; }
            public void setCaPath(String v)       { this.caPath = v; }
        }

        public static class Mgw {
            private String host = "127.0.0.1";
            private int port = 8443;
            /** Injected from ${SWIFT_MGW_API_KEY} — never commit plaintext */
            private String apiKey;

            public String getHost()   { return host; }
            public int getPort()      { return port; }
            public String getApiKey() { return apiKey; }

            public void setHost(String v)   { this.host = v; }
            public void setPort(int v)      { this.port = v; }
            public void setApiKey(String v) { this.apiKey = v; }
        }
    }
}
