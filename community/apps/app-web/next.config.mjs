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
    // alias "@YOUR_NPM_SCOPE_UPPER/ui-kit" → "ui-kit" (legacy import path used in pages)
    config.resolve.alias = {
      ...config.resolve.alias,
      "@YOUR_NPM_SCOPE_UPPER/ui-kit": path.resolve(__dirname, "../../packages/ui-kit/src/index.ts"),
    };
    return config;
  },
};

export default nextConfig;
