/**
 * ProposalCard — renders a single governance proposal with live vote data.
 *
 * Reads `AXQGovernance.proposals(id)` via the wagmi hook from evm-interop,
 * then shows vote tallies and the current state (Active / Queued / Executed /
 * Vetoed / Defeated / Pending).
 */

'use client';

import { useReadContract } from 'wagmi';
import { AXQ_GOVERNANCE_ABI } from '../../../../packages/evm-interop/src/abis';
import { Skeleton, ProgressBar, Alert } from '@axioledger/axio-design-system';
import type { Address } from 'viem';

// ── Types ─────────────────────────────────────────────────────────────────────

interface ProposalData {
  id:            bigint;
  proposer:      Address;
  description:   string;
  voteStart:     bigint;
  voteEnd:       bigint;
  executionTime: bigint;
  votesFor:      bigint;
  votesAgainst:  bigint;
  executed:      boolean;
  vetoed:        boolean;
}

type ProposalState =
  | 'Pending' | 'Active' | 'Vetoed' | 'Queued'
  | 'Executed' | 'Defeated' | 'Unknown';

function deriveState(p: ProposalData, nowSec: bigint): ProposalState {
  if (p.vetoed)                             return 'Vetoed';
  if (p.executed)                           return 'Executed';
  if (nowSec < p.voteStart)                 return 'Pending';
  if (nowSec <= p.voteEnd)                  return 'Active';
  if (p.votesFor <= p.votesAgainst)         return 'Defeated';
  if (nowSec < p.executionTime)             return 'Queued';
  return 'Queued';
}

type StateVariant = 'success' | 'info' | 'error' | 'warning';
const STATE_INFO: Record<ProposalState, { variant: StateVariant | null; label: string }> = {
  Pending:  { variant: null,      label: 'Pending'  },
  Active:   { variant: 'success', label: 'Active'   },
  Vetoed:   { variant: 'error',   label: 'Vetoed'   },
  Queued:   { variant: 'warning', label: 'Queued'   },
  Executed: { variant: 'info',    label: 'Executed' },
  Defeated: { variant: null,      label: 'Defeated' },
  Unknown:  { variant: null,      label: '?'        },
};

// ── Component ─────────────────────────────────────────────────────────────────

interface ProposalCardProps {
  governanceAddress: Address;
  proposalId: bigint;
}

export function ProposalCard({ governanceAddress, proposalId }: ProposalCardProps) {
  const { data, isLoading, isError } = useReadContract({
    address:      governanceAddress,
    abi:          AXQ_GOVERNANCE_ABI,
    functionName: 'proposals',
    args:         [proposalId],
  });

  if (isLoading) {
    return (
      <div style={styles.card}>
        <Skeleton variant="text" width="30%" />
        <Skeleton variant="text" width="80%" style={{ marginTop: 8 }} />
        <Skeleton variant="text" width="60%" style={{ marginTop: 8 }} />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div style={styles.card}>
        <Alert variant="error">Failed to load proposal #{proposalId.toString()}</Alert>
      </div>
    );
  }

  // data is a tuple — destructure by index (wagmi v2 returns tuple as array)
  const proposal: ProposalData = {
    id:            data[0],
    proposer:      data[1],
    description:   data[2],
    voteStart:     data[6],
    voteEnd:       data[7],
    executionTime: data[8],
    votesFor:      data[9],
    votesAgainst:  data[10],
    executed:      data[11],
    vetoed:        data[12],
  };

  const nowSec   = BigInt(Math.floor(Date.now() / 1000));
  const state    = deriveState(proposal, nowSec);
  const stateInfo = STATE_INFO[state];
  const total    = proposal.votesFor + proposal.votesAgainst;
  const forPct   = total > 0n ? Number((proposal.votesFor  * 10000n) / total) / 100 : 0;
  const agstPct  = total > 0n ? Number((proposal.votesAgainst * 10000n) / total) / 100 : 0;

  return (
    <div style={styles.card}>
      {/* Header */}
      <div style={styles.header}>
        <span style={styles.id}>#{proposal.id.toString()}</span>
        {stateInfo.variant ? (
          <span style={styles.stateBadge} data-variant={stateInfo.variant}>{stateInfo.label}</span>
        ) : (
          <span style={styles.stateBadgeMuted}>{stateInfo.label}</span>
        )}
      </div>

      {/* Description */}
      <p style={styles.description}>{proposal.description || '(no description)'}</p>

      {/* Proposer */}
      <p style={styles.meta}>
        Proposed by{' '}
        <code style={styles.code}>
          {proposal.proposer.slice(0, 6)}…{proposal.proposer.slice(-4)}
        </code>
      </p>

      {/* Vote bars — using DS ProgressBar */}
      <div style={styles.voteSection}>
        <div style={styles.voteRow}>
          <span style={styles.voteLabel}>For</span>
          <ProgressBar value={forPct} size="thin" />
          <span style={styles.votePct}>{forPct.toFixed(1)}%</span>
        </div>
        <div style={styles.voteRow}>
          <span style={styles.voteLabel}>Against</span>
          <ProgressBar value={agstPct} size="thin" />
          <span style={styles.votePct}>{agstPct.toFixed(1)}%</span>
        </div>
      </div>

      {/* Raw vote weights */}
      <p style={styles.meta}>
        Quadratic votes — For: <strong>{proposal.votesFor.toString()}</strong>
        {' · '}Against: <strong>{proposal.votesAgainst.toString()}</strong>
      </p>
    </div>
  );
}

// ── Styles (CSS variables — dark mode safe) ───────────────────────────────────

const styles: Record<string, React.CSSProperties> = {
  card: {
    border: '1px solid var(--color-border-default)',
    borderRadius: 8, padding: '16px 20px', marginBottom: 16,
    background: 'var(--color-surface-default)',
    fontFamily: 'var(--font-family-base)',
    fontSize: 14, lineHeight: 1.6,
  },
  header:      { display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 },
  id:          { fontWeight: 700, fontSize: 15, color: 'var(--color-text-primary)' },
  stateBadge: {
    borderRadius: 12, padding: '2px 10px', fontSize: 12, fontWeight: 600,
    background: 'var(--color-status-info-subtle)',
    color: 'var(--color-status-info-default)',
  },
  stateBadgeMuted: {
    borderRadius: 12, padding: '2px 10px', fontSize: 12, fontWeight: 600,
    background: 'var(--color-surface-raised)',
    color: 'var(--color-text-secondary)',
  },
  description: { margin: '0 0 8px', color: 'var(--color-text-primary)' },
  meta:        { margin: '4px 0', color: 'var(--color-text-secondary)', fontSize: 12 },
  code:        { fontFamily: 'monospace', color: 'var(--color-text-primary)' },
  voteSection: { margin: '8px 0' },
  voteRow:     { display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 },
  voteLabel:   { width: 50, fontSize: 12, color: 'var(--color-text-secondary)', flexShrink: 0 },
  votePct:     { width: 40, fontSize: 12, color: 'var(--color-text-secondary)', textAlign: 'right', flexShrink: 0 },
};
