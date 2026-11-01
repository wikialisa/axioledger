'use client';

import dynamic from 'next/dynamic';

// wagmi + viem + walletconnect use browser globals (window, navigator) at
// module-level — ssr: false must live inside a Client Component (Next.js 15).
const WalletHome = dynamic(
  () => import('./WalletHome').then(m => m.WalletHome),
  { ssr: false }
);

export function WalletHomeClient() {
  return <WalletHome />;
}
