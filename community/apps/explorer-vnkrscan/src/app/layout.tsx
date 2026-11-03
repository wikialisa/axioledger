import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "YOUR_TOKEN Scan",
  description: "App-Chain Block Explorer & Proof of Reserve — YOUR_TOKEN Blockchain Network Ltd.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
