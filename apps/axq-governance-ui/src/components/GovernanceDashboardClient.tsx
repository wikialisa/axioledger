'use client';

import dynamic from 'next/dynamic';

const GovernanceDashboard = dynamic(
  () => import('./GovernanceDashboard').then(m => m.GovernanceDashboard),
  { ssr: false }
);

export function GovernanceDashboardClient() {
  return <GovernanceDashboard />;
}
