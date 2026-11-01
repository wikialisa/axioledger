/**
 * @axioledger/evm-interop — wagmi hook factories for KPX + AXQ contracts
 *
 * Re-export pattern: each hook calls the generated wagmi v2 hooks with the
 * correct ABI and function name already bound.  Callers only need to supply
 * the contract address (or pull it from a config context).
 *
 * Usage in a Next.js 'use client' component:
 *
 *   import { useAXQBalance, useProposals, useKPXAmountOut } from '@axioledger/evm-interop';
 *
 *   const { data: balance } = useAXQBalance(AXQ_TOKEN_ADDR, userAddress);
 */

'use client';

import { useReadContract, useWriteContract, useWatchContractEvent } from 'wagmi';
import type { Address, Abi } from 'viem';

import {
  AXQ_TOKEN_ABI,
  AXQ_GOVERNANCE_ABI,
  ANS_REGISTRY_ABI,
  KPX_LIQUIDITY_POOL_ABI,
  VRQ_PASSKEY_VALIDATOR_ABI,
} from './abis';

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Narrow type to satisfy wagmi's `abi` parameter. */
type AsAbi<T> = T extends Abi ? T : never;

// ── AXQToken hooks ────────────────────────────────────────────────────────────

/**
 * Read the $AXQ balance of `account`.
 * @returns bigint | undefined
 */
export function useAXQBalance(contractAddress: Address, account: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          AXQ_TOKEN_ABI as AsAbi<typeof AXQ_TOKEN_ABI>,
    functionName: 'balanceOf',
    args:         [account],
  });
}

/**
 * Read the total $AXQ supply.
 */
export function useAXQTotalSupply(contractAddress: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          AXQ_TOKEN_ABI as AsAbi<typeof AXQ_TOKEN_ABI>,
    functionName: 'totalSupply',
  });
}

/**
 * Read the allowance granted by `owner` to `spender`.
 */
export function useAXQAllowance(contractAddress: Address, owner: Address, spender: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          AXQ_TOKEN_ABI as AsAbi<typeof AXQ_TOKEN_ABI>,
    functionName: 'allowance',
    args:         [owner, spender],
  });
}

/**
 * Write: transfer $AXQ.  Returns `{ writeContract, isPending, … }`.
 */
export function useAXQTransfer(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const transfer = (to: Address, amount: bigint) =>
    writeContract({
      address:      contractAddress,
      abi:          AXQ_TOKEN_ABI as AsAbi<typeof AXQ_TOKEN_ABI>,
      functionName: 'transfer',
      args:         [to, amount],
    });
  return { transfer, ...rest };
}

/**
 * Write: approve a spender.
 */
export function useAXQApprove(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const approve = (spender: Address, amount: bigint) =>
    writeContract({
      address:      contractAddress,
      abi:          AXQ_TOKEN_ABI as AsAbi<typeof AXQ_TOKEN_ABI>,
      functionName: 'approve',
      args:         [spender, amount],
    });
  return { approve, ...rest };
}

// ── AXQGovernance hooks ───────────────────────────────────────────────────────

/**
 * Read a single proposal by ID.
 */
export function useProposal(contractAddress: Address, proposalId: bigint) {
  return useReadContract({
    address:      contractAddress,
    abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
    functionName: 'proposals',
    args:         [proposalId],
  });
}

/**
 * Read the current proposal count (useful for paginating).
 */
export function useProposalCount(contractAddress: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
    functionName: 'proposalCount',
  });
}

/**
 * Read whether `voter` has already voted on `proposalId`.
 */
export function useHasVoted(contractAddress: Address, proposalId: bigint, voter: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
    functionName: 'hasVoted',
    args:         [proposalId, voter],
  });
}

/**
 * Write: cast a quadratic-weighted vote.
 */
export function useCastVote(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const castVote = (proposalId: bigint, support: boolean) =>
    writeContract({
      address:      contractAddress,
      abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
      functionName: 'castVote',
      args:         [proposalId, support],
    });
  return { castVote, ...rest };
}

/**
 * Write: create a governance proposal.
 */
export function usePropose(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const propose = (target: Address, value: bigint, callData: `0x${string}`, description: string) =>
    writeContract({
      address:      contractAddress,
      abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
      functionName: 'propose',
      args:         [target, value, callData, description],
    });
  return { propose, ...rest };
}

/**
 * Write: queue a passed proposal for execution.
 */
export function useQueueProposal(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const queue = (proposalId: bigint) =>
    writeContract({
      address:      contractAddress,
      abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
      functionName: 'queue',
      args:         [proposalId],
    });
  return { queue, ...rest };
}

/**
 * Write: execute a time-lock-expired proposal.
 */
export function useExecuteProposal(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const execute = (proposalId: bigint, value?: bigint) =>
    writeContract({
      address:      contractAddress,
      abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
      functionName: 'execute',
      args:         [proposalId],
      value:        value ?? 0n,
    });
  return { execute, ...rest };
}

/**
 * Watch for new ProposalCreated events.
 */
export function useWatchProposalCreated(
  contractAddress: Address,
  onProposal: (id: bigint, proposer: Address, description: string) => void,
) {
  return useWatchContractEvent({
    address:      contractAddress,
    abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
    eventName:    'ProposalCreated',
    onLogs(logs) {
      for (const log of logs) {
        const { id, proposer, description } = (log as any).args;
        onProposal(id, proposer, description);
      }
    },
  });
}

/**
 * Watch for VoteCast events on a specific proposal.
 */
export function useWatchVoteCast(
  contractAddress: Address,
  proposalId: bigint,
  onVote: (voter: Address, support: boolean, weight: bigint) => void,
) {
  return useWatchContractEvent({
    address:      contractAddress,
    abi:          AXQ_GOVERNANCE_ABI as AsAbi<typeof AXQ_GOVERNANCE_ABI>,
    eventName:    'VoteCast',
    args:         { id: proposalId } as any,
    onLogs(logs) {
      for (const log of logs) {
        const { voter, support, weight } = (log as any).args;
        onVote(voter, support, weight);
      }
    },
  });
}

// ── ANSRegistry hooks ─────────────────────────────────────────────────────────

/**
 * Resolve `label.tld` → owner address.  Reverts on-chain if name is expired.
 */
export function useANSResolve(contractAddress: Address, label: string, tld: string) {
  return useReadContract({
    address:      contractAddress,
    abi:          ANS_REGISTRY_ABI as AsAbi<typeof ANS_REGISTRY_ABI>,
    functionName: 'resolve',
    args:         [label, tld],
  });
}

/**
 * Write: register a new ANS name.
 */
export function useANSRegister(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const register = (label: string, tld: string, resolver: Address, fee: bigint) =>
    writeContract({
      address:      contractAddress,
      abi:          ANS_REGISTRY_ABI as AsAbi<typeof ANS_REGISTRY_ABI>,
      functionName: 'register',
      args:         [label, tld, resolver],
      value:        fee,
    });
  return { register, ...rest };
}

// ── KPXLiquidityPool hooks ────────────────────────────────────────────────────

/**
 * Read pool reserves.
 */
export function useKPXReserves(poolAddress: Address) {
  const a = useReadContract({
    address: poolAddress,
    abi:     KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
    functionName: 'reserveA',
  });
  const b = useReadContract({
    address: poolAddress,
    abi:     KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
    functionName: 'reserveB',
  });
  return { reserveA: a, reserveB: b };
}

/**
 * Quote: calculate output amount for `amountIn` of `tokenIn`.
 */
export function useKPXAmountOut(poolAddress: Address, tokenIn: Address, amountIn: bigint) {
  return useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
    functionName: 'getAmountOut',
    args:         [amountIn, tokenIn],
    query:        { enabled: amountIn > 0n },
  });
}

/**
 * Read the spot price of TOKEN_A expressed in TOKEN_B (18-decimal fixed-point).
 */
export function useKPXSpotPrice(poolAddress: Address) {
  return useReadContract({
    address:      poolAddress,
    abi:          KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
    functionName: 'priceAInB',
  });
}

/**
 * Write: swap exact tokenIn for at least amountOutMin of the other token.
 */
export function useKPXSwapExactIn(poolAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const swap = (tokenIn: Address, amountIn: bigint, amountOutMin: bigint, to: Address) =>
    writeContract({
      address:      poolAddress,
      abi:          KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
      functionName: 'swapExactIn',
      args:         [tokenIn, amountIn, amountOutMin, to],
    });
  return { swap, ...rest };
}

/**
 * Write: add liquidity to a KPX pool.
 */
export function useKPXAddLiquidity(poolAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const addLiquidity = (
    amountADesired: bigint,
    amountBDesired: bigint,
    amountAMin: bigint,
    amountBMin: bigint,
    to: Address,
  ) =>
    writeContract({
      address:      poolAddress,
      abi:          KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
      functionName: 'addLiquidity',
      args:         [amountADesired, amountBDesired, amountAMin, amountBMin, to],
    });
  return { addLiquidity, ...rest };
}

/**
 * Watch Swap events on a KPX pool.
 */
export function useWatchKPXSwap(
  poolAddress: Address,
  onSwap: (sender: Address, tokenIn: Address, amountIn: bigint, amountOut: bigint, to: Address) => void,
) {
  return useWatchContractEvent({
    address:   poolAddress,
    abi:       KPX_LIQUIDITY_POOL_ABI as AsAbi<typeof KPX_LIQUIDITY_POOL_ABI>,
    eventName: 'Swap',
    onLogs(logs) {
      for (const log of logs) {
        const { sender, tokenIn, amountIn, amountOut, to } = (log as any).args;
        onSwap(sender, tokenIn, amountIn, amountOut, to);
      }
    },
  });
}

// ── VRQPasskeyValidator hooks ─────────────────────────────────────────────────

/**
 * Check whether a smart-account has the VRQ validator installed.
 */
export function useVRQIsInstalled(contractAddress: Address, smartAccount: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI as AsAbi<typeof VRQ_PASSKEY_VALIDATOR_ABI>,
    functionName: 'isInitialized',
    args:         [smartAccount],
  });
}

/**
 * Read the stored P256 public key (X coordinate) for a smart-account.
 */
export function useVRQPubKeyX(contractAddress: Address, smartAccount: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI as AsAbi<typeof VRQ_PASSKEY_VALIDATOR_ABI>,
    functionName: 'accountPubKeyX',
    args:         [smartAccount],
  });
}

/**
 * Read the stored P256 public key (Y coordinate) for a smart-account.
 */
export function useVRQPubKeyY(contractAddress: Address, smartAccount: Address) {
  return useReadContract({
    address:      contractAddress,
    abi:          VRQ_PASSKEY_VALIDATOR_ABI as AsAbi<typeof VRQ_PASSKEY_VALIDATOR_ABI>,
    functionName: 'accountPubKeyY',
    args:         [smartAccount],
  });
}

/**
 * Write: install the VRQ validator module on the calling smart-account.
 * `installData` = abi.encode(pubKeyX, pubKeyY, kycCommitment, zkProof)
 */
export function useVRQInstall(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const install = (installData: `0x${string}`) =>
    writeContract({
      address:      contractAddress,
      abi:          VRQ_PASSKEY_VALIDATOR_ABI as AsAbi<typeof VRQ_PASSKEY_VALIDATOR_ABI>,
      functionName: 'onInstall',
      args:         [installData],
    });
  return { install, ...rest };
}

/**
 * Write: uninstall the VRQ validator from the calling smart-account.
 */
export function useVRQUninstall(contractAddress: Address) {
  const { writeContract, ...rest } = useWriteContract();
  const uninstall = () =>
    writeContract({
      address:      contractAddress,
      abi:          VRQ_PASSKEY_VALIDATOR_ABI as AsAbi<typeof VRQ_PASSKEY_VALIDATOR_ABI>,
      functionName: 'onUninstall',
      args:         ['0x'],
    });
  return { uninstall, ...rest };
}

// ── Re-exports ────────────────────────────────────────────────────────────────

export {
  AXQ_TOKEN_ABI,
  AXQ_GOVERNANCE_ABI,
  ANS_REGISTRY_ABI,
  KPX_LIQUIDITY_POOL_ABI,
  VRQ_PASSKEY_VALIDATOR_ABI,
} from './abis';
