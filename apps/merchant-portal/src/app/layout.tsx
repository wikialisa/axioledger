import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AXVN Merchant — Payment Dashboard",
  description: "Merchant Portal — Quản lý thanh toán, API Keys, đơn hàng — AXVN FinTech",
  icons: { icon: "/favicon.ico" },
  openGraph: {
    title: "AXVN Merchant Portal",
    description: "Merchant Dashboard — Quản lý thanh toán & API",
    url: "https://merchant.${BRAND_DOMAIN}",
    siteName: "AXVN Merchant",
    locale: "vi_VN",
    type: "website",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#000000",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="vi">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Work+Sans:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
