/**
 * global-setup.ts — Playwright global setup
 *
 * Runs ONCE before all tests. Verifies:
 *   1. Anvil is reachable at RPC_URL
 *   2. All required contracts are deployed
 *   3. TEST_USER has AXQ balance (seeded by localnet-setup.sh)
 *
 * Fails fast with a clear error if localnet is not running.
 */

import { createPublicClient, http } from 'viem';
import { foundry } from 'viem/chains';

const RPC_URL       = process.env.E2E_RPC_URL       ?? 'http://127.0.0.1:8545';
const AXQ_TOKEN     = (process.env.E2E_AXQ_TOKEN    ?? '0x5FbDB2315678afecb367f032d93F642f64180aa3') as `0x${string}`;
const TEST_USER     = '0x976EA74026E726554dB657fA54763abd0C3a0aa9' as `0x${string}`;

const client = createPublicClient({
  chain: { ...foundry, id: 31337, rpcUrls: { default: { http: [RPC_URL] } } } as typeof foundry,
  transport: http(RPC_URL),
});

export default async function globalSetup() {
  console.log('\n[Playwright] Global setup — verifying localnet…');

  // 1. Anvil reachable?
  try {
    const block = await client.getBlockNumber();
    console.log(`[Playwright] ✓ Anvil reachable — block ${block}`);
  } catch {
    throw new Error(
      `[Playwright] ✗ Anvil not reachable at ${RPC_URL}\n` +
      `  → Run: bash scripts/localnet-setup.sh`
    );
  }

  // 2. AXQToken deployed?
  try {
    const code = await client.getBytecode({ address: AXQ_TOKEN });
    if (!code || code === '0x') {
      throw new Error('no bytecode');
    }
    console.log(`[Playwright] ✓ AXQToken deployed at ${AXQ_TOKEN}`);
  } catch {
    throw new Error(
      `[Playwright] ✗ AXQToken not deployed at ${AXQ_TOKEN}\n` +
      `  → Run: bash scripts/localnet-setup.sh`
    );
  }

  // 3. TEST_USER has AXQ balance?
  const balance = await client.readContract({
    address: AXQ_TOKEN,
    abi: [{ name: 'balanceOf', type: 'function', stateMutability: 'view',
            inputs: [{ type: 'address' }], outputs: [{ type: 'uint256' }] }],
    functionName: 'balanceOf',
    args: [TEST_USER],
  }) as bigint;

  if (balance === 0n) {
    throw new Error(
      `[Playwright] ✗ TEST_USER has 0 AXQ — localnet seed incomplete\n` +
      `  → Run: bash scripts/localnet-setup.sh`
    );
  }
  console.log(`[Playwright] ✓ TEST_USER balance: ${Number(balance) / 1e18} AXQ`);
  console.log('[Playwright] ✓ Localnet ready — starting browser tests\n');
}
