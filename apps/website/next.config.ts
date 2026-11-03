import type { NextConfig } from 'next';

/**
 * AXIOLEDGER Website — Next.js config
 *
 * output: 'export'  →  generates fully static HTML/CSS/JS in ./out/
 * basePath          →  required for GitHub Pages at wikialisa.github.io/axioledger/
 *                      Set NEXT_PUBLIC_BASE_PATH env var to override (e.g. for custom domain).
 * trailingSlash     →  ensures each route becomes index.html in its own directory.
 *                      Required for GitHub Pages static hosting.
 */

const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '/axioledger';

const nextConfig: NextConfig = {
  output: 'export',
  basePath,
  trailingSlash: true,
  reactStrictMode: true,

  // Disable image optimisation — not available in static export
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
