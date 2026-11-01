import type { ReactNode } from 'react';
import '@axioledger/axio-design-system/styles';
import { Providers } from '../components/Providers';

export const metadata = {
  title: 'Axiopass Wallet',
  description: 'Passkey-native smart wallet — FaceID / TouchID replaces your seed phrase.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        {/* Work Sans — AXIO Design System primary typeface */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Work+Sans:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
      </head>
      <body style={{ margin: 0, fontFamily: "'Work Sans', sans-serif" }}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
