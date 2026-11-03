import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "YOUR_TOKEN Pay",
  description: "Payment Gateway & Merchant Dashboard — YOUR_TOKEN FinTech Services JSC",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="vi"><body>{children}</body></html>;
}
