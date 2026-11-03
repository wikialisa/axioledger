import type { Metadata, Viewport } from 'next';
import '../styles/globals.css';

export const metadata: Metadata = {
  title: {
    default: 'AXIOLEDGER ($AXQ) — Web3 Financial Infrastructure',
    template: '%s | AXIOLEDGER',
  },
  description:
    'AXIOLEDGER is a high-performance, privacy-preserving, multi-chain financial operating system. Hub & 4 Pillars — ZK-OBFT consensus, 600K+ TPS, DAO governance.',
  metadataBase: new URL('https://wikialisa.github.io/axioledger'),
  openGraph: {
    type: 'website',
    siteName: 'AXIOLEDGER',
    locale: 'en_US',
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#0D1117',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Work+Sans:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
