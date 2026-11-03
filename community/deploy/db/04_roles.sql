-- =============================================================================
-- YOUR_INFRA — Database Users & Role-Based Access Control
-- =============================================================================
-- Chạy bằng superuser (postgres)
-- =============================================================================

-- ── Application roles ─────────────────────────────────────────────────────────

-- Service role cho fiat-connector-api (chỉ đọc/ghi payments + identity.kyc)
CREATE ROLE your_infra_fiat_connector LOGIN PASSWORD 'CHANGE_ME_fiat_connector_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_fiat_connector;
GRANT USAGE ON SCHEMA identity, payments, notifications TO your_infra_fiat_connector;
GRANT SELECT ON identity.users, identity.kyc_profiles TO your_infra_fiat_connector;
GRANT SELECT, INSERT, UPDATE ON payments.fiat_receipts TO your_infra_fiat_connector;
GRANT SELECT, UPDATE ON payments.p2p_orders TO your_infra_fiat_connector;
GRANT INSERT ON notifications.delivery_log TO your_infra_fiat_connector;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA payments TO your_infra_fiat_connector;

-- Service role cho otc-liquidity-engine
CREATE ROLE your_infra_otc LOGIN PASSWORD 'CHANGE_ME_otc_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_otc;
GRANT USAGE ON SCHEMA otc, identity, treasury TO your_infra_otc;
GRANT SELECT, INSERT, UPDATE ON otc.quotes TO your_infra_otc;
GRANT SELECT ON otc.counterparties TO your_infra_otc;
GRANT SELECT ON identity.kyc_profiles TO your_infra_otc;
GRANT SELECT ON treasury.reserve_snapshots TO your_infra_otc;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA otc TO your_infra_otc;

-- Service role cho indexer-subgraph (ghi treasury data)
CREATE ROLE your_infra_indexer LOGIN PASSWORD 'CHANGE_ME_indexer_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_indexer;
GRANT USAGE ON SCHEMA treasury TO your_infra_indexer;
GRANT SELECT, INSERT ON treasury.reserve_snapshots TO your_infra_indexer;
GRANT SELECT, INSERT ON treasury.swap_events TO your_infra_indexer;
GRANT SELECT, INSERT ON treasury.tvl_snapshots TO your_infra_indexer;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA treasury TO your_infra_indexer;

-- Service role cho swift-chain-bridge
CREATE ROLE AXVN_swift LOGIN PASSWORD 'CHANGE_ME_swift_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_swift;
GRANT USAGE ON SCHEMA swift, payments, treasury TO AXVN_swift;
GRANT SELECT, INSERT, UPDATE ON swift.messages TO AXVN_swift;
GRANT SELECT, INSERT, UPDATE ON swift.bridge_relay_log TO AXVN_swift;
GRANT SELECT, UPDATE ON payments.p2p_orders TO AXVN_swift;
GRANT SELECT ON treasury.reserve_snapshots TO AXVN_swift;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA swift TO AXVN_swift;

-- Service role cho KYC portal / kyc-portal
CREATE ROLE AXVN_kyc_portal LOGIN PASSWORD 'CHANGE_ME_kyc_portal_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_kyc_portal;
GRANT USAGE ON SCHEMA identity, notifications TO AXVN_kyc_portal;
GRANT SELECT, INSERT, UPDATE ON identity.users TO AXVN_kyc_portal;
GRANT SELECT, INSERT, UPDATE ON identity.kyc_profiles TO AXVN_kyc_portal;
GRANT SELECT, INSERT ON notifications.delivery_log TO AXVN_kyc_portal;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA identity TO AXVN_kyc_portal;

-- Service role cho merchant portal / pay-portal
CREATE ROLE AXVN_merchant LOGIN PASSWORD 'CHANGE_ME_merchant_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_merchant;
GRANT USAGE ON SCHEMA payments, identity TO AXVN_merchant;
GRANT SELECT, INSERT, UPDATE ON payments.merchants TO AXVN_merchant;
GRANT SELECT, INSERT, UPDATE ON payments.merchant_orders TO AXVN_merchant;
GRANT SELECT ON payments.cashback_rules TO AXVN_merchant;
GRANT SELECT, INSERT ON payments.cashback_ledger TO AXVN_merchant;
GRANT SELECT ON identity.kyc_profiles TO AXVN_merchant;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA payments TO AXVN_merchant;

-- Service role cho sandbox dashboard (read-heavy + alerts write)
CREATE ROLE AXVN_sandbox LOGIN PASSWORD 'CHANGE_ME_sandbox_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_sandbox;
GRANT USAGE ON SCHEMA sandbox, treasury, payments, identity TO AXVN_sandbox;
GRANT SELECT, UPDATE ON sandbox.participants TO AXVN_sandbox;
GRANT SELECT, INSERT ON sandbox.circuit_breaker_events TO AXVN_sandbox;
GRANT SELECT, INSERT, UPDATE ON sandbox.alerts TO AXVN_sandbox;
GRANT SELECT, INSERT ON sandbox.telemetry TO AXVN_sandbox;
GRANT SELECT ON treasury.tvl_snapshots TO AXVN_sandbox;
GRANT SELECT ON treasury.reserve_snapshots TO AXVN_sandbox;
GRANT SELECT ON payments.p2p_orders TO AXVN_sandbox;

-- Read-only role cho analytics / reporting
CREATE ROLE AXVN_readonly LOGIN PASSWORD 'CHANGE_ME_readonly_2026';
GRANT CONNECT ON DATABASE YOUR_INFRA TO your_infra_readonly;
GRANT USAGE ON SCHEMA identity, payments, treasury, otc, sandbox, swift, notifications TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA identity      TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA payments      TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA treasury      TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA otc           TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA sandbox       TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA swift         TO AXVN_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA notifications TO AXVN_readonly;

-- Admin role (full access — only for DBA / migrations)
CREATE ROLE AXVN_admin LOGIN PASSWORD 'CHANGE_ME_admin_2026' CREATEROLE;
GRANT ALL ON DATABASE YOUR_INFRA TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA identity      TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA payments      TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA treasury      TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA otc           TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA sandbox       TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA swift         TO AXVN_admin;
GRANT ALL ON ALL TABLES IN SCHEMA notifications TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA identity      TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA payments      TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA treasury      TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA otc           TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA sandbox       TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA swift         TO AXVN_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA notifications TO AXVN_admin;

-- ── Row-Level Security: sandbox.alerts (regulators see all, participants see own) ─
ALTER TABLE sandbox.alerts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE sandbox.participants ENABLE ROW LEVEL SECURITY;

-- Bypass for admin
CREATE POLICY rls_admin_sandbox_alerts ON sandbox.alerts
    USING (current_user IN ('AXVN_admin', 'postgres'));

CREATE POLICY rls_admin_sandbox_parts ON sandbox.participants
    USING (current_user IN ('AXVN_admin', 'postgres', 'AXVN_sandbox', 'AXVN_readonly'));

-- ── Revoke default public access ─────────────────────────────────────────────
REVOKE ALL ON SCHEMA identity      FROM PUBLIC;
REVOKE ALL ON SCHEMA payments      FROM PUBLIC;
REVOKE ALL ON SCHEMA treasury      FROM PUBLIC;
REVOKE ALL ON SCHEMA otc           FROM PUBLIC;
REVOKE ALL ON SCHEMA sandbox       FROM PUBLIC;
REVOKE ALL ON SCHEMA swift         FROM PUBLIC;
REVOKE ALL ON SCHEMA notifications FROM PUBLIC;
