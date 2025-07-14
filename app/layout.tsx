import type React from "react"
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "@/app/globals.css"
import { MultiWalletProvider } from "@/components/wallet/multi-wallet-provider"

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
      <head>
        <link rel="icon" href="/favicon.ico" type="image/x-icon" />
      </head>
      <body className={inter.className}>
        <MultiWalletProvider>
          {children}
        </MultiWalletProvider>
      </body>
    </html>
  )
}
