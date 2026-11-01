/**
 * GovernanceDashboard v2 — refactored to use AXIO-DS components.
 *
 * Uses:
 *   <Button>         for all interactive elements
 *   <Input ansResolve> for proposal target address (auto TLP + anti-phishing)
 *   <AddressDisplay>  for proposer address masking
 *   <NamespaceBadge>  for governance namespace identity
 *   useToast()        for tx feedback
 */

'use client';

import { useState } from 'react';
import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
  useConnect,
  useDisconnect,
} from 'wagmi';
import { injected } from 'wagmi/connectors';
import {
  Button,
  Input,
  AddressDisplay,
  NamespaceBadge,
  Alert,
  useToast,
  type TLPLevel,
} from '@axioledger/axio-design-system';
import { AXQ_GOVERNANCE_ABI, AXQ_TOKEN_ABI } from '../../../../packages/evm-interop/src/abis';
import { ProposalCard }  from './ProposalCard';
import { CastVotePanel } from './CastVotePanel';
import { CONTRACT_ADDRESSES } from '../lib/config';
import type { Address } from 'viem';

// ── Wallet bar ────────────────────────────────────────────────────────────────

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
    <Button
      variant="filled"
      color="blue"
      size="medium"
      onClick={() => connect({ connector: injected() })}
    >
      Connect Wallet
    </Button>
  );
}

// ── ProposeForm ───────────────────────────────────────────────────────────────

function ProposeForm() {
  const [description, setDescription] = useState('');
  const [target,      setTarget]      = useState('');
  const [targetTLP,   setTargetTLP]   = useState<TLPLevel | null>(null);
  const { isConnected } = useAccount();
  const { toast }       = useToast();

  const { writeContract, data: txHash, isPending } = useWriteContract();
  const { isSuccess, isError, error } = useWaitForTransactionReceipt({ hash: txHash });

  if (isSuccess) {
    toast.success(`Proposal submitted — tx: ${txHash?.slice(0, 10)}…`);
  }
  if (isError) {
    toast.error((error as Error)?.message ?? 'Transaction failed');
  }

  const canSubmit = description.trim().length > 0
    && target.trim().length > 0
    && targetTLP !== 'blocked'
    && !isPending;

  const submit = () => {
    if (!canSubmit) return;
    writeContract({
      address:      CONTRACT_ADDRESSES.axqGovernance,
      abi:          AXQ_GOVERNANCE_ABI,
      functionName: 'propose',
      args:         [target.trim() as Address, 0n, '0x', description.trim()],
    });
  };

  if (!isConnected) return null;

  return (
    <div style={styles.formBox}>
      <h3 style={styles.sectionTitle}>New Proposal</h3>
      <p style={{ margin: '0 0 14px', fontSize: 13, color: 'var(--color-text-secondary)' }}>
        Requires ≥ 100,000 $AXQ in your wallet to propose.
      </p>

      {/* ANS-aware target address input — auto TLP guard */}
      <Input
        type="text"
        label="Target contract address"
        placeholder="alice.axq or 0x…"
        value={target}
        onChange={e => setTarget(e.target.value)}
        ansResolve
        onResolve={(_addr, level) => setTargetTLP(level)}
      />

      <div style={{ marginTop: 12 }}>
        <Input
          type="multiline"
          label="Proposal description"
          placeholder="Describe the on-chain action…"
          value={description}
          onChange={e => setDescription(e.target.value)}
        />
      </div>

      <div style={{ marginTop: 14 }}>
        <Button
          variant="filled"
          color="blue"
          size="medium"
          fullWidth
          loading={isPending}
          disabled={!canSubmit}
          onClick={submit}
        >
          Submit Proposal
        </Button>
      </div>

      {targetTLP === 'blocked' && (
        <div style={{ marginTop: 8 }}>
          <Alert variant="error">
            Target address blocked — resolve an ANS name first.
          </Alert>
        </div>
      )}
    </div>
  );
}

// ── Main dashboard ────────────────────────────────────────────────────────────

export function GovernanceDashboard() {
  const { address, isConnected } = useAccount();

  const { data: countData } = useReadContract({
    address:      CONTRACT_ADDRESSES.axqGovernance,
    abi:          AXQ_GOVERNANCE_ABI,
    functionName: 'proposalCount',
  });
  const count = countData ? Number(countData) : 0;

  const { data: balanceData } = useReadContract({
    address:      CONTRACT_ADDRESSES.axqToken,
    abi:          AXQ_TOKEN_ABI,
    functionName: 'balanceOf',
    args:         [address ?? '0x0000000000000000000000000000000000000000'],
    query:        { enabled: isConnected && !!address && CONTRACT_ADDRESSES.axqToken.length > 2 },
  });

  const govConfigured = CONTRACT_ADDRESSES.axqGovernance.length > 2;

  return (
    <div style={styles.page}>

      {/* ── Header ── */}
      <header style={styles.header}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
            <h1 style={styles.title}>AXQ Governance</h1>
            <NamespaceBadge name="dao.axq" />
          </div>
          <p style={styles.subtitle}>
            Quadratic voting · 7-day time-lock · Guardian Council veto (4/5)
          </p>
        </div>
        <WalletBar />
      </header>

      {/* Config warning */}
      {!govConfigured && (
        <div style={styles.notice}>
          ⚠️ Set <code>NEXT_PUBLIC_AXQ_GOVERNANCE</code> and{' '}
          <code>NEXT_PUBLIC_AXQ_TOKEN</code> in <code>.env.local</code>.
        </div>
      )}

      {/* Balance */}
      {isConnected && balanceData !== undefined && (
        <div style={styles.balanceBar}>
          <span style={{ color: 'var(--color-text-secondary)', fontSize: 13 }}>Your $AXQ:</span>
          <strong style={{ fontSize: 15, color: 'var(--color-text-primary)' }}>
            {(Number(balanceData) / 1e18).toLocaleString(undefined, { maximumFractionDigits: 2 })}
          </strong>
          {Number(balanceData) >= 100_000e18 && (
            <NamespaceBadge name="proposer.axq" />
          )}
        </div>
      )}

      {/* Stats */}
      {govConfigured && (
        <div style={styles.statsRow}>
          {[
            { label: 'Total Proposals', value: count },
            { label: 'Voting Period',   value: '3 days' },
            { label: 'Time-Lock',       value: '7 days' },
            { label: 'Guardian Seats',  value: '5 (4/5 veto)' },
          ].map(({ label, value }) => (
            <div key={label} style={styles.statCard}>
              <p style={styles.statLabel}>{label}</p>
              <p style={styles.statValue}>{value}</p>
            </div>
          ))}
        </div>
      )}

      {/* Propose form */}
      {govConfigured && <ProposeForm />}

      {/* Proposal list */}
      {govConfigured && count > 0 && (
        <section style={{ marginTop: 24 }}>
          <h2 style={styles.sectionTitle}>All Proposals</h2>
          {Array.from({ length: count }, (_, i) => {
            const id = BigInt(i + 1);
            return (
              <div key={id.toString()}>
                <ProposalCard
                  governanceAddress={CONTRACT_ADDRESSES.axqGovernance}
                  proposalId={id}
                />
                <CastVotePanel
                  governanceAddress={CONTRACT_ADDRESSES.axqGovernance}
                  proposalId={id}
                />
              </div>
            );
          })}
        </section>
      )}

      {govConfigured && count === 0 && (
        <div style={{ textAlign: 'center', padding: '48px 0' }}>
          <p style={{ color: 'var(--color-text-secondary)', marginBottom: 16 }}>
            No proposals yet. Submit the first one above.
          </p>
          <Button
            variant="outlined"
            color="blue"
            size="medium"
            onClick={() => document.querySelector<HTMLInputElement>('input')?.focus()}
          >
            Create First Proposal
          </Button>
        </div>
      )}
    </div>
  );
}

// ── Styles ────────────────────────────────────────────────────────────────────

const styles: Record<string, React.CSSProperties> = {
  page: {
    maxWidth: 760,
    margin: '0 auto',
    padding: '32px 16px',
    fontFamily: 'var(--font-family-base)',
    fontSize: 14,
    lineHeight: 1.6,
    color: 'var(--color-text-primary)',
  },
  header: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
    marginBottom: 24, flexWrap: 'wrap', gap: 12,
  },
  title:    { margin: 0, fontSize: 24, fontWeight: 700 },
  subtitle: { margin: 0, fontSize: 13, color: 'var(--color-text-secondary)' },
  balanceBar: {
    display: 'flex', alignItems: 'center', gap: 10,
    marginBottom: 20, fontSize: 13,
  },
  statsRow: {
    display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))',
    gap: 12, marginBottom: 24,
  },
  statCard: {
    background: 'var(--color-surface-raised)',
    border: '1px solid var(--color-border-default)',
    borderRadius: 10, padding: '12px 16px',
  },
  statLabel: { margin: 0, fontSize: 11, color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' },
  statValue: { margin: '4px 0 0', fontWeight: 700, fontSize: 20, color: 'var(--color-text-primary)' },
  formBox: {
    border: '1px solid var(--color-border-default)',
    borderRadius: 10, padding: '16px 20px', marginBottom: 24,
  },
  sectionTitle: { margin: '0 0 12px', fontSize: 16, fontWeight: 700 },
};
