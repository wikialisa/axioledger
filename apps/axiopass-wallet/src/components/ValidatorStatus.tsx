/**
 * ValidatorStatus — reads on-chain state of VRQPasskeyValidator for a wallet.
 *
 * Shows whether the ERC-7579 passkey module is installed, the stored P256
 * public key coordinates, and the zkVerifier address.
 */

'use client';

import { useReadContract } from 'wagmi';
import { VRQ_PASSKEY_VALIDATOR_ABI } from '../../../../packages/evm-interop/src/abis';
import { Skeleton } from '@axioledger/axio-design-system';
import type { Address } from 'viem';

interface ValidatorStatusProps {
  validatorAddress: Address;
  smartAccount:     Address;
}

export function ValidatorStatus({ validatorAddress, smartAccount }: ValidatorStatusProps) {
  const { data: installed, isLoading: loadingInstall } = useReadContract({
    address:      validatorAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI,
    functionName: 'isInitialized',
    args:         [smartAccount],
  });

  const { data: pubKeyX } = useReadContract({
    address:      validatorAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI,
    functionName: 'accountPubKeyX',
    args:         [smartAccount],
    query:        { enabled: !!installed },
  });

  const { data: pubKeyY } = useReadContract({
    address:      validatorAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI,
    functionName: 'accountPubKeyY',
    args:         [smartAccount],
    query:        { enabled: !!installed },
  });

  const { data: zkVerifier } = useReadContract({
    address:      validatorAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI,
    functionName: 'zkVerifier',
  });

  if (loadingInstall) {
    return (
      <div style={styles.card}>
        <Skeleton variant="text" width="60%" />
        <Skeleton variant="text" width="40%" style={{ marginTop: 8 }} />
        <Skeleton variant="text" width="80%" style={{ marginTop: 8 }} />
      </div>
    );
  }

  return (
    <div style={styles.card}>
      <h3 style={styles.title}>VRQPasskeyValidator Status</h3>

      <Row label="Module installed" value={installed ? '✓ Yes' : '✗ No'} ok={!!installed} />
      <Row label="zkVerifier"
        value={zkVerifier ? `${(zkVerifier as string).slice(0, 10)}…` : '—'} />

      {installed && pubKeyX !== undefined && pubKeyY !== undefined && (
        <>
          <Row label="PubKey X" value={`0x${(pubKeyX as bigint).toString(16).slice(0, 16)}…`} />
          <Row label="PubKey Y" value={`0x${(pubKeyY as bigint).toString(16).slice(0, 16)}…`} />
        </>
      )}

      <p style={styles.hint}>
        P256 Verifier (Daimo):{' '}
        <code style={styles.code}>0xc2b781…754De4</code> (deterministic CREATE2)
      </p>
    </div>
  );
}

function Row({ label, value, ok }: { label: string; value: string; ok?: boolean }) {
  return (
    <div style={styles.row}>
      <span style={styles.rowLabel}>{label}</span>
      <span style={{
        ...styles.rowValue,
        color: ok === false
          ? 'var(--color-status-error-default)'
          : ok === true
            ? 'var(--color-status-success-default)'
            : 'var(--color-text-primary)',
      }}>
        {value}
      </span>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  card: {
    border: '1px solid var(--color-border-default)',
    borderRadius: 8, padding: '16px 20px', marginBottom: 20,
    fontFamily: 'var(--font-family-base)',
    fontSize: 13, lineHeight: 1.6, color: 'var(--color-text-primary)',
  },
  title:    { margin: '0 0 12px', fontSize: 15, fontWeight: 700 },
  row:      { display: 'flex', justifyContent: 'space-between', padding: '3px 0', borderBottom: '1px solid var(--color-border-default)' },
  rowLabel: { color: 'var(--color-text-secondary)' },
  rowValue: { fontFamily: 'monospace', fontWeight: 600 },
  hint:     { margin: '10px 0 0', fontSize: 12, color: 'var(--color-text-secondary)' },
  code:     { fontFamily: 'monospace' },
};
