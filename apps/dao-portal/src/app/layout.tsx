import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AXVN DAO",
  description: "Treasury Management & Governance Portal — AXVN Capital & Foundation Ltd.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
