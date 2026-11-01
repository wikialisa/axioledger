import type { NextConfig } from 'next';

/**
 * AXQ Governance UI — Next.js config
 *
 * CSP differences from axiopass-wallet:
 *  - No PublicKeyCredential in Permissions-Policy (no passkey on governance UI)
 *  - frame-ancestors: none (governance should never be embedded)
 *  - connect-src includes governance-specific API origins
 */

const isLocalnet = process.env.NEXT_PUBLIC_NETWORK === 'localnet';
const isDev      = process.env.NODE_ENV === 'development';

const AXIO_RPC_ORIGINS = [
  'https://rpc.axqprotocol.axq',
  'https://eth-sepolia.g.alchemy.com',
  'https://eth-mainnet.g.alchemy.com',
  'https://axio-governance.pages.dev',
  'https://*.axio-governance.pages.dev',
];

const LOCAL_ORIGINS = isLocalnet || isDev
  ? ['http://127.0.0.1:8545', 'ws://127.0.0.1:8545', 'http://localhost:*']
  : [];

const CSP_DIRECTIVES: Record<string, string[]> = {
  'default-src':   ["'self'"],
  'script-src':    ["'self'", "'unsafe-eval'",
                   ...( isDev ? ["'unsafe-inline'"] : [] )],
  'style-src':     ["'self'", "'unsafe-inline'"],
  'img-src':       ["'self'", 'data:', 'blob:'],
  'font-src':      ["'self'", 'https://fonts.gstatic.com', 'data:'],
  'connect-src':   ["'self'", ...AXIO_RPC_ORIGINS, ...LOCAL_ORIGINS,
                   'wss://eth-sepolia.g.alchemy.com'],
  'worker-src':    ["'self'", 'blob:'],
  'child-src':     ["'self'", 'blob:'],
  'frame-ancestors': ["'none'"],
  'base-uri':      ["'self'"],
  'form-action':   ["'self'"],
  'upgrade-insecure-requests': isDev ? [] : [''],
};

function buildCSP(directives: Record<string, string[]>): string {
  return Object.entries(directives)
    .filter(([, vals]) => vals.length > 0)
    .map(([key, vals]) => `${key} ${vals.join(' ')}`.trim())
    .join('; ');
}

const SECURITY_HEADERS = [
  { key: 'Content-Security-Policy',      value: buildCSP(CSP_DIRECTIVES) },
  { key: 'Strict-Transport-Security',    value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options',              value: 'DENY' },
  { key: 'X-Content-Type-Options',       value: 'nosniff' },
  { key: 'Referrer-Policy',              value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy',           value: 'camera=(), microphone=(), geolocation=()' },
  { key: 'X-DNS-Prefetch-Control',       value: 'on' },
  { key: 'Cross-Origin-Opener-Policy',   value: 'same-origin' },
  { key: 'Cross-Origin-Embedder-Policy', value: 'require-corp' },
];

const nextConfig: NextConfig = {
  reactStrictMode: true,

  transpilePackages: [
    '@axioledger/axio-design-system',
    '@axioledger/evm-interop',
    '@axioledger/axq-sdk',
  ],

  async headers() {
    return [{ source: '/(.*)', headers: SECURITY_HEADERS }];
  },

  webpack(config) {
    config.resolve.extensionAlias = { '.js': ['.ts', '.tsx', '.js'] };
    config.resolve.alias = {
      ...config.resolve.alias,
      '@x402/evm':              false,
      '@x402/core/client':      false,
      '@x402/evm/exact/client': false,
      '@x402/evm/upto/client':  false,
      '@x402/svm/exact/client': false,
      '@react-native-async-storage/async-storage': false,
      'pino-pretty': false,
      'ox/tempo':    false,
    };
    return config;
  },
};

export default nextConfig;
