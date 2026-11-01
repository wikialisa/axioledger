/**
 * @axioledger/evm-interop — ABI catalogue
 *
 * One canonical place for every contract ABI used across the monorepo.
 * Import what you need; tree-shaking removes the rest in bundled apps.
 */

// ── AXQToken ─────────────────────────────────────────────────────────────────

export const AXQ_TOKEN_ABI = [
  // ERC-20 reads
  { name: 'name',        type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'string' }] },
  { name: 'symbol',      type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'string' }] },
  { name: 'decimals',    type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'uint8' }] },
  { name: 'totalSupply', type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'balanceOf',   type: 'function', stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { name: 'allowance',   type: 'function', stateMutability: 'view',
    inputs: [{ name: 'owner', type: 'address' }, { name: 'spender', type: 'address' }],
    outputs: [{ type: 'uint256' }] },
  // ERC-20 writes
  { name: 'transfer',    type: 'function', stateMutability: 'nonpayable',
    inputs: [{ name: 'to', type: 'address' }, { name: 'amount', type: 'uint256' }],
    outputs: [{ type: 'bool' }] },
  { name: 'approve',     type: 'function', stateMutability: 'nonpayable',
    inputs: [{ name: 'spender', type: 'address' }, { name: 'amount', type: 'uint256' }],
    outputs: [{ type: 'bool' }] },
  { name: 'transferFrom', type: 'function', stateMutability: 'nonpayable',
    inputs: [{ name: 'from', type: 'address' }, { name: 'to', type: 'address' }, { name: 'amount', type: 'uint256' }],
    outputs: [{ type: 'bool' }] },
  // AXQToken-specific
  { name: 'genesisAllocate', type: 'function', stateMutability: 'nonpayable',
    inputs: [], outputs: [] },
  { name: 'TOTAL_SUPPLY', type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'uint256' }] },
  // Events
  { name: 'Transfer', type: 'event',
    inputs: [
      { name: 'from',  type: 'address', indexed: true },
      { name: 'to',    type: 'address', indexed: true },
      { name: 'value', type: 'uint256', indexed: false },
    ] },
  { name: 'Approval', type: 'event',
    inputs: [
      { name: 'owner',   type: 'address', indexed: true },
      { name: 'spender', type: 'address', indexed: true },
      { name: 'value',   type: 'uint256', indexed: false },
    ] },
] as const;

// ── AXQGovernance ─────────────────────────────────────────────────────────────

export const AXQ_GOVERNANCE_ABI = [
  // Constants / state reads
  { name: 'VOTING_PERIOD',      type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint64' }] },
  { name: 'TIME_LOCK_PERIOD',   type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint64' }] },
  { name: 'PROPOSAL_THRESHOLD', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'QUORUM_VOTES',       type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'proposalCount',      type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'AXQ_TOKEN',          type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'address' }] },
  { name: 'treasury',           type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'address' }] },
  {
    name: 'proposals',
    type: 'function', stateMutability: 'view',
    inputs: [{ name: 'id', type: 'uint256' }],
    outputs: [
      { name: 'id',            type: 'uint256' },
      { name: 'proposer',      type: 'address' },
      { name: 'description',   type: 'string'  },
      { name: 'callData',      type: 'bytes'   },
      { name: 'target',        type: 'address' },
      { name: 'value',         type: 'uint256' },
      { name: 'voteStart',     type: 'uint64'  },
      { name: 'voteEnd',       type: 'uint64'  },
      { name: 'executionTime', type: 'uint64'  },
      { name: 'votesFor',      type: 'uint256' },
      { name: 'votesAgainst',  type: 'uint256' },
      { name: 'executed',      type: 'bool'    },
      { name: 'vetoed',        type: 'bool'    },
    ],
  },
  {
    name: 'hasVoted',
    type: 'function', stateMutability: 'view',
    inputs: [{ name: 'id', type: 'uint256' }, { name: 'voter', type: 'address' }],
    outputs: [{ type: 'bool' }],
  },
  {
    name: 'vetoCount',
    type: 'function', stateMutability: 'view',
    inputs: [{ name: 'id', type: 'uint256' }],
    outputs: [{ type: 'uint8' }],
  },
  // Writes
  {
    name: 'propose',
    type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'target',      type: 'address' },
      { name: 'value',       type: 'uint256' },
      { name: 'callData',    type: 'bytes'   },
      { name: 'description', type: 'string'  },
    ],
    outputs: [{ type: 'uint256' }],
  },
  {
    name: 'castVote',
    type: 'function', stateMutability: 'nonpayable',
    inputs: [{ name: 'id', type: 'uint256' }, { name: 'support', type: 'bool' }],
    outputs: [],
  },
  {
    name: 'queue',
    type: 'function', stateMutability: 'nonpayable',
    inputs: [{ name: 'id', type: 'uint256' }],
    outputs: [],
  },
  {
    name: 'execute',
    type: 'function', stateMutability: 'payable',
    inputs: [{ name: 'id', type: 'uint256' }],
    outputs: [],
  },
  {
    name: 'vetoVote',
    type: 'function', stateMutability: 'nonpayable',
    inputs: [{ name: 'id', type: 'uint256' }],
    outputs: [],
  },
  // Events
  { name: 'ProposalCreated', type: 'event',
    inputs: [
      { name: 'id',          type: 'uint256', indexed: true },
      { name: 'proposer',    type: 'address', indexed: false },
      { name: 'description', type: 'string',  indexed: false },
    ] },
  { name: 'VoteCast', type: 'event',
    inputs: [
      { name: 'id',      type: 'uint256', indexed: true  },
      { name: 'voter',   type: 'address', indexed: false },
      { name: 'support', type: 'bool',    indexed: false },
      { name: 'weight',  type: 'uint256', indexed: false },
    ] },
  { name: 'ProposalQueued',  type: 'event',
    inputs: [
      { name: 'id',            type: 'uint256', indexed: true  },
      { name: 'executionTime', type: 'uint64',  indexed: false },
    ] },
  { name: 'ProposalExecuted', type: 'event',
    inputs: [{ name: 'id', type: 'uint256', indexed: true }] },
  { name: 'ProposalVetoed', type: 'event',
    inputs: [
      { name: 'id',        type: 'uint256', indexed: true  },
      { name: 'guardian',  type: 'address', indexed: false },
      { name: 'vetoCount', type: 'uint8',   indexed: false },
    ] },
] as const;

// ── ANSRegistry ───────────────────────────────────────────────────────────────

export const ANS_REGISTRY_ABI = [
  // reads
  { name: 'records', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'nameHash', type: 'bytes32' }],
    outputs: [
      { name: 'owner',    type: 'address' },
      { name: 'resolver', type: 'address' },
      { name: 'expiry',   type: 'uint64'  },
      { name: 'locked',   type: 'bool'    },
    ] },
  { name: 'resolve', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'label', type: 'string' }, { name: 'tld', type: 'string' }],
    outputs: [{ type: 'address' }] },
  { name: 'getResolver', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'label', type: 'string' }, { name: 'tld', type: 'string' }],
    outputs: [{ type: 'address' }] },
  { name: 'tldFees', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'tldHash', type: 'bytes32' }], outputs: [{ type: 'uint256' }] },
  { name: 'supportedTlds', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'tldHash', type: 'bytes32' }], outputs: [{ type: 'bool' }] },
  // writes
  { name: 'register', type: 'function', stateMutability: 'payable',
    inputs: [
      { name: 'label',    type: 'string'  },
      { name: 'tld',      type: 'string'  },
      { name: 'resolver', type: 'address' },
    ], outputs: [] },
  { name: 'renew', type: 'function', stateMutability: 'payable',
    inputs: [{ name: 'label', type: 'string' }, { name: 'tld', type: 'string' }],
    outputs: [] },
  { name: 'setResolver', type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'label',    type: 'string'  },
      { name: 'tld',      type: 'string'  },
      { name: 'resolver', type: 'address' },
    ], outputs: [] },
  { name: 'transfer', type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'label', type: 'string'  },
      { name: 'tld',   type: 'string'  },
      { name: 'to',    type: 'address' },
    ], outputs: [] },
  // events
  { name: 'NameRegistered', type: 'event',
    inputs: [
      { name: 'nameHash', type: 'bytes32', indexed: true  },
      { name: 'label',    type: 'string',  indexed: false },
      { name: 'tld',      type: 'string',  indexed: false },
      { name: 'owner',    type: 'address', indexed: false },
      { name: 'expiry',   type: 'uint64',  indexed: false },
    ] },
  { name: 'NameRenewed', type: 'event',
    inputs: [
      { name: 'nameHash',  type: 'bytes32', indexed: true  },
      { name: 'newExpiry', type: 'uint64',  indexed: false },
    ] },
] as const;

// ── KPXLiquidityPool ──────────────────────────────────────────────────────────

export const KPX_LIQUIDITY_POOL_ABI = [
  // reads
  { name: 'TOKEN_A',   type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'address' }] },
  { name: 'TOKEN_B',   type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'address' }] },
  { name: 'reserveA',  type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'reserveB',  type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'totalSupply', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'balanceOf',   type: 'function', stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { name: 'priceAInB',   type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'getAmountOut', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'amountIn', type: 'uint256' }, { name: 'tokenIn', type: 'address' }],
    outputs: [{ type: 'uint256' }] },
  // writes
  { name: 'addLiquidity', type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'amountADesired', type: 'uint256' },
      { name: 'amountBDesired', type: 'uint256' },
      { name: 'amountAMin',     type: 'uint256' },
      { name: 'amountBMin',     type: 'uint256' },
      { name: 'to',             type: 'address' },
    ],
    outputs: [
      { name: 'amountA',    type: 'uint256' },
      { name: 'amountB',    type: 'uint256' },
      { name: 'liquidity',  type: 'uint256' },
    ] },
  { name: 'removeLiquidity', type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'lpAmount',   type: 'uint256' },
      { name: 'amountAMin', type: 'uint256' },
      { name: 'amountBMin', type: 'uint256' },
      { name: 'to',         type: 'address' },
    ],
    outputs: [
      { name: 'amountA', type: 'uint256' },
      { name: 'amountB', type: 'uint256' },
    ] },
  { name: 'swapExactIn', type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'tokenIn',      type: 'address' },
      { name: 'amountIn',     type: 'uint256' },
      { name: 'amountOutMin', type: 'uint256' },
      { name: 'to',           type: 'address' },
    ],
    outputs: [{ name: 'amountOut', type: 'uint256' }] },
  // events
  { name: 'Swap', type: 'event',
    inputs: [
      { name: 'sender',    type: 'address', indexed: true  },
      { name: 'tokenIn',   type: 'address', indexed: false },
      { name: 'amountIn',  type: 'uint256', indexed: false },
      { name: 'amountOut', type: 'uint256', indexed: false },
      { name: 'to',        type: 'address', indexed: true  },
    ] },
  { name: 'LiquidityAdded', type: 'event',
    inputs: [
      { name: 'provider',  type: 'address', indexed: true  },
      { name: 'amountA',   type: 'uint256', indexed: false },
      { name: 'amountB',   type: 'uint256', indexed: false },
      { name: 'lpMinted',  type: 'uint256', indexed: false },
    ] },
  { name: 'LiquidityRemoved', type: 'event',
    inputs: [
      { name: 'provider', type: 'address', indexed: true  },
      { name: 'amountA',  type: 'uint256', indexed: false },
      { name: 'amountB',  type: 'uint256', indexed: false },
      { name: 'lpBurned', type: 'uint256', indexed: false },
    ] },
] as const;

// ── VRQPasskeyValidator ───────────────────────────────────────────────────────

export const VRQ_PASSKEY_VALIDATOR_ABI = [
  // reads
  { name: 'isModuleType',   type: 'function', stateMutability: 'pure',
    inputs: [{ name: 'moduleTypeId', type: 'uint256' }], outputs: [{ type: 'bool' }] },
  { name: 'isInitialized',  type: 'function', stateMutability: 'view',
    inputs: [{ name: 'smartAccount', type: 'address' }], outputs: [{ type: 'bool' }] },
  { name: 'accountPubKeyX', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { name: 'accountPubKeyY', type: 'function', stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { name: 'zkVerifier',     type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'address' }] },
  // ERC-1271
  { name: 'isValidSignatureWithSender', type: 'function', stateMutability: 'view',
    inputs: [
      { name: 'sender', type: 'address' },
      { name: 'hash',   type: 'bytes32' },
      { name: 'data',   type: 'bytes'   },
    ], outputs: [{ name: '', type: 'bytes4' }] },
  // ERC-7579 lifecycle
  { name: 'onInstall',   type: 'function', stateMutability: 'payable',
    inputs: [{ name: 'data', type: 'bytes' }], outputs: [] },
  { name: 'onUninstall', type: 'function', stateMutability: 'payable',
    inputs: [{ name: 'data', type: 'bytes' }], outputs: [] },
  // ERC-4337 validation
  { name: 'validateUserOp', type: 'function', stateMutability: 'payable',
    inputs: [
      {
        name: 'userOp', type: 'tuple',
        components: [
          { name: 'sender',              type: 'address' },
          { name: 'nonce',               type: 'uint256' },
          { name: 'initCode',            type: 'bytes'   },
          { name: 'callData',            type: 'bytes'   },
          { name: 'accountGasLimits',    type: 'bytes32' },
          { name: 'preVerificationGas',  type: 'uint256' },
          { name: 'gasFees',             type: 'bytes32' },
          { name: 'paymasterAndData',    type: 'bytes'   },
          { name: 'signature',           type: 'bytes'   },
        ],
      },
      { name: 'userOpHash', type: 'bytes32' },
    ],
    outputs: [{ type: 'uint256' }] },
  // events
  { name: 'ValidatorInstalled', type: 'event',
    inputs: [
      { name: 'account',  type: 'address', indexed: true  },
      { name: 'pubKeyX',  type: 'uint256', indexed: false },
      { name: 'pubKeyY',  type: 'uint256', indexed: false },
    ] },
  { name: 'ValidatorUninstalled', type: 'event',
    inputs: [{ name: 'account', type: 'address', indexed: true }] },
] as const;

// ── KPXRouterGateway ──────────────────────────────────────────────────────────

export const KPX_ROUTER_GATEWAY_ABI = [
  // reads
  { name: 'feeRate',       type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'vrqVerifier',   type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'address' }] },
  { name: 'darkPool',      type: 'function', stateMutability: 'view',
    inputs: [], outputs: [{ type: 'address' }] },
  { name: 'getPool',       type: 'function', stateMutability: 'view',
    inputs: [{ name: 'tokenA', type: 'address' }, { name: 'tokenB', type: 'address' }],
    outputs: [{ type: 'address' }] },
  // swapExactIn via a known pool address
  { name: 'swapExactIn',   type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'pool',         type: 'address' },
      { name: 'tokenIn',      type: 'address' },
      { name: 'amountIn',     type: 'uint256' },
      { name: 'amountOutMin', type: 'uint256' },
      { name: 'to',           type: 'address' },
    ],
    outputs: [{ name: 'amountOut', type: 'uint256' }] },
  // depositRWA — Banking bridge entry point
  { name: 'depositRWA',    type: 'function', stateMutability: 'nonpayable',
    inputs: [
      { name: 'assetId',    type: 'bytes32' },
      { name: 'amount',     type: 'uint256' },
      { name: 'collateral', type: 'uint256' },
      { name: 'zkProof',    type: 'bytes'   },
    ],
    outputs: [] },
  // events
  { name: 'SwapExecuted', type: 'event',
    inputs: [
      { name: 'sender',    type: 'address', indexed: true  },
      { name: 'pool',      type: 'address', indexed: false },
      { name: 'tokenIn',   type: 'address', indexed: false },
      { name: 'amountIn',  type: 'uint256', indexed: false },
      { name: 'amountOut', type: 'uint256', indexed: false },
    ] },
  { name: 'RWADeposited', type: 'event',
    inputs: [
      { name: 'depositor', type: 'address', indexed: true  },
      { name: 'assetId',   type: 'bytes32', indexed: false },
      { name: 'amount',    type: 'uint256', indexed: false },
    ] },
] as const;
