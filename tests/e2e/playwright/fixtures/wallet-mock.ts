/**
 * fixtures/wallet-mock.ts
 *
 * Playwright fixture that injects a deterministic EIP-1193 window.ethereum
 * mock + WebAuthn stub into every page before any app script runs.
 *
 * WHY NOT SYNPRESS / METAMASK EXTENSION?
 * ───────────────────────────────────────
 * AXIOLEDGER uses wagmi `injected()` connector — it reads window.ethereum
 * directly. We don't need MetaMask's popup UI; we need a provider that:
 *   a) returns our Anvil test account address on eth_requestAccounts
 *   b) signs transactions by forwarding to Anvil (no popup, no confirmation)
 *   c) handles eth_chainId, eth_getBalance, wallet_switchEthereumChain
 *
 * WHY NOT SYNPRESS FOR WEBAUTHN?
 * ───────────────────────────────
 * Synpress cannot mock navigator.credentials — it drives a real MetaMask
 * extension. Our PasskeyButton calls navigator.credentials.create() which
 * is a browser API. We mock it at the page context level so it returns
 * a deterministic P256 key pair without hardware authenticator.
 *
 * ARCHITECTURE:
 *   page.addInitScript({ content: MOCK_SCRIPT }) → injected before app boots
 *   fixture.goto(url) → page has mocked APIs from frame 0
 *
 * TEST ACCOUNTS (Anvil default mnemonic):
 *   Account 0 (deployer): 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 *   Account 6 (testUser):  0x976EA74026E726554dB657fA54763abd0C3a0aa9
 */

import { test as base, type Page } from '@playwright/test';
import { createWalletClient, createPublicClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { foundry } from 'viem/chains';

// ── Anvil test accounts ───────────────────────────────────────────────────────

export const DEPLOYER_KEY  = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' as `0x${string}`;
export const TEST_USER_KEY = '0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e' as `0x${string}`;

export const deployerAccount  = privateKeyToAccount(DEPLOYER_KEY);
export const testUserAccount  = privateKeyToAccount(TEST_USER_KEY);

export const RPC_URL       = process.env.E2E_RPC_URL       ?? 'http://127.0.0.1:8545';
export const CHAIN_ID      = 31337;

export const CONTRACTS = {
  axqToken:     (process.env.E2E_AXQ_TOKEN     ?? '0x5FbDB2315678afecb367f032d93F642f64180aa3') as `0x${string}`,
  ansRegistry:  (process.env.E2E_ANS_REGISTRY  ?? '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512') as `0x${string}`,
  axqGovernance:(process.env.E2E_AXQ_GOVERNANCE ?? '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9') as `0x${string}`,
  vrqValidator: (process.env.E2E_VRQ_VALIDATOR ?? '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0') as `0x${string}`,
};

const localnetChain = {
  ...foundry,
  id: CHAIN_ID,
  rpcUrls: { default: { http: [RPC_URL] } },
} as typeof foundry;

// Viem clients used by tests to read/verify on-chain state
export const publicClient = createPublicClient({ chain: localnetChain, transport: http(RPC_URL) });
export const deployerClient = createWalletClient({ account: deployerAccount, chain: localnetChain, transport: http(RPC_URL) });
export const testUserClient  = createWalletClient({ account: testUserAccount, chain: localnetChain, transport: http(RPC_URL) });

// ── window.ethereum mock script (injected into browser page) ─────────────────
//
// This script runs inside the browser context. It:
//   1. Exposes a minimal EIP-1193 provider on window.ethereum
//   2. Forwards JSON-RPC calls to Anvil via fetch (same-origin bypass via proxy)
//   3. Provides eth_requestAccounts without a popup
//   4. Mocks navigator.credentials for WebAuthn (PasskeyButton)
//
// The ACCOUNT_ADDRESS and RPC_URL_PLACEHOLDER are replaced before injection.

function buildMockScript(accountAddress: string, rpcUrl: string, chainId: number): string {
  return `
(function() {
  'use strict';

  // ── EIP-1193 window.ethereum mock ────────────────────────────────────────
  const ACCOUNT   = '${accountAddress}';
  const RPC       = '${rpcUrl}';
  const CHAIN_ID  = ${chainId};
  let   isConnected = false;

  async function rpcCall(method, params = []) {
    const resp = await fetch(RPC, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ jsonrpc: '2.0', id: Date.now(), method, params }),
    });
    const json = await resp.json();
    if (json.error) throw Object.assign(new Error(json.error.message), { code: json.error.code });
    return json.result;
  }

  const ethereum = {
    isMetaMask:        true,
    selectedAddress:   ACCOUNT,
    chainId:           '0x' + CHAIN_ID.toString(16),
    networkVersion:    String(CHAIN_ID),
    _listeners:        {},

    // EIP-1193 request method — the core of the mock
    async request({ method, params = [] }) {
      switch (method) {

        // Wallet connection — return immediately, no popup
        case 'eth_requestAccounts':
        case 'eth_accounts':
          isConnected = true;
          return [ACCOUNT];

        // Chain info
        case 'eth_chainId':
          return '0x' + CHAIN_ID.toString(16);
        case 'net_version':
          return String(CHAIN_ID);

        // Switch chain — accept any switch to our local chain
        case 'wallet_switchEthereumChain':
          if (params[0]?.chainId === '0x' + CHAIN_ID.toString(16)) return null;
          throw Object.assign(new Error('Chain not added'), { code: 4902 });

        // Add chain — accept our local chain
        case 'wallet_addEthereumChain':
          return null;

        // Sign typed data — forward to Anvil
        case 'eth_signTypedData_v4':
          return rpcCall('eth_signTypedData_v4', params);

        // Personal sign — forward to Anvil
        case 'personal_sign':
          return rpcCall('personal_sign', params);

        // All other methods — forward directly to Anvil
        default:
          return rpcCall(method, params);
      }
    },

    // Event emitter (minimal)
    on(event, handler) {
      if (!this._listeners[event]) this._listeners[event] = [];
      this._listeners[event].push(handler);
      // Immediately emit 'connect' so wagmi picks up the provider
      if (event === 'connect') {
        setTimeout(() => handler({ chainId: '0x' + CHAIN_ID.toString(16) }), 0);
      }
      if (event === 'accountsChanged' && isConnected) {
        setTimeout(() => handler([ACCOUNT]), 0);
      }
    },
    removeListener(event, handler) {
      if (this._listeners[event]) {
        this._listeners[event] = this._listeners[event].filter(h => h !== handler);
      }
    },
    emit(event, data) {
      (this._listeners[event] || []).forEach(h => h(data));
    },
  };

  // Freeze to prevent app code from overwriting
  Object.defineProperty(window, 'ethereum', {
    value: ethereum,
    writable: false,
    configurable: false,
  });

  // wagmi also looks for window.ethereum.providers array
  window.ethereum.providers = [ethereum];

  // ── WebAuthn / Passkey mock ───────────────────────────────────────────────
  // Returns a deterministic P256 key pair without requiring hardware.
  // pubKeyX = 0xAXIO..., pubKeyY = 0x...LEDGER (test vectors)

  const MOCK_CREDENTIAL_ID = 'axioledger-localnet-test-cred-01';

  // Minimal SPKI-encoded P-256 public key for testing
  // This is the SubjectPublicKeyInfo encoding of a known test key
  const MOCK_SPKI_HEX = '3059301306072a8648ce3d020106082a8648ce3d030107034200' +
    '04' + // uncompressed point prefix
    'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef' + // x coord
    'cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe';  // y coord

  function hexToBytes(hex) {
    const arr = new Uint8Array(hex.length / 2);
    for (let i = 0; i < arr.length; i++) arr[i] = parseInt(hex.slice(i*2, i*2+2), 16);
    return arr;
  }

  const MOCK_AUTH_DATA = new Uint8Array(37);
  MOCK_AUTH_DATA[32] = 0x05; // UP | UV flags set

  const MOCK_CLIENT_DATA = JSON.stringify({
    type: 'webauthn.create',
    challenge: btoa('localnet-test-challenge'),
    origin: window.location.origin,
  });

  const MOCK_AUTH_ASSERT_DATA = new Uint8Array(37);
  MOCK_AUTH_ASSERT_DATA[32] = 0x05;

  // Override navigator.credentials
  const originalCredentials = navigator.credentials;
  Object.defineProperty(navigator, 'credentials', {
    value: {
      // Registration (create)
      create: async (options) => {
        const challenge = options?.publicKey?.challenge ?? new Uint8Array(32);
        // Return a fake PublicKeyCredential
        return {
          id:    MOCK_CREDENTIAL_ID,
          type:  'public-key',
          rawId: new TextEncoder().encode(MOCK_CREDENTIAL_ID),
          response: {
            // Minimal attestation response
            attestationObject: new Uint8Array(100),
            clientDataJSON:    new TextEncoder().encode(MOCK_CLIENT_DATA),
            // getPublicKey() returns our fake SPKI key
            getPublicKey: () => hexToBytes(MOCK_SPKI_HEX).buffer,
            getPublicKeyAlgorithm: () => -7, // ES256
            getAuthenticatorData: () => MOCK_AUTH_DATA.buffer,
          },
        };
      },

      // Authentication (get / sign)
      get: async (options) => {
        const challenge = options?.publicKey?.challenge ?? new Uint8Array(32);
        const clientDataJSON = JSON.stringify({
          type: 'webauthn.get',
          challenge: btoa(String.fromCharCode(...new Uint8Array(
            challenge instanceof ArrayBuffer ? challenge : challenge.buffer || new Uint8Array(32)
          ))),
          origin: window.location.origin,
        });

        // DER-encoded mock signature (r=1, s=1 — stub verifier accepts anything)
        const derSig = new Uint8Array([
          0x30, 0x06,
          0x02, 0x01, 0x01,  // r = 1
          0x02, 0x01, 0x01,  // s = 1
        ]);

        return {
          id:    MOCK_CREDENTIAL_ID,
          type:  'public-key',
          rawId: new TextEncoder().encode(MOCK_CREDENTIAL_ID),
          response: {
            authenticatorData: MOCK_AUTH_ASSERT_DATA.buffer,
            clientDataJSON:    new TextEncoder().encode(clientDataJSON),
            signature:         derSig.buffer,
            userHandle:        null,
          },
        };
      },

      store:  originalCredentials?.store?.bind(originalCredentials),
      preventSilentAccess: originalCredentials?.preventSilentAccess?.bind(originalCredentials),
    },
    writable: false,
    configurable: false,
  });

  console.log('[axio-mock] window.ethereum + navigator.credentials mocked for localnet testing');
})();
`;
}

// ── Playwright fixture ────────────────────────────────────────────────────────

export type WalletMockFixtures = {
  /** Page with wallet mock injected — use this instead of raw `page` */
  walletPage: Page;
  /** Page connected as TEST_USER (account index 6) */
  testUserPage: Page;
  /** Page connected as DEPLOYER (account index 0) */
  deployerPage: Page;
};

export const test = base.extend<WalletMockFixtures>({
  // Generic mocked page — no specific account pre-selected
  walletPage: async ({ page }, use) => {
    await page.addInitScript({
      content: buildMockScript(testUserAccount.address, RPC_URL, CHAIN_ID),
    });
    await use(page);
  },

  testUserPage: async ({ page }, use) => {
    await page.addInitScript({
      content: buildMockScript(testUserAccount.address, RPC_URL, CHAIN_ID),
    });
    await use(page);
  },

  deployerPage: async ({ page }, use) => {
    await page.addInitScript({
      content: buildMockScript(deployerAccount.address, RPC_URL, CHAIN_ID),
    });
    await use(page);
  },
});

export { expect } from '@playwright/test';
