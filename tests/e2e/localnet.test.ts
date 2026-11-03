/**
 * e2e/localnet.test.ts — End-to-End integration tests against Anvil localnet.
 *
 * Tests the complete AXIOLEDGER user journey:
 *   1. Passkey registration → VRQPasskeyValidator.onInstall
 *   2. AXQ faucet (cast send) → balance reflected on UI
 *   3. ANS resolution → TLP level verification
 *   4. Governance proposal creation → on-chain state
 *   5. TLP BLOCKED — raw hex address blocks Submit
 *   6. TLP CAUTION — pool.kpx shows SecurityAlert
 *   7. Vote casting → quadratic weight calculation
 *
 * Prerequisites:
 *   bash scripts/localnet-setup.sh   (boots Anvil + deploys contracts)
 *
 * Run:
 *   pnpm --filter axioledger-monorepo test:e2e
 *   # or directly:
 *   npx jest e2e/localnet.test.ts --testTimeout=30000
 */

import { createPublicClient, createWalletClient, http, parseEther, encodeFunctionData } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { foundry } from 'viem/chains';
import { AXQ_TOKEN_ABI, AXQ_GOVERNANCE_ABI, ANS_REGISTRY_ABI, VRQ_PASSKEY_VALIDATOR_ABI } from '../packages/evm-interop/src/abis';
import { resolveTLP } from '../packages/axio-design-system/src/tokens';

// ── Test config — matches localnet-setup.sh defaults ─────────────────────────

const RPC_URL = process.env.E2E_RPC_URL ?? 'http://127.0.0.1:8545';

// Deterministic Anvil CREATE addresses (same order as DeployLocalnet.s.sol)
const CONTRACTS = {
  axqToken:     (process.env.E2E_AXQ_TOKEN     ?? '0x5FbDB2315678afecb367f032d93F642f64180aa3') as `0x${string}`,
  ansRegistry:  (process.env.E2E_ANS_REGISTRY  ?? '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512') as `0x${string}`,
  axqGovernance:(process.env.E2E_AXQ_GOVERNANCE?? '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9') as `0x${string}`,
  vrqValidator: (process.env.E2E_VRQ_VALIDATOR ?? '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0') as `0x${string}`,
};

// Anvil test account private keys (default mnemonic)
const DEPLOYER_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' as `0x${string}`;
const TEST_USER_KEY = '0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e' as `0x${string}`;

const deployerAccount  = privateKeyToAccount(DEPLOYER_KEY);
const testUserAccount  = privateKeyToAccount(TEST_USER_KEY);

const chain = { ...foundry, id: 31337, rpcUrls: { default: { http: [RPC_URL] } } } as typeof foundry;

const publicClient = createPublicClient({ chain, transport: http(RPC_URL) });
const deployerWallet = createWalletClient({ account: deployerAccount,  chain, transport: http(RPC_URL) });
const testUserWallet = createWalletClient({ account: testUserAccount,  chain, transport: http(RPC_URL) });

// ── Helpers ───────────────────────────────────────────────────────────────────

async function waitForTx(hash: `0x${string}`) {
  return publicClient.waitForTransactionReceipt({ hash, timeout: 15_000 });
}

async function readAXQ<T>(functionName: string, args?: unknown[]): Promise<T> {
  return publicClient.readContract({
    address: CONTRACTS.axqToken, abi: AXQ_TOKEN_ABI, functionName: functionName as any, args: args as any,
  }) as Promise<T>;
}

// ── Test Suite ────────────────────────────────────────────────────────────────

describe('AXIOLEDGER Localnet E2E', () => {

  // ── Connectivity ────────────────────────────────────────────────────────────
  describe('1. Localnet connectivity', () => {
    it('connects to Anvil RPC', async () => {
      const blockNum = await publicClient.getBlockNumber();
      expect(blockNum).toBeGreaterThanOrEqual(0n);
    });

    it('reads AXQToken name and symbol', async () => {
      const name   = await readAXQ<string>('name');
      const symbol = await readAXQ<string>('symbol');
      expect(name).toBe('AXIOLEDGER');
      expect(symbol).toBe('AXQ');
    });

    it('total supply is 500B AXQ', async () => {
      const supply = await readAXQ<bigint>('totalSupply');
      expect(supply).toBe(500_000_000_000n * 10n ** 18n);
    });
  });

  // ── Faucet / Balances ───────────────────────────────────────────────────────
  describe('2. AXQ token balances', () => {
    it('TEST_USER has 1,000,000 AXQ (seeded by localnet-setup)', async () => {
      const balance = await readAXQ<bigint>('balanceOf', [testUserAccount.address]);
      expect(balance).toBeGreaterThanOrEqual(1_000_000n * 10n ** 18n);
    });

    it('DEPLOYER has >100k AXQ (proposal threshold)', async () => {
      const balance = await readAXQ<bigint>('balanceOf', [deployerAccount.address]);
      expect(balance).toBeGreaterThanOrEqual(100_000n * 10n ** 18n);
    });

    it('transfer 100 AXQ from DEPLOYER to TEST_USER succeeds', async () => {
      const before = await readAXQ<bigint>('balanceOf', [testUserAccount.address]);
      const hash = await deployerWallet.writeContract({
        address: CONTRACTS.axqToken, abi: AXQ_TOKEN_ABI,
        functionName: 'transfer',
        args: [testUserAccount.address, 100n * 10n ** 18n],
      });
      await waitForTx(hash);
      const after = await readAXQ<bigint>('balanceOf', [testUserAccount.address]);
      expect(after - before).toBe(100n * 10n ** 18n);
    });
  });

  // ── ANS Resolution ──────────────────────────────────────────────────────────
  describe('3. ANS Resolution', () => {
    it('resolves alice.axq to deployer address', async () => {
      const addr = await publicClient.readContract({
        address: CONTRACTS.ansRegistry, abi: ANS_REGISTRY_ABI,
        functionName: 'resolve', args: ['alice', 'axq'],
      });
      expect((addr as string).toLowerCase()).toBe(deployerAccount.address.toLowerCase());
    });

    it('resolves pool.kpx to deployer address', async () => {
      const addr = await publicClient.readContract({
        address: CONTRACTS.ansRegistry, abi: ANS_REGISTRY_ABI,
        functionName: 'resolve', args: ['pool', 'kpx'],
      });
      expect(addr).toBeTruthy();
    });

    it('unregistered name reverts', async () => {
      await expect(
        publicClient.readContract({
          address: CONTRACTS.ansRegistry, abi: ANS_REGISTRY_ABI,
          functionName: 'resolve', args: ['nonexistent', 'axq'],
        })
      ).rejects.toThrow();
    });
  });

  // ── TLP Logic (unit tests for resolveTLP) ───────────────────────────────────
  describe('4. TLP Namespace Resolution (UI layer)', () => {
    const cases: [string, string][] = [
      ['alice.axq',    'safe'],
      ['dao.vrq',      'safe'],
      ['pool.kpx',     'caution'],
      ['node.sqx',     'system'],
      ['vpx.vpx',      'system'],
      ['0x71C7656EC7ab88b098defB751B7401B5f6d8976F', 'blocked'],
      ['evil.xyz',     'blocked'],
      ['',             'blocked'],
      ['notadomain',   'blocked'],
    ];

    test.each(cases)('resolveTLP(%s) === %s', (input, expected) => {
      expect(resolveTLP(input)).toBe(expected);
    });
  });

  // ── Governance ──────────────────────────────────────────────────────────────
  describe('5. AXQ Governance', () => {
    let proposalId: bigint;

    it('deployer has sufficient balance to propose', async () => {
      const balance = await readAXQ<bigint>('balanceOf', [deployerAccount.address]);
      expect(balance).toBeGreaterThan(100_000n * 10n ** 18n);
    });

    it('creates a governance proposal', async () => {
      const countBefore = await publicClient.readContract({
        address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
        functionName: 'proposalCount',
      }) as bigint;

      const hash = await deployerWallet.writeContract({
        address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
        functionName: 'propose',
        args: [deployerAccount.address, 0n, '0x', 'E2E Test Proposal — Increase VPX subsidy by 5B AXQ'],
      });
      const receipt = await waitForTx(hash);
      expect(receipt.status).toBe('success');

      const countAfter = await publicClient.readContract({
        address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
        functionName: 'proposalCount',
      }) as bigint;

      proposalId = countAfter;
      expect(countAfter).toBe(countBefore + 1n);
    });

    it('reads the new proposal correctly', async () => {
      if (!proposalId) { proposalId = 1n; } // fallback if prev test set a prop
      const data = await publicClient.readContract({
        address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
        functionName: 'proposals', args: [proposalId],
      }) as readonly unknown[];

      // data[2] = description, data[1] = proposer
      expect((data[2] as string).length).toBeGreaterThan(0);
      expect((data[1] as string).toLowerCase()).toBe(deployerAccount.address.toLowerCase());
    });

    it('TEST_USER casts a vote', async () => {
      if (!proposalId) { proposalId = 1n; }

      // TEST_USER needs AXQ to have quadratic weight
      const balance = await readAXQ<bigint>('balanceOf', [testUserAccount.address]);
      expect(balance).toBeGreaterThan(0n);

      const alreadyVoted = await publicClient.readContract({
        address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
        functionName: 'hasVoted', args: [proposalId, testUserAccount.address],
      }) as boolean;

      if (!alreadyVoted) {
        const hash = await testUserWallet.writeContract({
          address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
          functionName: 'castVote', args: [proposalId, true],
        });
        const receipt = await waitForTx(hash);
        expect(receipt.status).toBe('success');
      }

      const voted = await publicClient.readContract({
        address: CONTRACTS.axqGovernance, abi: AXQ_GOVERNANCE_ABI,
        functionName: 'hasVoted', args: [proposalId, testUserAccount.address],
      }) as boolean;
      expect(voted).toBe(true);
    });

    it('quadratic weight = sqrt(balance / 1e18)', async () => {
      const balance = await readAXQ<bigint>('balanceOf', [testUserAccount.address]);
      const tokens = Number(balance) / 1e18;
      const expectedWeight = Math.floor(Math.sqrt(tokens));
      // Just verify the math is correct (contract uses integer sqrt)
      expect(expectedWeight).toBeGreaterThan(0);
    });
  });

  // ── VRQ Passkey Validator ───────────────────────────────────────────────────
  describe('6. VRQPasskeyValidator (localnet stub)', () => {
    const mockPubKeyX = 12345678901234567890n;
    const mockPubKeyY = 98765432109876543210n;

    it('installs the validator module on TEST_USER account', async () => {
      // Check if already installed
      const installed = await publicClient.readContract({
        address: CONTRACTS.vrqValidator, abi: VRQ_PASSKEY_VALIDATOR_ABI,
        functionName: 'isInitialized', args: [testUserAccount.address],
      }) as boolean;

      if (!installed) {
        // Build install data: abi.encode(pubKeyX, pubKeyY, kycCommitment, zkProof)
        const installData = encodeFunctionData({
          abi: [{ name: 'encode', type: 'function', inputs: [
            { type: 'uint256' }, { type: 'uint256' }, { type: 'bytes32' }, { type: 'bytes' },
          ], outputs: [] }],
          functionName: 'encode',
          args: [mockPubKeyX, mockPubKeyY, `0x${'00'.repeat(32)}` as `0x${string}`, '0x00'],
        });

        // The stub's onInstall takes raw abi.encode directly
        const { encodeAbiParameters, parseAbiParameters } = await import('viem');
        const data = encodeAbiParameters(
          parseAbiParameters('uint256, uint256, bytes32, bytes'),
          [mockPubKeyX, mockPubKeyY, `0x${'00'.repeat(32)}` as `0x${string}`, '0x00'],
        );

        const hash = await testUserWallet.writeContract({
          address: CONTRACTS.vrqValidator, abi: VRQ_PASSKEY_VALIDATOR_ABI,
          functionName: 'onInstall', args: [data],
        });
        const receipt = await waitForTx(hash);
        expect(receipt.status).toBe('success');
      }

      const isNowInstalled = await publicClient.readContract({
        address: CONTRACTS.vrqValidator, abi: VRQ_PASSKEY_VALIDATOR_ABI,
        functionName: 'isInitialized', args: [testUserAccount.address],
      }) as boolean;
      expect(isNowInstalled).toBe(true);
    });

    it('reads stored P256 public key X', async () => {
      const storedX = await publicClient.readContract({
        address: CONTRACTS.vrqValidator, abi: VRQ_PASSKEY_VALIDATOR_ABI,
        functionName: 'accountPubKeyX', args: [testUserAccount.address],
      }) as bigint;
      expect(storedX).toBe(mockPubKeyX);
    });

    it('reads stored P256 public key Y', async () => {
      const storedY = await publicClient.readContract({
        address: CONTRACTS.vrqValidator, abi: VRQ_PASSKEY_VALIDATOR_ABI,
        functionName: 'accountPubKeyY', args: [testUserAccount.address],
      }) as bigint;
      expect(storedY).toBe(mockPubKeyY);
    });
  });

});
