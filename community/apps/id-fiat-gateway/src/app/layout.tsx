import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "YOUR_TOKEN ID | Fiat Gateway",
  description: "P2P Escrow, Identity & Fiat On/Off Ramp — YOUR_TOKEN FinTech Services JSC",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
