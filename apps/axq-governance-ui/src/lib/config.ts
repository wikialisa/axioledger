/**
 * Wagmi + viem chain config for the AXQ Governance UI.
 *
 * Contract addresses are supplied at build time for the configured network.
 */

import { http, createConfig } from 'wagmi';
import { sepolia, mainnet } from 'viem/chains';
import { injected, metaMask } from 'wagmi/connectors';

const isMainnet = process.env.NEXT_PUBLIC_NETWORK === 'mainnet';

export const wagmiConfig = createConfig({
  chains:     isMainnet ? [mainnet] : [sepolia, mainnet],
  connectors: [injected(), metaMask()],
  transports: {
    [sepolia.id]:  http(),
    [mainnet.id]:  http(isMainnet ? process.env.NEXT_PUBLIC_RPC_URL : undefined),
  },
});

// ── Contract addresses ────────────────────────────────────────────────────────
// Set via environment variables; fall back to empty strings so the UI can
// render a "not configured" state rather than crashing.

export const CONTRACT_ADDRESSES = {
  axqToken:     (process.env.NEXT_PUBLIC_AXQ_TOKEN     ?? '') as `0x${string}`,
  axqGovernance:(process.env.NEXT_PUBLIC_AXQ_GOVERNANCE ?? '') as `0x${string}`,
  ansRegistry:  (process.env.NEXT_PUBLIC_ANS_REGISTRY  ?? '') as `0x${string}`,
} as const;
