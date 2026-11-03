import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  eslint: { ignoreDuringBuilds: true },
  reactStrictMode: true,
  transpilePackages: ["ui-kit"],
  webpack(config) {
    config.resolve.alias = {
      ...config.resolve.alias,
      "@YOUR_NPM_SCOPE_UPPER/ui-kit": path.resolve(__dirname, "../../packages/ui-kit/src/index.ts"),
      "@YOUR_NPM_SCOPE_UPPER/types": path.resolve(__dirname, "../../packages/types/src/index.ts"),
      "@YOUR_NPM_SCOPE_UPPER/config": path.resolve(__dirname, "../../packages/config/src/index.ts"),
      "@YOUR_NPM_SCOPE_UPPER/core-sdk": path.resolve(__dirname, "../../packages/core-sdk/src/index.ts"),
    };
    return config;
  },
};

export default nextConfig;
