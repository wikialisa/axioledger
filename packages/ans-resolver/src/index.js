'use strict';
/**
 * @axioledger/ans-resolver — AXIOLEDGER Name Service (ANS) TypeScript client
 *
 * Resolves .axq / .vpx / .sqx / .kpx / .vrq names to addresses on-chain.
 * Reads from the deployed ANSRegistry smart contract via viem.
 *
 * @example
 * import { ANSResolver } from '@axioledger/ans-resolver';
 *
 * const resolver = new ANSResolver({
 *   rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY',
 *   registryAddress: '0x...',
 * });
 *
 * const owner = await resolver.resolve('alice', 'axq');
 * const addr  = await resolver.resolveToAddress('alice.axq');
 */

const { createPublicClient, http, keccak256, encodePacked, isAddress } = require('viem');
const { sepolia, mainnet } = require('viem/chains');

// ── ABI (minimal — only functions we call) ────────────────────────────────────
const ANS_REGISTRY_ABI = [
  {
    name: 'resolve',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'label', type: 'string' },
      { name: 'tld',   type: 'string' },
    ],
    outputs: [{ name: '', type: 'address' }],
  },
  {
    name: 'getResolver',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'label', type: 'string' },
      { name: 'tld',   type: 'string' },
    ],
    outputs: [{ name: '', type: 'address' }],
  },
  {
    name: 'records',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'nameHash', type: 'bytes32' }],
    outputs: [
      { name: 'owner',    type: 'address' },
      { name: 'resolver', type: 'address' },
      { name: 'expiry',   type: 'uint64'  },
      { name: 'locked',   type: 'bool'    },
    ],
  },
  {
    name: 'tldFees',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'tldHash', type: 'bytes32' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'supportedTlds',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'tldHash', type: 'bytes32' }],
    outputs: [{ name: '', type: 'bool' }],
  },
];

// ── Supported TLDs ────────────────────────────────────────────────────────────

const SUPPORTED_TLDS = ['axq', 'vpx', 'sqx', 'kpx', 'vrq'];

const CHAIN_MAP = {
  mainnet: { chain: mainnet, id: 1 },
  sepolia: { chain: sepolia, id: 11155111 },
};

// ── Helper: compute nameHash matching ANSRegistry._nameHash() ─────────────────
function computeNameHash(label, tld) {
  const labelHash = keccak256(new TextEncoder().encode(label));
  const tldHash   = keccak256(new TextEncoder().encode(tld));
  return keccak256(encodePacked(['bytes32', 'bytes32'], [labelHash, tldHash]));
}

// ── Parse "alice.axq" → { label: "alice", tld: "axq" } ───────────────────────
function parseName(name) {
  const parts = name.trim().toLowerCase().split('.');
  if (parts.length < 2) throw new Error(`Invalid ANS name: "${name}" — expected "label.tld"`);
  const tld   = parts[parts.length - 1];
  const label = parts.slice(0, -1).join('.');
  if (!SUPPORTED_TLDS.includes(tld)) {
    throw new Error(`Unsupported TLD ".${tld}" — supported: ${SUPPORTED_TLDS.map(t => `.${t}`).join(', ')}`);
  }
  return { label, tld };
}

// ── ANSResolver class ─────────────────────────────────────────────────────────

class ANSResolver {
  /**
   * @param {object} config
   * @param {string} config.rpcUrl            — EVM JSON-RPC endpoint
   * @param {string} config.registryAddress   — Deployed ANSRegistry contract address
   * @param {'mainnet'|'sepolia'} [config.network='sepolia']
   */
  constructor(config) {
    if (!config.rpcUrl)          throw new Error('ANSResolver: rpcUrl is required');
    if (!config.registryAddress) throw new Error('ANSResolver: registryAddress is required');
    if (!isAddress(config.registryAddress)) {
      throw new Error(`ANSResolver: invalid registryAddress "${config.registryAddress}"`);
    }

    const network    = config.network || 'sepolia';
    const chainInfo  = CHAIN_MAP[network];
    if (!chainInfo) throw new Error(`ANSResolver: unknown network "${network}"`);

    this.registryAddress = config.registryAddress;
    this.client = createPublicClient({
      chain:     chainInfo.chain,
      transport: http(config.rpcUrl),
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /**
   * Resolve "alice.axq" → owner address.
   * Throws if name is expired or not registered.
   * @param {string} name  e.g. "alice.axq"
   * @returns {Promise<string>} checksummed Ethereum address
   */
  async resolveToAddress(name) {
    const { label, tld } = parseName(name);
    return this.resolve(label, tld);
  }

  /**
   * Resolve label + tld separately → owner address.
   * @param {string} label  e.g. "alice"
   * @param {string} tld    e.g. "axq"
   * @returns {Promise<string>} checksummed Ethereum address
   */
  async resolve(label, tld) {
    const address = await this.client.readContract({
      address:      this.registryAddress,
      abi:          ANS_REGISTRY_ABI,
      functionName: 'resolve',
      args:         [label.toLowerCase(), tld.toLowerCase()],
    });
    return address;
  }

  /**
   * Get resolver contract address for extended records.
   * @param {string} name  e.g. "alice.axq"
   * @returns {Promise<string>} resolver contract address (may be zero address)
   */
  async getResolver(name) {
    const { label, tld } = parseName(name);
    return this.client.readContract({
      address:      this.registryAddress,
      abi:          ANS_REGISTRY_ABI,
      functionName: 'getResolver',
      args:         [label.toLowerCase(), tld.toLowerCase()],
    });
  }

  /**
   * Fetch full record details (owner, resolver, expiry, locked).
   * @param {string} name  e.g. "alice.axq"
   * @returns {Promise<{owner: string, resolver: string, expiry: bigint, locked: boolean}>}
   */
  async getRecord(name) {
    const { label, tld } = parseName(name);
    const nameHash = computeNameHash(label.toLowerCase(), tld.toLowerCase());

    const [owner, resolver, expiry, locked] = await this.client.readContract({
      address:      this.registryAddress,
      abi:          ANS_REGISTRY_ABI,
      functionName: 'records',
      args:         [nameHash],
    });

    return { owner, resolver, expiry, locked };
  }

  /**
   * Check whether a name is registered and not expired.
   * @param {string} name  e.g. "alice.axq"
   * @returns {Promise<boolean>}
   */
  async isRegistered(name) {
    try {
      const record = await this.getRecord(name);
      const now    = BigInt(Math.floor(Date.now() / 1000));
      return record.owner !== '0x0000000000000000000000000000000000000000'
          && record.expiry > now;
    } catch {
      return false;
    }
  }

  /**
   * Get registration fee for a TLD (in wei).
   * @param {string} tld  e.g. "axq"
   * @returns {Promise<bigint>}
   */
  async getRegistrationFee(tld) {
    const tldHash = keccak256(new TextEncoder().encode(tld.toLowerCase()));
    return this.client.readContract({
      address:      this.registryAddress,
      abi:          ANS_REGISTRY_ABI,
      functionName: 'tldFees',
      args:         [tldHash],
    });
  }

  /**
   * Check whether a TLD is supported by the registry.
   * @param {string} tld  e.g. "axq"
   * @returns {Promise<boolean>}
   */
  async isTldSupported(tld) {
    const tldHash = keccak256(new TextEncoder().encode(tld.toLowerCase()));
    return this.client.readContract({
      address:      this.registryAddress,
      abi:          ANS_REGISTRY_ABI,
      functionName: 'supportedTlds',
      args:         [tldHash],
    });
  }
}

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = { ANSResolver, SUPPORTED_TLDS, computeNameHash, parseName };
