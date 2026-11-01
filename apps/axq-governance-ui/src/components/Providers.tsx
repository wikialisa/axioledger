/**
 * WagmiProvider wrapper — must be a client component because it uses
 * React context.  Wraps the whole app so all pages have access to wagmi hooks.
 */

'use client';

import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AxioProvider } from '@axioledger/axio-design-system';
import { wagmiConfig } from '../lib/config';
import type { ReactNode } from 'react';

const queryClient = new QueryClient();

export function Providers({ children }: { children: ReactNode }) {
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        {/* AxioProvider mounts ThemeContext + ANSContext + CSS token root */}
        <AxioProvider theme="system">
          {children}
        </AxioProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
