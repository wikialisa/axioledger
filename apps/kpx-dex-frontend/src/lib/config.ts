/**
 * Wagmi config + contract addresses for KPX DEX Frontend.
 *
 * Contract addresses are read from environment variables (.env.local).
 * Falls back to empty strings so the UI can render a "not configured"
 * state rather than crashing at build time.
 */

import { http, createConfig } from 'wagmi';
import { hardhat, sepolia, mainnet } from 'viem/chains';
import { injected, metaMask } from 'wagmi/connectors';

export const wagmiConfig = createConfig({
  chains:     [hardhat, sepolia, mainnet],
  connectors: [injected(), metaMask()],
  transports: {
    [hardhat.id]:  http(process.env.NEXT_PUBLIC_RPC_URL ?? 'http://127.0.0.1:8545'),
    [sepolia.id]:  http(),
    [mainnet.id]:  http(),
  },
});

// ── Contract addresses ────────────────────────────────────────────────────────

export const CONTRACT_ADDRESSES = {
  kpxRouter:   (process.env.NEXT_PUBLIC_KPX_ROUTER   ?? '') as `0x${string}`,
  axqToken:    (process.env.NEXT_PUBLIC_AXQ_TOKEN     ?? '') as `0x${string}`,
  ansRegistry: (process.env.NEXT_PUBLIC_ANS_REGISTRY  ?? '') as `0x${string}`,
  vrqVerifier: (process.env.NEXT_PUBLIC_KPX_VRQ_VERIFIER ?? '') as `0x${string}`,
  darkPool:    (process.env.NEXT_PUBLIC_KPX_DARK_POOL ?? '') as `0x${string}`,
} as const;

// ── Network display name ──────────────────────────────────────────────────────

export function networkLabel(): string {
  const chainId = parseInt(process.env.NEXT_PUBLIC_CHAIN_ID ?? '0', 10);
  if (chainId === 31337) return 'Localnet';
  if (chainId === 11155111) return 'Sepolia';
  if (chainId === 1) return 'Mainnet';
  return 'Unknown';
}
