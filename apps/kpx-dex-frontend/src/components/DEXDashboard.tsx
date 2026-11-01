/**
 * DEXDashboard — AXIO Design System v6 edition.
 *
 * Uses:
 *   <Button>        — all CTAs + wallet connect/disconnect
 *   <Card>          — info cards, router metadata boxes
 *   <Badge/Chip>    — network label, status indicators
 *   <NamespaceBadge>— protocol namespace identity
 *   <Alert>         — missing-config warnings
 *   useToast()      — swap / tx feedback
 *   <AddressDisplay>— wallet address masking + copy
 */

'use client';

import { useAccount, useConnect, useDisconnect, useReadContract } from 'wagmi';
import { injected, metaMask } from 'wagmi/connectors';
import {
  Button,
  Card,
  Badge,
  NamespaceBadge,
  Alert,
  AddressDisplay,
  useToast,
} from '@axioledger/axio-design-system';
import { KPX_ROUTER_GATEWAY_ABI } from '../../../../packages/evm-interop/src/abis';
import { CONTRACT_ADDRESSES, networkLabel } from '../lib/config';
import { SwapPanel } from './SwapPanel';
import { PoolStats } from './PoolStats';
import type { Address } from 'viem';

// ── WalletBar ─────────────────────────────────────────────────────────────────

function WalletBar() {
  const { address, isConnected } = useAccount();
  const { connect }    = useConnect();
  const { disconnect } = useDisconnect();
  const { toast }      = useToast();

  if (isConnected && address) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
        <AddressDisplay address={address} showBadge showCopy />
        <Button
          variant="outlined"
          color="black"
          size="small"
          onClick={() => { disconnect(); toast.info('Wallet disconnected'); }}
        >
          Disconnect
        </Button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
      <Button
        variant="filled"
        color="blue"
        size="medium"
        onClick={() => connect({ connector: injected() })}
      >
        Connect Wallet
      </Button>
      <Button
        variant="outlined"
        color="black"
        size="medium"
        onClick={() => connect({ connector: metaMask() })}
      >
        MetaMask
      </Button>
    </div>
  );
}

// ── RouterInfo ────────────────────────────────────────────────────────────────

function RouterInfo() {
  const routerAddress = CONTRACT_ADDRESSES.kpxRouter;
  const configured    = routerAddress.length > 2;

  const { data: feeRate } = useReadContract({
    address:      routerAddress,
    abi:          KPX_ROUTER_GATEWAY_ABI,
    functionName: 'feeRate',
    query:        { enabled: configured },
  });
  const { data: vrqVerifier } = useReadContract({
    address:      routerAddress,
    abi:          KPX_ROUTER_GATEWAY_ABI,
    functionName: 'vrqVerifier',
    query:        { enabled: configured },
  });

  if (!configured) {
    return (
      <Alert variant="warning" title="Router not configured">
        Set <code>NEXT_PUBLIC_KPX_ROUTER</code> in <code>.env.local</code> to enable swaps.
      </Alert>
    );
  }

  const feeDisplay = feeRate !== undefined
    ? `${(Number(feeRate) / 100).toFixed(2)}%`
    : '—';

  const NET = networkLabel();

  const stats = [
    { label: 'Router',       value: `${routerAddress.slice(0, 10)}…${routerAddress.slice(-6)}` },
    { label: 'Protocol Fee', value: feeDisplay },
    { label: 'VRQ Verifier', value: vrqVerifier ? `${(vrqVerifier as string).slice(0, 10)}…` : '—' },
    { label: 'Network',      value: NET },
  ];

  return (
    <div style={styles.statsGrid}>
      {stats.map(({ label, value }) => (
        <Card key={label} style={styles.statCard}>
          <p style={styles.statLabel}>{label}</p>
          <p style={styles.statValue}><code style={styles.mono}>{value}</code></p>
        </Card>
      ))}
    </div>
  );
}

// ── DEXDashboard ──────────────────────────────────────────────────────────────

export function DEXDashboard() {
  const routerConfigured = CONTRACT_ADDRESSES.kpxRouter.length > 2;
  const darkPool         = CONTRACT_ADDRESSES.darkPool;
  const hasPool          = darkPool.length > 2;
  const NET              = networkLabel();

  return (
    <div style={styles.page}>

      {/* ── Header ── */}
      <header style={styles.header}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
            <h1 style={styles.title}>KPX DEX</h1>
            <NamespaceBadge name="pool.kpx" />
            <Badge variant={NET === 'Localnet' ? 'info' : 'success'}>
              {NET}
            </Badge>
          </div>
          <p style={styles.subtitle}>
            Gasless swaps · AMM · RWA markets · Cross-chain bridge
          </p>
        </div>
        <WalletBar />
      </header>

      {/* ── Router metadata ── */}
      <div style={{ marginBottom: 24 }}>
        <RouterInfo />
      </div>

      {/* ── Swap + Pool side-by-side ── */}
      {routerConfigured && (
        <div style={styles.twoCol}>
          {hasPool ? (
            <SwapPanel poolAddress={darkPool as Address} />
          ) : (
            <Alert variant="info" title="No pool configured">
              Set <code>NEXT_PUBLIC_KPX_DARK_POOL</code> for a live swap pool.
            </Alert>
          )}
          {hasPool && (
            <PoolStats
              poolAddress={darkPool as Address}
              tokenASymbol="AXQ"
              tokenBSymbol="Pool-B"
            />
          )}
        </div>
      )}

      {/* ── Protocol info cards ── */}
      <section style={styles.cardsGrid}>
        {INFO_CARDS.map(({ title, body, badge }) => (
          <Card key={title} style={styles.infoCard}>
            {badge && (
              <span style={{ marginBottom: 8, display: 'block' }}>
                <NamespaceBadge name={badge} />
              </span>
            )}
            <p style={styles.cardTitle}>{title}</p>
            <p style={styles.cardBody}>{body}</p>
          </Card>
        ))}
      </section>

    </div>
  );
}

// ── Static content ────────────────────────────────────────────────────────────

const INFO_CARDS = [
  { badge: 'pool.kpx',       title: 'Gasless Swaps',        body: 'KPXRouterGateway routes orders through the AMM pool, wrapping ERC-20 approval and swap in a single meta-transaction.' },
  { badge: 'rwa.kpx',        title: 'RWA Markets',          body: 'Real-world assets are tokenised and deposited via depositRWA() after a VRQ ZK-compliance check.' },
  { badge: 'bridge.kpx',     title: 'Cross-chain Bridge',   body: 'Lock-mint mechanism bridges assets across EVM chains. SQX L2 support activates Phase 6.' },
  { badge: 'compliance.vrq', title: 'VRQ Compliance Gate',  body: 'All swaps pass through vrqVerifier — a ZK proof that the sender is AML-compliant without exposing PII.' },
];

// ── Styles (--axq-* token variables) ─────────────────────────────────────────

const styles: Record<string, React.CSSProperties> = {
  page: {
    maxWidth: 900,
    margin: '0 auto',
    padding: '32px 16px',
    fontFamily: 'var(--axq-font-family-base)',
    fontSize: 14,
    lineHeight: 1.6,
    color: 'var(--axq-color-text-primary)',
  },
  header: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
    marginBottom: 24, flexWrap: 'wrap', gap: 12,
  },
  title:   { margin: 0, fontSize: 26, fontWeight: 800 },
  subtitle:{ margin: 0, fontSize: 13, color: 'var(--axq-color-text-secondary)' },
  statsGrid: {
    display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))',
    gap: 12,
  },
  statCard:  { padding: '12px 16px' },
  statLabel: { margin: 0, fontSize: 11, color: 'var(--axq-color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.8px' },
  statValue: { margin: '4px 0 0', fontWeight: 700, fontSize: 13 },
  mono:      { fontFamily: 'var(--axq-font-family-mono, monospace)' },
  twoCol: {
    display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))',
    gap: 16, marginBottom: 24, alignItems: 'start',
  },
  cardsGrid: {
    display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
    gap: 12, borderTop: '1px solid var(--axq-color-border-default)', paddingTop: 24,
  },
  infoCard:  { padding: '14px 16px' },
  cardTitle: { margin: '0 0 6px', fontWeight: 700, fontSize: 13 },
  cardBody:  { margin: 0, fontSize: 12, color: 'var(--axq-color-text-secondary)', lineHeight: 1.5 },
};
