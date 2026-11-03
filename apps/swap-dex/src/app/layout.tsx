import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AXVN Swap",
  description: "AMM DEX & Cross-chain Liquidity Router — AXVN Global Ventures Pte. Ltd.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
