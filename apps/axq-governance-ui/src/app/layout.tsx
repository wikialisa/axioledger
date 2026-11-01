import type { ReactNode } from 'react';
import '@axioledger/axio-design-system/styles';
import { Providers } from '../components/Providers';

export const metadata = {
  title: 'AXQ Governance',
  description: 'AXIOLEDGER DAO — Quadratic voting · Guardian Council · Time-Lock',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, background: 'var(--color-background)' }}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
