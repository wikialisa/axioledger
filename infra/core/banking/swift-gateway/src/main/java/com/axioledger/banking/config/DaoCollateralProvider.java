package com.axioledger.banking.config;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Fetches the AXQ collateral ratio from the Treasury DAO on-chain parameter store.
 *
 * <h3>Purpose — Cố vấn Chỉ thị Implementation</h3>
 * <p>Replaces the hardcoded {@code calculateAXQCollateral(amount, 15)} in the v0.0.0 skeleton.
 * The Treasury DAO governs the minimum collateral percentage via an on-chain storage slot;
 * this provider reads it at runtime so the ratio can change without a service re-deploy.
 *
 * <h3>Resolution order</h3>
 * <ol>
 *   <li>Fetch from DAO RPC endpoint: {@code eth_call → TreasuryDAO.getCollateralBps()}</li>
 *   <li>If DAO unreachable, use {@code axioledger.min_axq_collateral_pct} from YAML</li>
 *   <li>If YAML value is 0, fall back to compile-time constant {@code DEFAULT_BPS = 1500}</li>
 * </ol>
 *
 * <p>The DAO returns basis points (bps): {@code 1500 bps = 15%}.
 * Callers receive an integer percentage (0–100).
 */
@Component
public class DaoCollateralProvider {

    private static final Logger log = LoggerFactory.getLogger(DaoCollateralProvider.class);

    /** Compile-time last-resort fallback: 15% = 1500 bps */
    private static final int DEFAULT_BPS = 1500;

    /**
     * ABI-encoded call to TreasuryDAO.getCollateralBps() (view function, no gas).
     * Function selector for getCollateralBps(): keccak256("getCollateralBps()")[0:4]
     */
    private static final String GET_COLLATERAL_BPS_CALLDATA = "0x8ef3e3d5";

    private final SwiftBankingConfig config;
    private final OkHttpClient httpClient;

    /** Cached value — refreshed on each call to avoid hammering RPC. */
    private final AtomicInteger cachedPct = new AtomicInteger(-1);

    public DaoCollateralProvider(SwiftBankingConfig config) {
        this(config, new OkHttpClient());
    }

    /** Test constructor — allows OkHttpClient injection. */
    DaoCollateralProvider(SwiftBankingConfig config, OkHttpClient httpClient) {
        this.config     = config;
        this.httpClient = httpClient;
    }

    /**
     * Returns the effective AXQ collateral percentage (integer, 0–100).
     *
     * <p>Calls the DAO RPC on each invocation (no in-process cache to keep the value
     * fresh as the DAO governance may update it). If the RPC call fails, the YAML
     * operator override is used as the floor.
     */
    public int getCollateralPct() {
        try {
            int daoPct = fetchFromDao();
            log.debug("DAO collateral ratio: {}%", daoPct);
            return daoPct;
        } catch (Exception e) {
            int fallback = config.getMinAxqCollateralPct() > 0
                    ? config.getMinAxqCollateralPct()
                    : bpsToPercent(DEFAULT_BPS);
            log.warn("DAO collateral fetch failed — using fallback {}%: {}", fallback, e.getMessage());
            return fallback;
        }
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private int fetchFromDao() throws IOException {
        String rpcUrl = config.getRpcUrl();
        if (rpcUrl == null || rpcUrl.isBlank()) {
            throw new IllegalStateException("axioledger.rpc_url not configured");
        }

        // Build eth_call JSON-RPC request
        String requestBody = """
                {
                  "jsonrpc": "2.0",
                  "method": "eth_call",
                  "params": [
                    {
                      "to": "%s",
                      "data": "%s"
                    },
                    "latest"
                  ],
                  "id": 1
                }
                """.formatted(
                config.getKpxRouter(),   // TreasuryDAO address (same router contract)
                GET_COLLATERAL_BPS_CALLDATA
        );

        okhttp3.RequestBody body = okhttp3.RequestBody.create(
                requestBody,
                okhttp3.MediaType.get("application/json; charset=utf-8")
        );

        Request request = new Request.Builder()
                .url(rpcUrl)
                .post(body)
                .header("Accept", "application/json")
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("RPC eth_call failed: HTTP " + response.code());
            }
            String raw = response.body() != null ? response.body().string() : "{}";
            return parseCollateralBpsResponse(raw);
        }
    }

    /**
     * Parses the eth_call hex result into an integer percentage.
     * Expected: {@code {"result":"0x00000000000000000000000000000000000000000000000000000000000005DC"}}
     * where {@code 0x5DC = 1500 bps = 15%}.
     */
    int parseCollateralBpsResponse(String json) {
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();
        if (!obj.has("result") || obj.get("result").isJsonNull()) {
            throw new IllegalArgumentException("eth_call returned no result");
        }
        String hex = obj.get("result").getAsString();
        if (hex.isBlank() || hex.equals("0x")) {
            throw new IllegalArgumentException("eth_call result is empty");
        }
        long bps = Long.parseUnsignedLong(hex.startsWith("0x") ? hex.substring(2) : hex, 16);
        return bpsToPercent((int) bps);
    }

    private static int bpsToPercent(int bps) {
        // 100 bps = 1%; clamp to [0, 100]
        int pct = bps / 100;
        return Math.max(0, Math.min(100, pct));
    }
}
