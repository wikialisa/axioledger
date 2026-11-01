'use client';

import dynamic from 'next/dynamic';

const DEXDashboard = dynamic(
  () => import('./DEXDashboard').then(m => m.DEXDashboard),
  { ssr: false }
);

export function DEXDashboardClient() {
  return <DEXDashboard />;
}
