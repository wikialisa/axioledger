'use strict';
/**
 * @axioledger/ans-resolver — unit tests
 * All on-chain calls are mocked via jest — no real RPC required.
 */

jest.mock('viem', () => {
  const mockReadContract = jest.fn();
  const mockCreatePublicClient = jest.fn(() => ({ readContract: mockReadContract }));
  return {
    createPublicClient: mockCreatePublicClient,
    http:              jest.fn((url) => ({ url })),
    keccak256:         jest.fn((data) => `0x${'a'.repeat(64)}`),
    encodePacked:      jest.fn(() => `0x${'b'.repeat(64)}`),
    isAddress:         jest.fn((addr) => /^0x[0-9a-fA-F]{40}$/.test(addr)),
    __readContract:    mockReadContract,
  };
});

jest.mock('viem/chains', () => ({
  sepolia:  { id: 11155111, name: 'Sepolia' },
  mainnet:  { id: 1,        name: 'Ethereum' },
}));

const REGISTRY = '0x' + 'C'.repeat(40);
const { ANSResolver, SUPPORTED_TLDS, parseName, computeNameHash } = require('../index');

function getReadMock() {
  return require('viem').__readContract;
}

describe('parseName', () => {
  it('parses "alice.axq"', () => {
    const r = parseName('alice.axq');
    expect(r).toEqual({ label: 'alice', tld: 'axq' });
  });

  it('parses subdomain "bob.vpx"', () => {
    const r = parseName('bob.vpx');
    expect(r.tld).toBe('vpx');
  });

  it('throws on unsupported TLD', () => {
    expect(() => parseName('alice.eth')).toThrow('Unsupported TLD');
  });

  it('throws on no TLD', () => {
    expect(() => parseName('alice')).toThrow('Invalid ANS name');
  });
});

describe('SUPPORTED_TLDS', () => {
  it('contains all 5 pillars', () => {
    expect(SUPPORTED_TLDS).toEqual(expect.arrayContaining(['axq','vpx','sqx','kpx','vrq']));
    expect(SUPPORTED_TLDS).toHaveLength(5);
  });
});

describe('ANSResolver constructor', () => {
  it('throws without rpcUrl', () => {
    expect(() => new ANSResolver({ registryAddress: REGISTRY })).toThrow('rpcUrl');
  });

  it('throws without registryAddress', () => {
    expect(() => new ANSResolver({ rpcUrl: 'http://x' })).toThrow('registryAddress');
  });

  it('throws on invalid address', () => {
    expect(() => new ANSResolver({ rpcUrl: 'http://x', registryAddress: 'notanaddress' }))
      .toThrow('invalid registryAddress');
  });

  it('constructs successfully with valid config', () => {
    const r = new ANSResolver({ rpcUrl: 'http://localhost:8545', registryAddress: REGISTRY });
    expect(r).toBeInstanceOf(ANSResolver);
    expect(r.registryAddress).toBe(REGISTRY);
  });
});

describe('ANSResolver.resolve', () => {
  let resolver;
  beforeEach(() => {
    resolver = new ANSResolver({ rpcUrl: 'http://localhost:8545', registryAddress: REGISTRY });
    getReadMock().mockReset();
  });

  it('returns owner address for a registered name', async () => {
    const expected = '0x' + 'A'.repeat(40);
    getReadMock().mockResolvedValue(expected);

    const result = await resolver.resolve('alice', 'axq');
    expect(result).toBe(expected);
    expect(getReadMock()).toHaveBeenCalledWith(expect.objectContaining({
      functionName: 'resolve',
      args: ['alice', 'axq'],
    }));
  });

  it('resolveToAddress parses and resolves "alice.axq"', async () => {
    const expected = '0x' + 'B'.repeat(40);
    getReadMock().mockResolvedValue(expected);

    const result = await resolver.resolveToAddress('alice.axq');
    expect(result).toBe(expected);
  });
});

describe('ANSResolver.getRecord', () => {
  let resolver;
  beforeEach(() => {
    resolver = new ANSResolver({ rpcUrl: 'http://localhost:8545', registryAddress: REGISTRY });
    getReadMock().mockReset();
  });

  it('returns structured record', async () => {
    const owner    = '0x' + 'D'.repeat(40);
    const resolver_= '0x' + '0'.repeat(40);
    const expiry   = BigInt(Math.floor(Date.now() / 1000) + 86400);
    getReadMock().mockResolvedValue([owner, resolver_, expiry, false]);

    const rec = await resolver.getRecord('alice.axq');
    expect(rec.owner).toBe(owner);
    expect(rec.expiry).toBe(expiry);
    expect(rec.locked).toBe(false);
  });
});

describe('ANSResolver.isRegistered', () => {
  let resolver;
  beforeEach(() => {
    resolver = new ANSResolver({ rpcUrl: 'http://localhost:8545', registryAddress: REGISTRY });
    getReadMock().mockReset();
  });

  it('returns true for active name', async () => {
    const owner  = '0x' + 'E'.repeat(40);
    const expiry = BigInt(Math.floor(Date.now() / 1000) + 86400);
    getReadMock().mockResolvedValue([owner, '0x' + '0'.repeat(40), expiry, false]);

    expect(await resolver.isRegistered('alice.axq')).toBe(true);
  });

  it('returns false for expired name', async () => {
    const owner  = '0x' + 'F'.repeat(40);
    const expiry = BigInt(Math.floor(Date.now() / 1000) - 100); // expired
    getReadMock().mockResolvedValue([owner, '0x' + '0'.repeat(40), expiry, false]);

    expect(await resolver.isRegistered('alice.axq')).toBe(false);
  });

  it('returns false when readContract throws', async () => {
    getReadMock().mockRejectedValue(new Error('not registered'));
    expect(await resolver.isRegistered('unknown.axq')).toBe(false);
  });
});
