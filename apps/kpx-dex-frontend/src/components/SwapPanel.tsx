/**
 * SwapPanel — gasless token swap via KPXRouterGateway.swapExactIn().
 *
 * Flow:
 *  1. User enters amountIn and selects tokenIn / pool
 *  2. On-chain quote: KPXLiquidityPool.getAmountOut(amountIn, tokenIn)
 *  3. User confirms → approve ERC-20 (if needed) → swapExactIn()
 *
 * For the Localnet staging sprint the pool address comes from .env.local
 * (NEXT_PUBLIC_KPX_DARK_POOL used as the default test pool until a
 * production AMM pool is deployed).
 */

'use client';

import { useState } from 'react';
import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
} from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import {
  KPX_ROUTER_GATEWAY_ABI,
  KPX_LIQUIDITY_POOL_ABI,
  AXQ_TOKEN_ABI,
} from '../../../../packages/evm-interop/src/abis';
import { CONTRACT_ADDRESSES } from '../lib/config';
import type { Address } from 'viem';

// ── helpers ───────────────────────────────────────────────────────────────────

function trimAddr(addr: string): string {
  return `${addr.slice(0, 8)}…${addr.slice(-6)}`;
}

// ── SwapPanel ─────────────────────────────────────────────────────────────────

interface SwapPanelProps {
  /** The KPXLiquidityPool address to route through */
  poolAddress: Address;
}

type SwapStep = 'idle' | 'approving' | 'swapping' | 'confirming' | 'done' | 'error';

export function SwapPanel({ poolAddress }: SwapPanelProps) {
  const { address, isConnected } = useAccount();
  const [amountIn,   setAmountIn]   = useState('');
  const [step,       setStep]       = useState<SwapStep>('idle');
  const [errMsg,     setErrMsg]     = useState('');

  const routerAddress = CONTRACT_ADDRESSES.kpxRouter;
  const tokenIn       = CONTRACT_ADDRESSES.axqToken; // default: AXQ → pool token B

  // Quote: how much tokenOut will we get?
  const amountInWei = amountIn && !Number.isNaN(parseFloat(amountIn))
    ? parseUnits(amountIn, 18)
    : 0n;

  const { data: quoteOut } = useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI,
    functionName: 'getAmountOut',
    args:         [amountInWei, tokenIn],
    query:        { enabled: amountInWei > 0n },
  });

  // Balance check
  const { data: balance } = useReadContract({
    address:      tokenIn,
    abi:          AXQ_TOKEN_ABI,
    functionName: 'balanceOf',
    args:         [address ?? '0x0000000000000000000000000000000000000000'],
    query:        { enabled: isConnected && !!address && tokenIn.length > 2 },
  });

  // Allowance check
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address:      tokenIn,
    abi:          AXQ_TOKEN_ABI,
    functionName: 'allowance',
    args:         [address ?? '0x0000000000000000000000000000000000000000', routerAddress],
    query:        { enabled: isConnected && !!address && tokenIn.length > 2 && routerAddress.length > 2 },
  });

  const needsApproval = allowance !== undefined && amountInWei > 0n && (allowance as bigint) < amountInWei;

  // Write contracts
  const { writeContractAsync: approve } = useWriteContract();
  const { writeContract: swap, data: swapTxHash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash: swapTxHash });

  if (isSuccess && step === 'confirming') setStep('done');

  const handleSwap = async () => {
    if (!address || amountInWei === 0n) return;
    setErrMsg('');
    try {
      // 1. Approve if needed
      if (needsApproval) {
        setStep('approving');
        await approve({
          address:      tokenIn,
          abi:          AXQ_TOKEN_ABI,
          functionName: 'approve',
          args:         [routerAddress, amountInWei],
        });
        await refetchAllowance();
      }

      // 2. Swap — 0.5% slippage guard
      setStep('swapping');
      const minOut = quoteOut ? ((quoteOut as bigint) * 995n) / 1000n : 0n;
      swap({
        address:      routerAddress,
        abi:          KPX_ROUTER_GATEWAY_ABI,
        functionName: 'swapExactIn',
        args:         [poolAddress, tokenIn, amountInWei, minOut, address],
      });
      setStep('confirming');
    } catch (err: unknown) {
      setStep('error');
      setErrMsg((err as Error)?.message ?? 'Unknown error');
    }
  };

  const resetStep = () => { setStep('idle'); setErrMsg(''); };

  const canSwap = isConnected
    && routerAddress.length > 2
    && amountInWei > 0n
    && step === 'idle';

  const fmtQuote = quoteOut
    ? parseFloat(formatUnits(quoteOut as bigint, 18)).toLocaleString(undefined, { maximumFractionDigits: 6 })
    : '—';
  const fmtBalance = balance !== undefined
    ? parseFloat(formatUnits(balance as bigint, 18)).toLocaleString(undefined, { maximumFractionDigits: 4 })
    : '—';

  return (
    <div style={styles.card}>
      <h3 style={styles.title}>Swap</h3>
      <p style={styles.route}>
        <code style={styles.code}>{tokenIn.length > 2 ? trimAddr(tokenIn) : 'AXQ Token'}</code>
        {' → '}
        <code style={styles.code}>{trimAddr(poolAddress)} (pool token B)</code>
      </p>

      {/* Amount in */}
      <div style={styles.inputRow}>
        <label style={styles.label}>You pay (AXQ)</label>
        <input
          type="number"
          min="0"
          step="any"
          value={amountIn}
          onChange={e => { setAmountIn(e.target.value); if (step === 'done') resetStep(); }}
          placeholder="0.0"
          style={styles.input}
          disabled={step !== 'idle' && step !== 'done'}
        />
        {balance !== undefined && (
          <p style={styles.balanceHint}>
            Balance: {fmtBalance} AXQ
            {' '}
            <button
              style={styles.maxBtn}
              onClick={() => setAmountIn(formatUnits(balance as bigint, 18))}
            >MAX</button>
          </p>
        )}
      </div>

      {/* Quote output */}
      <div style={{ ...styles.inputRow, marginTop: 12 }}>
        <label style={styles.label}>You receive (est.)</label>
        <div style={styles.quoteBox}>{fmtQuote}</div>
        {quoteOut !== undefined && (
          <p style={styles.balanceHint}>Slippage protection: 0.5% min-out enforced</p>
        )}
      </div>

      {/* Approval hint */}
      {needsApproval && step === 'idle' && (
        <p style={styles.approvalHint}>
          ⚠️ Approval required — KPXRouterGateway will be approved to spend {amountIn} AXQ.
        </p>
      )}

      {/* Action button */}
      {step === 'done' ? (
        <div style={styles.successBox}>
          ✅ Swap confirmed
          {swapTxHash && <> · Tx: <code style={styles.code}>{swapTxHash.slice(0, 12)}…</code></>}
          <button style={styles.resetBtn} onClick={resetStep}>New Swap</button>
        </div>
      ) : step === 'error' ? (
        <div style={styles.errorBox}>
          {errMsg}
          <button style={styles.resetBtn} onClick={resetStep}>Retry</button>
        </div>
      ) : (
        <button
          style={{
            ...styles.swapBtn,
            ...((!canSwap || isConfirming) ? styles.swapBtnDisabled : {}),
          }}
          onClick={handleSwap}
          disabled={!canSwap || isConfirming}
        >
          {step === 'approving'  ? 'Approving…'
           : step === 'swapping' ? 'Swapping…'
           : step === 'confirming' ? 'Confirming…'
           : needsApproval ? 'Approve & Swap'
           : 'Swap'}
        </button>
      )}

      {!isConnected && (
        <p style={styles.balanceHint}>Connect your wallet above to swap.</p>
      )}
    </div>
  );
}

// ── Styles (CSS variables — dark mode safe) ───────────────────────────────────

const styles: Record<string, React.CSSProperties> = {
  card: {
    border: '1px solid var(--color-border-default)',
    borderRadius: 10, padding: '20px 24px', marginBottom: 20,
    fontFamily: 'var(--font-family-base)', fontSize: 14,
    background: 'var(--color-surface-default)',
  },
  title:      { margin: '0 0 4px', fontSize: 16, fontWeight: 700, color: 'var(--color-text-primary)' },
  route:      { margin: '0 0 16px', fontSize: 12, color: 'var(--color-text-secondary)' },
  code:       { fontFamily: 'monospace', fontSize: 12 },
  inputRow:   { display: 'flex', flexDirection: 'column', gap: 4 },
  label:      { fontSize: 12, color: 'var(--color-text-secondary)', fontWeight: 600 },
  input: {
    padding: '10px 12px', borderRadius: 8, fontSize: 16, fontWeight: 700,
    border: '1.5px solid var(--color-border-default)',
    background: 'var(--color-surface-raised)',
    color: 'var(--color-text-primary)', outline: 'none',
    width: '100%', boxSizing: 'border-box',
  },
  quoteBox: {
    padding: '10px 12px', borderRadius: 8, fontSize: 16, fontWeight: 700,
    border: '1.5px dashed var(--color-border-default)',
    background: 'var(--color-surface-raised)',
    color: 'var(--color-text-primary)',
  },
  balanceHint:  { margin: '2px 0 0', fontSize: 12, color: 'var(--color-text-secondary)' },
  approvalHint: { margin: '10px 0', fontSize: 12, color: 'var(--color-status-warning-default)' },
  maxBtn: {
    background: 'none', border: 'none', cursor: 'pointer',
    color: 'var(--color-link-default)', fontSize: 12, fontWeight: 700, padding: 0,
  },
  swapBtn: {
    marginTop: 16, width: '100%', padding: '12px 0', borderRadius: 8,
    fontSize: 15, fontWeight: 700, cursor: 'pointer', border: 'none',
    background: 'var(--color-action-primary-default)',
    color: 'var(--color-text-on-action)',
    transition: 'opacity 0.15s',
  },
  swapBtnDisabled: { opacity: 0.4, cursor: 'not-allowed' },
  successBox: {
    marginTop: 14, padding: '10px 14px', borderRadius: 8,
    background: 'var(--color-status-success-subtle)',
    color: 'var(--color-status-success-default)',
    fontSize: 13, fontWeight: 600,
  },
  errorBox: {
    marginTop: 14, padding: '10px 14px', borderRadius: 8,
    background: 'var(--color-status-error-subtle)',
    color: 'var(--color-status-error-default)',
    fontSize: 13,
  },
  resetBtn: {
    marginLeft: 12, padding: '2px 10px', borderRadius: 6, border: 'none',
    cursor: 'pointer', fontSize: 12, fontWeight: 600,
    background: 'var(--color-surface-raised)', color: 'var(--color-text-primary)',
  },
};
