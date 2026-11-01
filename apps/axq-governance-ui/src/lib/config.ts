/**
 * Wagmi + viem chain config for the AXQ Governance UI.
 *
 * Replace the placeholder contract addresses with the real deployed
 * addresses once AXQGovernance is on Sepolia / mainnet.
 */

import { http, createConfig } from 'wagmi';
import { sepolia, mainnet } from 'viem/chains';
import { injected, metaMask } from 'wagmi/connectors';

export const wagmiConfig = createConfig({
  chains:     [sepolia, mainnet],
  connectors: [injected(), metaMask()],
  transports: {
    [sepolia.id]:  http(),
    [mainnet.id]:  http(),
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
