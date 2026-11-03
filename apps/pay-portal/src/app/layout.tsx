import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AXVN Pay",
  description: "Payment Gateway & Merchant Dashboard — AXVN FinTech Services JSC",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
