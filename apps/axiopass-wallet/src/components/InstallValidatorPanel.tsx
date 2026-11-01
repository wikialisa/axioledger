/**
 * InstallValidatorPanel — registers a passkey, builds the ERC-7579 install
 * payload, and calls VRQPasskeyValidator.onInstall() via wagmi writeContract.
 *
 * Flow:
 *  1. User clicks "Register Passkey" → browser shows TouchID / FaceID prompt
 *  2. We extract the P256 (x, y) key from the new credential
 *  3. We abi.encode(pubKeyX, pubKeyY, kycCommitment=0, zkProof=0x00) as stub
 *     (real KYC proof injected by the VRQ compliance oracle in production)
 *  4. We call onInstall(installData)
 */

'use client';

import { useState } from 'react';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { encodeAbiParameters, parseAbiParameters } from 'viem';
import { VRQ_PASSKEY_VALIDATOR_ABI } from '../../../../packages/evm-interop/src/abis';
import { Button, Alert, StepIndicator, type Step } from '@axioledger/axio-design-system';
import { createPasskey } from '../lib/webauthn';
import type { Address } from 'viem';

interface InstallValidatorPanelProps {
  validatorAddress: Address;
  onInstalled?: (pubKeyX: bigint, pubKeyY: bigint) => void;
}

type InstallStep = 'idle' | 'passkey' | 'tx' | 'confirming' | 'done' | 'error';

export function InstallValidatorPanel({
  validatorAddress,
  onInstalled,
}: InstallValidatorPanelProps) {
  const { address, isConnected } = useAccount();
  const [step, setStep]       = useState<InstallStep>('idle');
  const [errorMsg, setErrorMsg] = useState('');
  const [storedKey, setStoredKey] = useState<{ x: bigint; y: bigint } | null>(null);

  const { writeContract, data: txHash } = useWriteContract();
  const { isSuccess, isError: txError } = useWaitForTransactionReceipt({ hash: txHash });

  if (isSuccess && step !== 'done') setStep('done');
  if (txError   && step !== 'error') { setStep('error'); setErrorMsg('Transaction reverted'); }

  const handleInstall = async () => {
    if (!address) return;
    try {
      setStep('passkey');
      setErrorMsg('');

      // 1. Create passkey
      const userId = new TextEncoder().encode(address);
      const cred   = await createPasskey(userId, `Axiopass (${address.slice(0, 6)}…)`);

      setStoredKey({ x: cred.pubKeyX, y: cred.pubKeyY });
      setStep('tx');

      // 2. Build ERC-7579 install payload
      //    abi.encode(uint256 pubKeyX, uint256 pubKeyY, bytes32 kycCommitment, bytes zkProof)
      //    kycCommitment = 0x00…00 (stub — replaced by VRQ compliance oracle in prod)
      //    zkProof       = 0x00    (stub — single zero byte as minimal bytes value)
      const installData = encodeAbiParameters(
        parseAbiParameters('uint256, uint256, bytes32, bytes'),
        [
          cred.pubKeyX,
          cred.pubKeyY,
          ('0x' + '00'.repeat(32)) as `0x${string}`,
          '0x00',
        ],
      );

      // 3. Call onInstall
      writeContract({
        address:      validatorAddress,
        abi:          VRQ_PASSKEY_VALIDATOR_ABI,
        functionName: 'onInstall',
        args:         [installData],
      });

      setStep('confirming');
      onInstalled?.(cred.pubKeyX, cred.pubKeyY);
    } catch (err: unknown) {
      setStep('error');
      setErrorMsg((err as Error)?.message ?? 'Unknown error');
    }
  };

  // Map step to DS StepIndicator index
  const stepIndex = ({ idle: -1, passkey: 0, tx: 1, confirming: 2, done: 3, error: -1 } as Record<InstallStep, number>)[step] ?? -1;
  const dsSteps: Step[] = [
    { label: 'Biometric passkey' },
    { label: 'Build payload' },
    { label: 'Confirm on-chain' },
  ];

  if (!isConnected) {
    return (
      <p style={{ fontSize: 13, color: 'var(--color-text-secondary)', margin: '4px 0' }}>
        Connect your wallet to install the passkey validator.
      </p>
    );
  }

  if (step === 'done') {
    return (
      <div style={{ marginBottom: 20 }}>
        <Alert variant="success" title="VRQPasskeyValidator installed">
          {storedKey && (
            <>P256 key stored on-chain — X: <code>0x{storedKey.x.toString(16).slice(0, 12)}…</code></>
          )}
        </Alert>
      </div>
    );
  }

  return (
    <div style={styles.panel}>
      <h3 style={styles.title}>Install Passkey Validator</h3>
      <p style={styles.desc}>
        Replaces your seed phrase with a biometric passkey (FaceID / TouchID).
        The ERC-7579 module is installed directly on your smart account via
        the ZeroDev Kernel, dual-gated by a ZK compliance check (VRQ Layer).
      </p>

      <div style={{ marginBottom: 20 }}>
        <StepIndicator steps={dsSteps} activeStep={Math.max(0, stepIndex)} />
      </div>

      {step === 'idle' && (
        <Button variant="filled" color="navy" size="medium" onClick={handleInstall}>
          🔑 Register Passkey &amp; Install Module
        </Button>
      )}
      {step === 'passkey' && (
        <p style={styles.muted}>Waiting for biometric prompt…</p>
      )}
      {step === 'tx' && (
        <p style={styles.muted}>Sending install transaction…</p>
      )}
      {step === 'confirming' && (
        <p style={styles.muted}>
          Waiting for confirmation…
          {txHash && <> Tx: <code style={styles.code}>{txHash.slice(0, 12)}…</code></>}
        </p>
      )}
      {step === 'error' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <Alert variant="error">{errorMsg}</Alert>
          <Button variant="outlined" color="black" size="small" onClick={() => setStep('idle')}>
            Retry
          </Button>
        </div>
      )}
    </div>
  );
}

// ── Styles (CSS variables — dark mode safe) ───────────────────────────────────

const styles: Record<string, React.CSSProperties> = {
  panel: {
    border: '1px solid var(--color-border-default)',
    borderRadius: 8, padding: '16px 20px', marginBottom: 20,
    fontFamily: 'var(--font-family-base)', fontSize: 14,
  },
  title: { margin: '0 0 8px', fontSize: 15, fontWeight: 700 },
  desc:  { margin: '0 0 16px', fontSize: 13, color: 'var(--color-text-secondary)', lineHeight: 1.5 },
  muted: { fontSize: 13, color: 'var(--color-text-secondary)', margin: '4px 0' },
  code:  { fontFamily: 'monospace', fontSize: 12 },
};
