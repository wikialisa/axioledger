/**
 * CastVotePanel — vote For / Against on a proposal.
 *
 * Calls AXQGovernance.castVote(id, support) via wagmi writeContract.
 * Shows spinner while the tx is pending and a success/error message after.
 */

'use client';

import { useState } from 'react';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { AXQ_GOVERNANCE_ABI } from '../../../../packages/evm-interop/src/abis';
import { Button, Alert } from '@axioledger/axio-design-system';
import type { Address } from 'viem';

interface CastVotePanelProps {
  governanceAddress: Address;
  proposalId: bigint;
  disabled?: boolean; // pass true when hasVoted === true
}

export function CastVotePanel({
  governanceAddress,
  proposalId,
  disabled = false,
}: CastVotePanelProps) {
  const { isConnected } = useAccount();
  const [pendingSupport, setPendingSupport] = useState<boolean | null>(null);

  const { writeContract, data: txHash, isPending, isError, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash: txHash });

  const vote = (support: boolean) => {
    setPendingSupport(support);
    writeContract({
      address:      governanceAddress,
      abi:          AXQ_GOVERNANCE_ABI,
      functionName: 'castVote',
      args:         [proposalId, support],
    });
  };

  if (!isConnected) {
    return (
      <p style={{ fontSize: 13, color: 'var(--color-text-secondary)', margin: '4px 0' }}>
        Connect your wallet to vote.
      </p>
    );
  }

  if (disabled || isSuccess) {
    return (
      <div style={{ paddingTop: 8 }}>
        <Alert variant={isSuccess ? 'success' : 'info'}>
          {isSuccess ? 'Vote submitted successfully.' : 'You have already voted on this proposal.'}
        </Alert>
      </div>
    );
  }

  return (
    <div style={styles.panel}>
      <p style={styles.label}>Cast your quadratic vote:</p>
      <div style={styles.row}>
        <Button
          variant="filled"
          color="green"
          size="medium"
          loading={isPending && pendingSupport === true}
          disabled={isPending || isConfirming}
          onClick={() => vote(true)}
        >
          👍 Vote For
        </Button>
        <Button
          variant="filled"
          color="error"
          size="medium"
          loading={isPending && pendingSupport === false}
          disabled={isPending || isConfirming}
          onClick={() => vote(false)}
        >
          👎 Vote Against
        </Button>
      </div>

      {isConfirming && (
        <p style={styles.muted}>Waiting for on-chain confirmation…</p>
      )}
      {isError && (
        <div style={{ marginTop: 6 }}>
          <Alert variant="error">{(error as Error)?.message ?? 'Transaction failed.'}</Alert>
        </div>
      )}
      {txHash && !isSuccess && (
        <p style={styles.muted}>Tx: <code>{txHash.slice(0, 10)}…</code></p>
      )}
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  panel: {
    borderTop: '1px solid var(--color-border-default)',
    paddingTop: 12, marginTop: 8,
    fontFamily: 'var(--font-family-base)',
  },
  label: { margin: '0 0 8px', fontSize: 13, color: 'var(--color-text-secondary)' },
  row:   { display: 'flex', gap: 10 },
  muted: { fontSize: 12, color: 'var(--color-text-secondary)', margin: '4px 0' },
};
