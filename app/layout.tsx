import type React from "react"
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "@/app/globals.css"
import { PetraProvider } from "@/components/wallet/petra-context"
import { WalletProvider } from "@/components/wallet/wallet-provider"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "AptosSwap - The Future of DeFi Trading",
  description: "Experience lightning-fast swaps with the best rates across multiple DEXs on Aptos blockchain.",
    generator: 'v0.dev'
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <PetraProvider>
          <WalletProvider>{children}</WalletProvider>
        </PetraProvider>
      </body>
    </html>
  )
}
