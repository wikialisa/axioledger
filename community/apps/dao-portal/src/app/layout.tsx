import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "YOUR_TOKEN DAO",
  description: "Treasury Management & Governance Portal — YOUR_TOKEN Capital & Foundation Ltd.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
