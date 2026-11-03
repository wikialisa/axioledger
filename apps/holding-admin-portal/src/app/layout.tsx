import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AXVN Holding Admin",
  description: "IP Asset Management & Whitelist Governance — AXVN TECH HOLDING JSC",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
