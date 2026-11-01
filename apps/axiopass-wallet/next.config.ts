import type { NextConfig } from 'next';

/**
 * Axiopass Wallet — Next.js config
 *
 * Security headers:
 *  - Content Security Policy (CSP): restricts scripts, styles, connect-src
 *    to known AXIOLEDGER domains + Anvil localnet.
 *  - Strict-Transport-Security (HSTS): 2 year max-age
 *  - X-Frame-Options: DENY (clickjacking)
 *  - X-Content-Type-Options: nosniff
 *  - Referrer-Policy: strict-origin-when-cross-origin
 *  - Permissions-Policy: camera, microphone, geolocation restricted
 */

// ── CSP builder ───────────────────────────────────────────────────────────────
// Each directive is an array of sources joined by a space.
// Policy is tightened per environment via NEXT_PUBLIC_NETWORK.

const isLocalnet = process.env.NEXT_PUBLIC_NETWORK === 'localnet';
const isDev      = process.env.NODE_ENV === 'development';

const AXIO_RPC_ORIGINS = [
  'https://rpc.axqprotocol.axq',
  'https://eth-sepolia.g.alchemy.com',
  'https://eth-mainnet.g.alchemy.com',
  // Staging origins
  'https://axiopass.pages.dev',
  'https://*.axiopass.pages.dev',
];

const LOCAL_ORIGINS = isLocalnet || isDev
  ? ['http://127.0.0.1:8545', 'ws://127.0.0.1:8545', 'http://localhost:*']
  : [];

const CSP_DIRECTIVES: Record<string, string[]> = {
  'default-src':        ["'self'"],
  'script-src':         ["'self'", "'unsafe-eval'",   // Next.js HMR + RSC need unsafe-eval in dev
                         ...( isDev ? ["'unsafe-inline'"] : [] )],
  'style-src':          ["'self'", "'unsafe-inline'"], // Inline styles from AXIO-DS components
  'img-src':            ["'self'", 'data:', 'blob:'],
  'font-src':           ["'self'", 'https://fonts.gstatic.com', 'data:'],
  'connect-src':        [
    "'self'",
    ...AXIO_RPC_ORIGINS,
    ...LOCAL_ORIGINS,
    'wss://eth-sepolia.g.alchemy.com',
    'https://api.coingecko.com',          // price data (Phase 5)
  ],
  'worker-src':         ["'self'", 'blob:'],
  'child-src':          ["'self'", 'blob:'],
  'frame-ancestors':    ["'none'"],         // deny iframe embedding
  'base-uri':           ["'self'"],
  'form-action':        ["'self'"],
  'upgrade-insecure-requests': isDev ? [] : [''],
};

function buildCSP(directives: Record<string, string[]>): string {
  return Object.entries(directives)
    .filter(([, vals]) => vals.length > 0)
    .map(([key, vals]) => `${key} ${vals.join(' ')}`.trim())
    .join('; ');
}

const csp = buildCSP(CSP_DIRECTIVES);

// ── Security headers ──────────────────────────────────────────────────────────
const SECURITY_HEADERS = [
  {
    key:   'Content-Security-Policy',
    value: csp,
  },
  {
    key:   'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload',
  },
  {
    key:   'X-Frame-Options',
    value: 'DENY',
  },
  {
    key:   'X-Content-Type-Options',
    value: 'nosniff',
  },
  {
    key:   'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
  {
    key:   'Permissions-Policy',
    // Allow PublicKeyCredential (WebAuthn) — required for PasskeyButton
    // Block camera, microphone, geolocation for all origins
    value: 'publickey-credentials-get=(self), publickey-credentials-create=(self), camera=(), microphone=(), geolocation=()',
  },
  {
    key:   'X-DNS-Prefetch-Control',
    value: 'on',
  },
  {
    key:   'Cross-Origin-Opener-Policy',
    // Required for SharedArrayBuffer (used by some ZK wasm bindings)
    value: 'same-origin',
  },
  {
    key:   'Cross-Origin-Embedder-Policy',
    value: 'require-corp',
  },
];

// ── Next.js config ────────────────────────────────────────────────────────────
const nextConfig: NextConfig = {
  reactStrictMode: true,

  // Transpile workspace packages (source-only, no build step)
  transpilePackages: [
    '@axioledger/axio-design-system',
    '@axioledger/evm-interop',
    '@axioledger/axq-sdk',
  ],

  async headers() {
    return [
      {
        // Apply security headers to all routes
        source: '/(.*)',
        headers: SECURITY_HEADERS,
      },
    ];
  },

  // Webpack: handle .ts imports from workspace packages
  webpack(config) {
    config.resolve.extensionAlias = {
      '.js': ['.ts', '.tsx', '.js'],
    };
    // Stub missing optional / Node-only peer deps from wagmi transitive deps.
    // None of these are used by AXIOLEDGER wallet in the browser.
    config.resolve.alias = {
      ...config.resolve.alias,
      // x402 payment protocol — pulled in by @coinbase/cdp-sdk
      '@x402/evm':              false,
      '@x402/core/client':      false,
      '@x402/evm/exact/client': false,
      '@x402/evm/upto/client':  false,
      '@x402/svm/exact/client': false,
      // React Native AsyncStorage — pulled in by @metamask/sdk browser bundle
      '@react-native-async-storage/async-storage': false,
      // pino-pretty — optional CLI formatter pulled in by @walletconnect/logger
      'pino-pretty': false,
      // ox/tempo VirtualMaster — dynamic require used by viem tempo chain (not needed)
      'ox/tempo': false,
    };
    return config;
  },
};

export default nextConfig;
