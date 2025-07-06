"use client"

import { useState, useEffect } from "react"
import "@/styles/swap.css"
import { ArrowUpDown, TrendingUp, Zap, RefreshCw, ChevronDown, ArrowLeft, LogOut, User, Users } from "lucide-react"
import { usePetra } from "@/components/wallet/petra-context"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import Link from "next/link"
import { ChatButton } from "@/components/chat/chat-button"
import { MobileMenuBar } from "@/components/swap/mobile-menu-bar"
import { WalletSelector } from "@/components/wallet/wallet-selector"
import { AdminInitializer } from "@/components/swap/admin-initializer"

interface Token {
  symbol: string
  name: string
  address: string
  decimals: number
  logoUrl: string
}

interface Quote {
  dex: string
  outputAmount: string
  priceImpact: string
  fee: string
  route: string[]
}

interface AppUser {
  id: string
  name: string
  email: string
  image: string
}

const tokens: Token[] = [
  {
    symbol: "APT",
    name: "Aptos",
    address: "0x1::aptos_coin::AptosCoin",
    decimals: 8,
    logoUrl: "/placeholder.svg?height=32&width=32",
  },
  {
    symbol: "APDOGE",
    name: "AptosDoge",
    address: "0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::aptosdoge::AptosDoge",
    decimals: 8,
    logoUrl: "/placeholder.svg?height=32&width=32",
  },
  {
    symbol: "USDC",
    name: "USD Coin",
    address: "0xa2eda21a58856fda86451436513b867c97eecb4ba099da5775520e0f7492e852::coin::T",
    decimals: 6,
    logoUrl: "/placeholder.svg?height=32&width=32",
  },
  {
    symbol: "USDT",
    name: "Tether USD",
    address: "0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b::coin::T",
    decimals: 6,
    logoUrl: "/placeholder.svg?height=32&width=32",
  },
  {
    symbol: "WETH",
    name: "Wrapped Ethereum",
    address: "0xcc8a89c8dce9693d354449f1f73e60e14e347417854f029db5bc8e7454008abb::coin::T",
    decimals: 8,
    logoUrl: "/placeholder.svg?height=32&width=32",
  },
]

// Aggregator configuration
const AGGREGATOR_ADDRESS = "0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8"
const SENDER_ADDRESS = "0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8"
const RECEIVER_ADDRESS = "0xed401eb09b9b70ba2b258f979534cbe1766b035b7ec67d9636a121099751a16a"

export default function SwapPage() {
  const { address, connected, network, signAndSubmitTransaction } = usePetra()
  const [fromToken, setFromToken] = useState<Token>(tokens[0])
  const [toToken, setToToken] = useState<Token>(tokens[1])
  const [fromAmount, setFromAmount] = useState("")
  const [isSwapping, setIsSwapping] = useState(false)
  const [user, setUser] = useState<AppUser | null>(null)
  const [quotes, setQuotes] = useState<Quote[]>([])
  const [isLoadingQuotes, setIsLoadingQuotes] = useState(false)
  const [showFromDropdown, setShowFromDropdown] = useState(false)
  const [showToDropdown, setShowToDropdown] = useState(false)
  const [activeSwapTab, setActiveSwapTab] = useState("swap")
  const [swapMode, setSwapMode] = useState<"same-address" | "cross-address">("cross-address")
  const [receiverAddress, setReceiverAddress] = useState(RECEIVER_ADDRESS)

  // Check for existing user session
  useEffect(() => {
    const savedUser = localStorage.getItem("user")
    if (savedUser) {
      setUser(JSON.parse(savedUser))
    }
  }, [])

  const handleLogout = () => {
    setUser(null)
    localStorage.removeItem("user")
  }

  // Fetch quotes from the aggregator
  const fetchQuotes = async () => {
    if (!fromAmount || Number.parseFloat(fromAmount) <= 0) return

    setIsLoadingQuotes(true)

    try {
      // Convert amount to octas (smallest unit)
      const amountInOctas = Math.floor(Number.parseFloat(fromAmount) * Math.pow(10, fromToken.decimals))
      
      // Call the aggregator's simulate_swap function
      const response = await fetch(`/api/simulate-swap`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          inputToken: fromToken.address,
          outputToken: toToken.address,
          inputAmount: amountInOctas.toString(),
        }),
      })

      if (response.ok) {
        const data = await response.json()
        const outputAmount = (Number(data.outputAmount) / Math.pow(10, toToken.decimals)).toFixed(6)
        
        const quote: Quote = {
          dex: data.dexId === 1 ? "Liquidswap" : "Econia",
          outputAmount,
          priceImpact: `${(Number(data.priceImpact) / 100).toFixed(2)}%`,
          fee: `${(Number(data.fee) / 100).toFixed(2)}%`,
          route: data.route || [fromToken.symbol, toToken.symbol],
        }
        
        setQuotes([quote])
      } else {
        // Fallback to mock quotes if API fails
        const mockQuotes: Quote[] = [
          {
            dex: "Liquidswap",
            outputAmount: (Number.parseFloat(fromAmount) * 1.02).toFixed(6),
            priceImpact: "0.12%",
            fee: "0.3%",
            route: [fromToken.symbol, toToken.symbol],
          },
          {
            dex: "Econia",
            outputAmount: (Number.parseFloat(fromAmount) * 0.98).toFixed(6),
            priceImpact: "0.08%",
            fee: "0.25%",
            route: [fromToken.symbol, "USDC", toToken.symbol],
          },
        ]
        setQuotes(mockQuotes)
      }
    } catch (error) {
      console.error("Error fetching quotes:", error)
      // Fallback to mock quotes
      const mockQuotes: Quote[] = [
        {
          dex: "Liquidswap",
          outputAmount: (Number.parseFloat(fromAmount) * 1.02).toFixed(6),
          priceImpact: "0.12%",
          fee: "0.3%",
          route: [fromToken.symbol, toToken.symbol],
        },
      ]
      setQuotes(mockQuotes)
    } finally {
      setIsLoadingQuotes(false)
    }
  }

  useEffect(() => {
    if (fromAmount) {
      const debounce = setTimeout(fetchQuotes, 800)
      return () => clearTimeout(debounce)
    } else {
      setQuotes([])
    }
  }, [fromAmount, fromToken, toToken])

  const swapTokens = () => {
    const temp = fromToken
    setFromToken(toToken)
    setToToken(temp)
  }

  const executeSwap = async () => {
    if (!connected || !address) {
      alert("Please connect your Petra wallet first!")
      return
    }

    setIsSwapping(true)

    try {
      // Convert amount to octas
      const amountInOctas = Math.floor(Number.parseFloat(fromAmount) * Math.pow(10, fromToken.decimals))
      const minOutputAmount = Math.floor(Number.parseFloat(bestQuote?.outputAmount || "0") * Math.pow(10, toToken.decimals) * 0.95) // 5% slippage
      const deadline = Math.floor(Date.now() / 1000) + 1200 // 20 minutes from now

      let transactionPayload

      if (swapMode === "cross-address") {
        // Cross-address swap using the aggregator
        transactionPayload = {
          type: "entry_function_payload",
          function: `${AGGREGATOR_ADDRESS}::multiswap_aggregator::swap_cross_address_v2`,
          type_arguments: [fromToken.address, toToken.address],
          arguments: [
            receiverAddress,
            amountInOctas.toString(),
            minOutputAmount.toString(),
            deadline.toString(),
          ],
        }
      } else {
        // Same-address swap
        transactionPayload = {
          type: "entry_function_payload",
          function: `${AGGREGATOR_ADDRESS}::multiswap_aggregator::swap_exact_input`,
          type_arguments: [fromToken.address, toToken.address],
          arguments: [
            amountInOctas.toString(),
            minOutputAmount.toString(),
            deadline.toString(),
          ],
        }
      }

      console.log("Executing swap with payload:", transactionPayload)
      
      // Sign and submit transaction
      const result = await signAndSubmitTransaction(transactionPayload)
      console.log("Transaction result:", result)

      alert("Swap completed successfully!")
      setFromAmount("")
      setQuotes([])
    } catch (error) {
      console.error("Swap failed:", error)
      alert("Swap failed. Please try again.")
    } finally {
      setIsSwapping(false)
    }
  }

  const bestQuote =
    quotes.length > 0
      ? quotes.reduce((best, current) =>
          Number.parseFloat(current.outputAmount) > Number.parseFloat(best.outputAmount) ? current : best,
        )
      : null

  return (
    <div className="min-h-screen bg-gradient-to-br from-black via-gray-900 to-black relative overflow-hidden">
      {/* Animated Background */}
      <div className="absolute inset-0">
        <div className="absolute top-0 left-0 w-72 h-72 bg-yellow-500 rounded-full mix-blend-multiply filter blur-xl opacity-10 animate-blob"></div>
        <div className="absolute top-0 right-0 w-72 h-72 bg-yellow-400 rounded-full mix-blend-multiply filter blur-xl opacity-10 animate-blob animation-delay-2000"></div>
        <div className="absolute -bottom-8 left-20 w-72 h-72 bg-yellow-600 rounded-full mix-blend-multiply filter blur-xl opacity-10 animate-blob animation-delay-4000"></div>
        <div className="absolute bottom-0 right-0 w-72 h-72 bg-yellow-300 rounded-full mix-blend-multiply filter blur-xl opacity-10 animate-blob animation-delay-6000"></div>
      </div>

      <div className="relative z-10 min-h-screen">
        {/* Top Navigation Bar */}
        <nav className="swap-nav px-4 py-3">
          <div className="container mx-auto flex items-center justify-between">
            <div className="flex items-center space-x-6">
              <Link href="/" className="flex items-center text-gray-300 hover:text-yellow-400 transition-colors">
                <ArrowLeft className="w-5 h-5 mr-2" />
                <span className="text-2xl font-bold bg-gradient-to-r from-yellow-400 to-yellow-600 bg-clip-text text-transparent">
                  AptosSwap
                </span>
              </Link>

              {/* Navigation Links */}
              <div className="hidden md:flex items-center space-x-6">
                <button className="swap-nav-link active text-yellow-400 font-semibold pb-1">Swap</button>
                <button className="swap-nav-link">Limit</button>
                <button className="swap-nav-link">DCA</button>
                <button className="swap-nav-link">Cross-chain</button>
              </div>
            </div>

            {/* Right Side - User & Wallet */}
            <div className="flex items-center space-x-4">
              {/* Network Selector */}
              <div className="network-selector flex items-center space-x-2 rounded-lg px-3 py-2">
                <div className="w-6 h-6 bg-gradient-to-r from-yellow-400 to-yellow-600 rounded-full flex items-center justify-center">
                  <span className="text-black text-xs font-bold">A</span>
                </div>
                <span className="text-white text-sm">{network?.name || "Aptos"}</span>
                <ChevronDown className="w-4 h-4" />
              </div>

              {/* User Info */}
              {user ? (
                <div className="flex items-center space-x-3">
                  <div className="user-info flex items-center space-x-2 rounded-lg px-3 py-2">
                    <img src={user.image || "/placeholder.svg"} alt={user.name} className="w-6 h-6 rounded-full" />
                    <span className="font-medium text-sm">{user.name}</span>
                  </div>
                  <Button
                    onClick={handleLogout}
                    variant="outline"
                    size="sm"
                    className="swap-button-secondary"
                  >
                    <LogOut className="w-4 h-4" />
                  </Button>
                </div>
              ) : null}

              {/* Petra Wallet Connection */}
              <WalletSelector />
            </div>
          </div>
        </nav>

        {/* Mobile Menu Bar */}
        <MobileMenuBar activeTab={activeSwapTab} onTabChange={setActiveSwapTab} />

        {/* Main Content */}
        <div className="container mx-auto px-4 py-6">
          <div className="flex gap-6">
            {/* Left Sidebar - Settings */}
            <div className="hidden lg:block w-80">
              {/* Admin Initializer - Only show for admin */}
              {connected && address === AGGREGATOR_ADDRESS && (
                <div className="mb-4">
                  <AdminInitializer />
                </div>
              )}
              
              <Card className="settings-panel mb-4">
                <CardContent className="p-4">
                  <h3 className="text-white font-semibold mb-3 flex items-center">
                    <Zap className="w-4 h-4 mr-2" />
                    Swap Settings
                  </h3>

                  {/* Wallet Status */}
                  {connected && address && (
                    <div className="wallet-status mb-4 p-3 rounded-lg">
                      <div className="flex items-center space-x-2 mb-2">
                        <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                        <span className="text-sm font-medium">Petra Wallet Connected</span>
                      </div>
                      <code className="text-xs text-gray-400 font-mono">
                        {address.slice(0, 10)}...{address.slice(-6)}
                      </code>
                    </div>
                  )}

                  {/* Slippage Tolerance */}
                  <div className="mb-4">
                    <label className="text-sm text-gray-300 mb-2 block">Slippage Tolerance</label>
                    <div className="flex space-x-2">
                      {["0.1%", "0.5%", "1%"].map((slippage) => (
                        <button
                          key={slippage}
                          className="slippage-button px-3 py-1 text-xs rounded"
                        >
                          {slippage}
                        </button>
                      ))}
                      <input
                        type="text"
                        placeholder="Custom"
                        className="swap-input px-2 py-1 text-xs w-16"
                      />
                    </div>
                  </div>

                  {/* Transaction Deadline */}
                  <div className="mb-4">
                    <label className="text-sm text-gray-300 mb-2 block">Transaction Deadline</label>
                    <div className="flex items-center space-x-2">
                      <input
                        type="number"
                        defaultValue="20"
                        className="swap-input px-3 py-2 w-20"
                      />
                      <span className="text-gray-400 text-sm">minutes</span>
                    </div>
                  </div>

                  {/* MEV Protection */}
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-300">MEV Protection</span>
                    <button className="mev-toggle w-10 h-6 rounded-full relative">
                      <div className="w-4 h-4 bg-black rounded-full absolute right-1 top-1"></div>
                    </button>
                  </div>
                </CardContent>
              </Card>

              {/* Recent Transactions */}
              <Card className="swap-card">
                <CardContent className="p-4">
                  <h3 className="text-white font-semibold mb-3">Recent Transactions</h3>
                  <div className="space-y-2">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="transaction-item flex items-center justify-between p-2 rounded">
                        <div className="flex items-center space-x-2">
                          <div className="w-2 h-2 bg-yellow-400 rounded-full"></div>
                          <span className="text-sm text-gray-300">APT → USDC</span>
                        </div>
                        <span className="text-xs text-gray-400">2m ago</span>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Center - Main Swap Interface */}
            <div className="flex-1 max-w-md mx-auto lg:mx-0">
              {/* Swap Card */}
              <Card className="swap-card p-6">
                <CardContent className="p-6">
                  {/* Swap Header */}
                  <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-bold text-white">Swap</h2>
                    <div className="flex items-center space-x-2">
                      <button className="swap-button-secondary p-2 rounded-lg">
                        <RefreshCw className="w-4 h-4" />
                      </button>
                      <button className="swap-button-secondary p-2 rounded-lg">
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                          <path
                            fillRule="evenodd"
                            d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z"
                            clipRule="evenodd"
                          />
                        </svg>
                      </button>
                    </div>
                  </div>

                  {/* Swap Mode Selector */}
                  <div className="mb-4">
                    <div className="flex items-center space-x-2 mb-3">
                      <span className="text-sm text-gray-300">Swap Mode:</span>
                    </div>
                    <div className="swap-mode-selector">
                      <button
                        onClick={() => setSwapMode("same-address")}
                        className={`swap-mode-button ${
                          swapMode === "same-address" ? "active" : ""
                        }`}
                      >
                        <User className="w-4 h-4" />
                        <span>Same Address</span>
                      </button>
                      <button
                        onClick={() => setSwapMode("cross-address")}
                        className={`swap-mode-button ${
                          swapMode === "cross-address" ? "active" : ""
                        }`}
                      >
                        <Users className="w-4 h-4" />
                        <span>Cross Address</span>
                      </button>
                    </div>
                  </div>

                  {/* Receiver Address Input (for cross-address mode) */}
                  {swapMode === "cross-address" && (
                    <div className="mb-4">
                      <label className="text-sm font-medium text-gray-300 mb-2 block">Receiver Address</label>
                      <Input
                        type="text"
                        value={receiverAddress}
                        onChange={(e) => setReceiverAddress(e.target.value)}
                        placeholder="Enter receiver address"
                        className="swap-input"
                      />
                      <div className="cross-address-info flex items-center justify-between mt-2 p-2 rounded-lg">
                        <span className="text-xs text-gray-400">
                          Sender: {SENDER_ADDRESS.slice(0, 10)}...{SENDER_ADDRESS.slice(-6)}
                        </span>
                        <span className="text-xs text-gray-400">
                          Receiver: {receiverAddress.slice(0, 10)}...{receiverAddress.slice(-6)}
                        </span>
                      </div>
                    </div>
                  )}

                  {/* Wallet Connection Status */}
                  {!connected && (
                    <div className="wallet-status disconnected mb-4 p-3 rounded-lg">
                      <p className="text-sm text-center">Connect your Petra wallet to start trading</p>
                    </div>
                  )}

                  {/* From Token */}
                  <div className="space-y-4">
                    <div className="relative">
                      <div className="flex items-center justify-between mb-2">
                        <label className="text-sm font-medium text-gray-300">You pay</label>
                        <span className="text-xs text-gray-400">Balance: {connected ? "Loading..." : "0.00"}</span>
                      </div>
                      <div className="token-selector rounded-xl p-4">
                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <Input
                              type="number"
                              placeholder="0"
                              value={fromAmount}
                              onChange={(e) => setFromAmount(e.target.value)}
                              className="bg-transparent border-none text-2xl font-bold text-white placeholder-gray-400 p-0 h-auto focus:ring-0"
                              disabled={!connected}
                            />
                            <div className="text-sm text-gray-400 mt-1">≈ $0.00</div>
                          </div>
                          <button
                            onClick={() => setShowFromDropdown(!showFromDropdown)}
                            className="swap-button-secondary flex items-center space-x-2 rounded-lg px-3 py-2 ml-4"
                          >
                            <img
                              src={fromToken.logoUrl || "/placeholder.svg"}
                              alt={fromToken.symbol}
                              className="w-6 h-6 rounded-full"
                            />
                            <span className="font-semibold">{fromToken.symbol}</span>
                            <ChevronDown className="w-4 h-4" />
                          </button>
                        </div>
                      </div>

                      {/* Token Dropdown */}
                      {showFromDropdown && (
                        <div className="token-dropdown absolute top-full left-0 right-0 mt-2 rounded-xl z-50 max-h-48 overflow-y-auto">
                          {tokens
                            .filter((token) => token.symbol !== toToken.symbol)
                            .map((token) => (
                              <button
                                key={token.symbol}
                                onClick={() => {
                                  setFromToken(token)
                                  setShowFromDropdown(false)
                                }}
                                className="token-option w-full flex items-center justify-between p-3 first:rounded-t-xl last:rounded-b-xl"
                              >
                                <div className="flex items-center space-x-3">
                                  <img
                                    src={token.logoUrl || "/placeholder.svg"}
                                    alt={token.symbol}
                                    className="w-8 h-8 rounded-full"
                                  />
                                  <div className="text-left">
                                    <div className="text-white font-semibold">{token.symbol}</div>
                                    <div className="text-xs text-gray-400">{token.name}</div>
                                  </div>
                                </div>
                                <div className="text-right">
                                  <div className="text-white text-sm">0.00</div>
                                  <div className="text-xs text-gray-400">$0.00</div>
                                </div>
                              </button>
                            ))}
                        </div>
                      )}
                    </div>

                    {/* Swap Button */}
                    <div className="flex justify-center">
                      <button
                        onClick={swapTokens}
                        className="swap-arrow p-3 rounded-full"
                      >
                        <ArrowUpDown className="w-5 h-5 text-black" />
                      </button>
                    </div>

                    {/* To Token */}
                    <div className="relative">
                      <div className="flex items-center justify-between mb-2">
                        <label className="text-sm font-medium text-gray-300">You receive</label>
                        <span className="text-xs text-gray-400">Balance: {connected ? "Loading..." : "0.00"}</span>
                      </div>
                      <div className="token-selector rounded-xl p-4">
                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <div className="text-2xl font-bold text-white">
                              {bestQuote ? bestQuote.outputAmount : "0"}
                            </div>
                            <div className="text-sm text-gray-400 mt-1">≈ $0.00</div>
                          </div>
                          <button
                            onClick={() => setShowToDropdown(!showToDropdown)}
                            className="swap-button-secondary flex items-center space-x-2 rounded-lg px-3 py-2 ml-4"
                          >
                            <img
                              src={toToken.logoUrl || "/placeholder.svg"}
                              alt={toToken.symbol}
                              className="w-6 h-6 rounded-full"
                            />
                            <span className="font-semibold">{toToken.symbol}</span>
                            <ChevronDown className="w-4 h-4" />
                          </button>
                        </div>
                      </div>

                      {/* Token Dropdown */}
                      {showToDropdown && (
                        <div className="token-dropdown absolute top-full left-0 right-0 mt-2 rounded-xl z-50 max-h-48 overflow-y-auto">
                          {tokens
                            .filter((token) => token.symbol !== fromToken.symbol)
                            .map((token) => (
                              <button
                                key={token.symbol}
                                onClick={() => {
                                  setToToken(token)
                                  setShowToDropdown(false)
                                }}
                                className="token-option w-full flex items-center justify-between p-3 first:rounded-t-xl last:rounded-b-xl"
                              >
                                <div className="flex items-center space-x-3">
                                  <img
                                    src={token.logoUrl || "/placeholder.svg"}
                                    alt={token.symbol}
                                    className="w-8 h-8 rounded-full"
                                  />
                                  <div className="text-left">
                                    <div className="text-white font-semibold">{token.symbol}</div>
                                    <div className="text-xs text-gray-400">{token.name}</div>
                                  </div>
                                </div>
                                <div className="text-right">
                                  <div className="text-white text-sm">0.00</div>
                                  <div className="text-xs text-gray-400">$0.00</div>
                                </div>
                              </button>
                            ))}
                        </div>
                      )}
                    </div>

                    {/* Route Information */}
                    {(isLoadingQuotes || quotes.length > 0) && (
                      <div className="route-info rounded-lg p-3">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-sm text-gray-300 flex items-center">
                            <TrendingUp className="w-4 h-4 mr-1" />
                            Best Route
                          </span>
                          {bestQuote && (
                            <Badge className="swap-badge text-xs">
                              <Zap className="w-3 h-3 mr-1" />
                              {bestQuote.dex}
                            </Badge>
                          )}
                        </div>

                        {isLoadingQuotes ? (
                          <div className="swap-loading flex items-center space-x-2 p-2 rounded">
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-yellow-400"></div>
                            <span className="text-sm text-gray-400">Finding best route...</span>
                          </div>
                        ) : bestQuote ? (
                          <div className="space-y-1">
                            <div className="flex justify-between text-xs">
                              <span className="text-gray-400">Price Impact:</span>
                              <span className="text-white">{bestQuote.priceImpact}</span>
                            </div>
                            <div className="flex justify-between text-xs">
                              <span className="text-gray-400">Network Fee:</span>
                              <span className="text-white">~$0.05</span>
                            </div>
                            <div className="flex justify-between text-xs">
                              <span className="text-gray-400">Route:</span>
                              <span className="text-white">{bestQuote.route.join(" → ")}</span>
                            </div>
                          </div>
                        ) : null}
                      </div>
                    )}

                    {/* Swap Button */}
                    <Button
                      onClick={executeSwap}
                      disabled={!connected || !fromAmount || Number.parseFloat(fromAmount) <= 0 || isSwapping}
                      className="swap-execute-button w-full font-bold py-4 rounded-xl text-lg"
                    >
                      {isSwapping ? (
                        <div className="flex items-center justify-center">
                          <RefreshCw className="w-5 h-5 mr-2 animate-spin" />
                          {swapMode === "cross-address" ? "Cross-Address Swapping..." : "Swapping..."}
                        </div>
                      ) : !connected ? (
                        "Connect Petra Wallet"
                      ) : !fromAmount || Number.parseFloat(fromAmount) <= 0 ? (
                        "Enter Amount"
                      ) : swapMode === "cross-address" ? (
                        `Swap ${fromToken.symbol} → ${toToken.symbol} (Cross-Address)`
                      ) : (
                        `Swap ${fromToken.symbol} for ${toToken.symbol}`
                      )}
                    </Button>

                    {/* Cross-Address Info */}
                    {swapMode === "cross-address" && connected && fromAmount && (
                      <div className="cross-address-info mt-3 p-3 rounded-lg">
                        <div className="flex items-center space-x-2 mb-2">
                          <Users className="w-4 h-4" />
                          <span className="text-sm font-medium">Cross-Address Swap</span>
                        </div>
                        <div className="text-xs text-gray-300 space-y-1">
                          <div>From: {SENDER_ADDRESS.slice(0, 10)}...{SENDER_ADDRESS.slice(-6)}</div>
                          <div>To: {receiverAddress.slice(0, 10)}...{receiverAddress.slice(-6)}</div>
                          <div>Using: Aptos DEX Aggregator</div>
                        </div>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Right Sidebar - Market Info */}
            <div className="hidden xl:block w-80">
              <Card className="swap-card mb-4">
                <CardContent className="p-4">
                  <h3 className="text-white font-semibold mb-3">Market Overview</h3>
                  <div className="space-y-3">
                    {[
                      { pair: "APT/USDC", price: "$8.45", change: "+2.34%", positive: true },
                      { pair: "USDT/USDC", price: "$1.00", change: "+0.01%", positive: true },
                      { pair: "WETH/APT", price: "285.6", change: "-1.23%", positive: false },
                    ].map((market, i) => (
                      <div key={i} className="market-item flex items-center justify-between p-2 rounded">
                        <div>
                          <div className="text-white text-sm font-medium">{market.pair}</div>
                          <div className="text-gray-400 text-xs">{market.price}</div>
                        </div>
                        <div className={`text-sm font-medium ${market.positive ? "text-green-400" : "text-red-400"}`}>
                          {market.change}
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              <Card className="swap-card">
                <CardContent className="p-4">
                  <h3 className="text-white font-semibold mb-3">Platform Stats</h3>
                  <div className="space-y-3">
                    <div className="platform-stat flex justify-between">
                      <span className="text-gray-400 text-sm">24h Volume</span>
                      <span className="text-white font-medium">$2.4M</span>
                    </div>
                    <div className="platform-stat flex justify-between">
                      <span className="text-gray-400 text-sm">Total Liquidity</span>
                      <span className="text-white font-medium">$45.2M</span>
                    </div>
                    <div className="platform-stat flex justify-between">
                      <span className="text-gray-400 text-sm">Active Pairs</span>
                      <span className="text-white font-medium">156</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </div>

      {/* Chat Button - Only visible when user is logged in */}
      <ChatButton user={user} />
    </div>
  )
}
