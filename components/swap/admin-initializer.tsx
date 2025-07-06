"use client"

import { useState } from "react"
import { usePetra } from "@/components/wallet/petra-context"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { CheckCircle, AlertCircle, Loader2, Settings, Database, Coins } from "lucide-react"

interface InitializationStatus {
  aggregator: boolean
  aptosdoge: boolean
  pools: boolean
  minting: boolean
}

const AGGREGATOR_ADDRESS = "0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8"

export function AdminInitializer() {
  const { address, connected, signAndSubmitTransaction } = usePetra()
  const [isInitializing, setIsInitializing] = useState(false)
  const [status, setStatus] = useState<InitializationStatus>({
    aggregator: false,
    aptosdoge: false,
    pools: false,
    minting: false,
  })
  const [mintAmount, setMintAmount] = useState("1000000000") // 1B APDOGE default
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // Check if current user is admin
  const isAdmin = connected && address === AGGREGATOR_ADDRESS

  const initializeAggregator = async () => {
    if (!connected || !address) {
      setError("Please connect your Petra wallet first!")
      return
    }

    if (!isAdmin) {
      setError("Only the admin can initialize the aggregator!")
      return
    }

    setIsInitializing(true)
    setError(null)
    setSuccess(null)

    try {
      // Step 1: Initialize the aggregator
      console.log("Initializing aggregator...")
      const aggregatorPayload = {
        type: "entry_function_payload",
        function: `${AGGREGATOR_ADDRESS}::multiswap_aggregator_v2::initialize`,
        type_arguments: [],
        arguments: [],
      }

      const aggregatorResult = await signAndSubmitTransaction(aggregatorPayload)
      console.log("Aggregator initialization result:", aggregatorResult)
      setStatus(prev => ({ ...prev, aggregator: true }))
      setSuccess("✅ Aggregator initialized successfully!")

      // Step 2: Initialize AptosDoge token
      console.log("Initializing AptosDoge token...")
      const aptosdogePayload = {
        type: "entry_function_payload",
        function: `${AGGREGATOR_ADDRESS}::aptosdoge::initialize`,
        type_arguments: [],
        arguments: [],
      }

      const aptosdogeResult = await signAndSubmitTransaction(aptosdogePayload)
      console.log("AptosDoge initialization result:", aptosdogeResult)
      setStatus(prev => ({ ...prev, aptosdoge: true }))
      setSuccess("✅ AptosDoge token initialized successfully!")

      // Step 3: Setup default pools
      console.log("Setting up default pools...")
      const poolsPayload = {
        type: "entry_function_payload",
        function: `${AGGREGATOR_ADDRESS}::multiswap_aggregator_v2::setup_default_pools`,
        type_arguments: [],
        arguments: [],
      }

      const poolsResult = await signAndSubmitTransaction(poolsPayload)
      console.log("Pools setup result:", poolsResult)
      setStatus(prev => ({ ...prev, pools: true }))
      setSuccess("✅ Default pools setup complete!")

      // Step 4: Mint AptosDoge for testing
      console.log("Minting AptosDoge for testing...")
      const mintPayload = {
        type: "entry_function_payload",
        function: `${AGGREGATOR_ADDRESS}::aptosdoge::mint`,
        type_arguments: [],
        arguments: [address, mintAmount],
      }

      const mintResult = await signAndSubmitTransaction(mintPayload)
      console.log("Minting result:", mintResult)
      setStatus(prev => ({ ...prev, minting: true }))
      setSuccess("✅ AptosDoge minted successfully!")

      setSuccess("🎉 All initialization steps completed successfully!")
      
    } catch (error) {
      console.error("Initialization failed:", error)
      setError(`Initialization failed: ${error instanceof Error ? error.message : 'Unknown error'}`)
    } finally {
      setIsInitializing(false)
    }
  }

  const checkInitializationStatus = async () => {
    if (!connected || !address) {
      setError("Please connect your Petra wallet first!")
      return
    }

    try {
      // Check if aggregator is initialized by calling a view function
      const response = await fetch('https://fullnode.testnet.aptoslabs.com/v1/view', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          function: `${AGGREGATOR_ADDRESS}::multiswap_aggregator_v2::get_config`,
          type_arguments: [],
          arguments: [],
        }),
      })

      if (response.ok) {
        setStatus(prev => ({ ...prev, aggregator: true }))
        setSuccess("✅ Aggregator is already initialized!")
      } else {
        setStatus(prev => ({ ...prev, aggregator: false }))
        setError("❌ Aggregator is not initialized")
      }
    } catch (error) {
      console.error("Status check failed:", error)
      setError("Failed to check initialization status")
    }
  }

  if (!connected) {
    return (
      <Card className="swap-card">
        <CardContent className="p-6">
          <div className="text-center">
            <AlertCircle className="w-12 h-12 mx-auto mb-4" />
            <h3 className="text-white font-semibold mb-2">Admin Access Required</h3>
            <p className="text-gray-400 mb-4">Please connect your Petra wallet to access admin functions.</p>
          </div>
        </CardContent>
      </Card>
    )
  }

  if (!isAdmin) {
    return (
      <Card className="swap-card">
        <CardContent className="p-6">
          <div className="text-center">
            <AlertCircle className="w-12 h-12 mx-auto mb-4" />
            <h3 className="text-white font-semibold mb-2">Access Denied</h3>
            <p className="text-gray-400 mb-4">Only the admin can access this function.</p>
            <div className="text-sm text-gray-500">
              <p>Connected: {address?.slice(0, 10)}...{address?.slice(-6)}</p>
              <p>Required: {AGGREGATOR_ADDRESS.slice(0, 10)}...{AGGREGATOR_ADDRESS.slice(-6)}</p>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="swap-card">
      <CardHeader>
        <CardTitle className="text-white flex items-center">
          <Settings className="w-5 h-5 mr-2" />
          Admin Initialization
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Status Overview */}
        <div className="grid grid-cols-2 gap-4">
          <div className="settings-item flex items-center space-x-2 p-3 rounded-lg">
            <Database className="w-4 h-4" />
            <span className="text-sm text-gray-300">Aggregator</span>
            <Badge className="swap-badge" variant={status.aggregator ? "default" : "secondary"}>
              {status.aggregator ? "Ready" : "Pending"}
            </Badge>
          </div>
          <div className="settings-item flex items-center space-x-2 p-3 rounded-lg">
            <Coins className="w-4 h-4" />
            <span className="text-sm text-gray-300">AptosDoge</span>
            <Badge className="swap-badge" variant={status.aptosdoge ? "default" : "secondary"}>
              {status.aptosdoge ? "Ready" : "Pending"}
            </Badge>
          </div>
          <div className="settings-item flex items-center space-x-2 p-3 rounded-lg">
            <Database className="w-4 h-4" />
            <span className="text-sm text-gray-300">Pools</span>
            <Badge className="swap-badge" variant={status.pools ? "default" : "secondary"}>
              {status.pools ? "Ready" : "Pending"}
            </Badge>
          </div>
          <div className="settings-item flex items-center space-x-2 p-3 rounded-lg">
            <Coins className="w-4 h-4" />
            <span className="text-sm text-gray-300">Minting</span>
            <Badge className="swap-badge" variant={status.minting ? "default" : "secondary"}>
              {status.minting ? "Ready" : "Pending"}
            </Badge>
          </div>
        </div>

        {/* Mint Amount Input */}
        <div className="space-y-2">
          <Label htmlFor="mintAmount" className="text-gray-300">AptosDoge Mint Amount (octas)</Label>
          <Input
            id="mintAmount"
            type="number"
            value={mintAmount}
            onChange={(e) => setMintAmount(e.target.value)}
            placeholder="1000000000"
            className="swap-input"
          />
          <p className="text-xs text-gray-400">
            {mintAmount ? `${(parseInt(mintAmount) / 100000000).toLocaleString()} APDOGE` : "Enter amount in octas"}
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex space-x-4">
          <Button
            onClick={checkInitializationStatus}
            variant="outline"
            className="swap-button-secondary flex-1"
            disabled={isInitializing}
          >
            <CheckCircle className="w-4 h-4 mr-2" />
            Check Status
          </Button>
          <Button
            onClick={initializeAggregator}
            className="swap-button flex-1 font-bold"
            disabled={isInitializing}
          >
            {isInitializing ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Initializing...
              </>
            ) : (
              <>
                <Settings className="w-4 h-4 mr-2" />
                Initialize All
              </>
            )}
          </Button>
        </div>

        {/* Status Messages */}
        {error && (
          <div className="status-message status-error p-3 rounded-lg">
            <div className="flex items-center space-x-2">
              <AlertCircle className="w-4 h-4" />
              <span className="text-sm">{error}</span>
            </div>
          </div>
        )}

        {success && (
          <div className="status-message status-success p-3 rounded-lg">
            <div className="flex items-center space-x-2">
              <CheckCircle className="w-4 h-4" />
              <span className="text-sm">{success}</span>
            </div>
          </div>
        )}

        {/* Contract Info */}
        <div className="settings-item p-3 rounded-lg">
          <h4 className="text-white font-medium mb-2">Contract Information</h4>
          <div className="space-y-1 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-400">Aggregator Address:</span>
              <code className="text-yellow-400">{AGGREGATOR_ADDRESS.slice(0, 10)}...{AGGREGATOR_ADDRESS.slice(-6)}</code>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Connected Wallet:</span>
              <code className="text-blue-400">{address?.slice(0, 10)}...{address?.slice(-6)}</code>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Network:</span>
              <span className="text-green-400">Testnet</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
} 