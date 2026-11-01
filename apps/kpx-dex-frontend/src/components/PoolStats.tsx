/**
 * PoolStats — reads live reserve data from a KPXLiquidityPool.
 *
 * Displays reserveA, reserveB, current priceAInB, and total LP supply.
 * Used inside DEXDashboard when a pool address is available.
 */

'use client';

import { useReadContract } from 'wagmi';
import { KPX_LIQUIDITY_POOL_ABI } from '../../../../packages/evm-interop/src/abis';
import type { Address } from 'viem';

interface PoolStatsProps {
  poolAddress: Address;
  tokenASymbol?: string;
  tokenBSymbol?: string;
}

export function PoolStats({ poolAddress, tokenASymbol = 'Token A', tokenBSymbol = 'Token B' }: PoolStatsProps) {
  const { data: reserveA } = useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI,
    functionName: 'reserveA',
  });

  const { data: reserveB } = useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI,
    functionName: 'reserveB',
  });

  const { data: price } = useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI,
    functionName: 'priceAInB',
  });

  const { data: totalSupply } = useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI,
    functionName: 'totalSupply',
  });

  const fmt = (v: bigint | undefined, decimals = 18): string =>
    v !== undefined
      ? (Number(v) / 10 ** decimals).toLocaleString(undefined, { maximumFractionDigits: 4 })
      : '—';

  return (
    <div style={styles.card}>
      <h3 style={styles.title}>Pool Stats</h3>
      <p style={styles.poolAddr}>
        Pool: <code style={styles.code}>{poolAddress.slice(0, 10)}…{poolAddress.slice(-6)}</code>
      </p>
      <div style={styles.grid}>
        {[
          { label: `Reserve ${tokenASymbol}`, value: fmt(reserveA as bigint) },
          { label: `Reserve ${tokenBSymbol}`, value: fmt(reserveB as bigint) },
          { label: `Price (${tokenASymbol} in ${tokenBSymbol})`, value: fmt(price as bigint) },
          { label: 'LP Token Supply',          value: fmt(totalSupply as bigint) },
        ].map(({ label, value }) => (
          <div key={label} style={styles.statBox}>
            <p style={styles.statLabel}>{label}</p>
            <p style={styles.statValue}>{value}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  card: {
    border: '1px solid var(--color-border-default)',
    borderRadius: 10, padding: '16px 20px', marginBottom: 20,
    fontFamily: 'var(--font-family-base)', fontSize: 14,
    background: 'var(--color-surface-default)',
  },
  title:    { margin: '0 0 4px', fontSize: 15, fontWeight: 700, color: 'var(--color-text-primary)' },
  poolAddr: { margin: '0 0 14px', fontSize: 12, color: 'var(--color-text-secondary)' },
  code:     { fontFamily: 'monospace' },
  grid:     { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', gap: 12 },
  statBox:  {
    background: 'var(--color-surface-raised)',
    border: '1px solid var(--color-border-default)',
    borderRadius: 8, padding: '10px 14px',
  },
  statLabel: { margin: 0, fontSize: 11, color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.8px' },
  statValue: { margin: '4px 0 0', fontWeight: 700, fontSize: 17, color: 'var(--color-text-primary)' },
};
