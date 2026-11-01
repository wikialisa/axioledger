import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,

  transpilePackages: [
    '@axioledger/axio-design-system',
    '@axioledger/evm-interop',
    '@axioledger/axq-sdk',
  ],

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
