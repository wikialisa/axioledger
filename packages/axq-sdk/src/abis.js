'use strict';
/**
 * Minimal ABI slices for on-chain reads/writes used by AxioledgerSDK.
 * Full ABIs live in packages/evm-interop — these are the read-path subsets.
 */

/** AXQToken — read + transfer surface */
const AXQ_TOKEN_ABI = [
  {
    name: 'balanceOf',
    type: 'function',
    stateMutability: 'view',
    inputs:  [{ name: 'account', type: 'address' }],
    outputs: [{ name: '',        type: 'uint256'  }],
  },
  {
    name: 'totalSupply',
    type: 'function',
    stateMutability: 'view',
    inputs:  [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'allowance',
    type: 'function',
    stateMutability: 'view',
    inputs:  [
      { name: 'owner',   type: 'address' },
      { name: 'spender', type: 'address' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'transfer',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs:  [
      { name: 'to',     type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
  },
  {
    name: 'approve',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs:  [
      { name: 'spender', type: 'address' },
      { name: 'amount',  type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
  },
];

/** ANSRegistry — resolution surface */
const ANS_REGISTRY_ABI = [
  {
    name: 'resolve',
    type: 'function',
    stateMutability: 'view',
    inputs:  [
      { name: 'label', type: 'string' },
      { name: 'tld',   type: 'string' },
    ],
    outputs: [{ name: '', type: 'address' }],
  },
  {
    name: 'getResolver',
    type: 'function',
    stateMutability: 'view',
    inputs:  [
      { name: 'label', type: 'string' },
      { name: 'tld',   type: 'string' },
    ],
    outputs: [{ name: '', type: 'address' }],
  },
  {
    name: 'records',
    type: 'function',
    stateMutability: 'view',
    inputs:  [{ name: 'nameHash', type: 'bytes32' }],
    outputs: [
      { name: 'owner',    type: 'address' },
      { name: 'resolver', type: 'address' },
      { name: 'expiry',   type: 'uint64'  },
      { name: 'locked',   type: 'bool'    },
    ],
  },
  {
    name: 'register',
    type: 'function',
    stateMutability: 'payable',
    inputs:  [
      { name: 'label',    type: 'string'  },
      { name: 'tld',      type: 'string'  },
      { name: 'resolver', type: 'address' },
    ],
    outputs: [],
  },
  {
    name: 'tldFees',
    type: 'function',
    stateMutability: 'view',
    inputs:  [{ name: 'tldHash', type: 'bytes32' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
];

module.exports = { AXQ_TOKEN_ABI, ANS_REGISTRY_ABI };
