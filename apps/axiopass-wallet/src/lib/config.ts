/**
 * Wagmi config + contract addresses for Axiopass Wallet.
 */

import { http, createConfig } from 'wagmi';
import { sepolia, mainnet } from 'wagmi/chains';
import { injected } from 'wagmi/connectors';

export const wagmiConfig = createConfig({
  chains:     [sepolia, mainnet],
  connectors: [injected()],
  transports: {
    [sepolia.id]: http(),
    [mainnet.id]: http(),
  },
});

/** Deployed VRQPasskeyValidator address (Sepolia). */
export const CONTRACT_ADDRESSES = {
  vrqValidator: (process.env.NEXT_PUBLIC_VRQ_VALIDATOR ?? '') as `0x${string}`,
  axqToken:     (process.env.NEXT_PUBLIC_AXQ_TOKEN     ?? '') as `0x${string}`,
} as const;

/**
 * Daimo P256Verifier — deterministic CREATE2 address used by VRQPasskeyValidator.
 * https://github.com/daimo-eth/p256-verifier
 */
export const P256_VERIFIER_ADDRESS = '0xc2b78104907F722DABAc4C69f826a522B2754De4' as const;
