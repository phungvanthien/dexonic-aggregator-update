# Dexonic Dex Aggregator - The Future of DeFi Trading

A decentralized exchange aggregator on the Aptos blockchain that provides lightning-fast swaps with the best rates across multiple DEXs.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- pnpm (recommended) or npm
- Petra Wallet extension for browser

### Installation & Setup

1. **Clone and install dependencies:**
```bash
git clone <repository-url>
cd DexonicDexAggregator
pnpm install
```

2. **Start the development server:**
```bash
pnpm dev
```

3. **Open your browser:**
Navigate to [http://localhost:3000](http://localhost:3000)

## 🏗️ Project Structure

```
DexonicDexAggregator/
├── app/                    # Next.js app directory
│   ├── api/               # API routes
│   ├── swap/              # Swap interface
│   ├── chat/              # Chat feature
│   └── profile/           # User profile
├── components/            # React components
│   ├── swap/             # Swap-related components
│   ├── auth/             # Authentication components
│   └── ui/               # UI components
├── aptos-multiswap-aggregator-v3/  # Smart contracts
└── lib/                  # Utility functions
```

## 🔧 Smart Contract Deployment

The smart contracts have been deployed to Aptos mainnet:

- **Aggregator Contract**: `0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::multiswap_aggregator_v2`

See `deploy.md` for detailed deployment information.

## 🎯 Features

### Core Features
- **Multi-DEX Aggregation**: Get the best rates across multiple DEXs
- **Cross-Address Swaps**: Swap tokens to different addresses
- **Real-time Quotes**: Instant price quotes and route optimization
- **MEV Protection**: Built-in protection against MEV attacks
- **Mobile Responsive**: Optimized for all device sizes

### Supported Tokens
- **APT** (Aptos Coin)
- **USDC** (USD Coin)
- **USDT** (Tether USD)
- **WETH** (Wrapped ETH)

### DEX Integration
- **Liquidswap**: `0x190d44266241744264b964a37b8f09863167a12d3e70cda39376cfb4e3561e12`
- **Econia**: `0xc0deb00c405f84c85dc13442e305df75d9b58c5481e6824349a528b0b78d4bb5`

## 🧪 Testing Features

### 1. Wallet Connection
- Install Petra Wallet extension
- Click "Connect Petra Wallet" button
- Approve the connection

### 2. Token Swapping
1. **Select Input Token**: Choose APT or any supported token
2. **Enter Amount**: Input the amount you want to swap
3. **Select Output Token**: Choose your desired output token
4. **Review Quote**: Check the swap details and price impact
5. **Execute Swap**: Confirm the transaction

### 3. Cross-Address Swaps
- Toggle to "Cross Address" mode
- Enter receiver address
- Swap tokens to another wallet

### 4. Settings
- **Slippage Tolerance**: Adjust from 0.1% to custom values
- **Transaction Deadline**: Set custom deadline (default: 20 minutes)
- **MEV Protection**: Toggle on/off for MEV protection

## 🔌 API Endpoints

### Simulate Swap
```bash
POST /api/simulate-swap
Content-Type: application/json

{
  "inputToken": "0x1::aptos_coin::AptosCoin",
  "outputToken": "<output_token_address>",
  "inputAmount": "10000000"
}
```

Response:
```json
{
  "outputAmount": "9066108",
  "dexId": 1,
  "priceImpact": "1000",
  "fee": "30",
  "hops": 1,
  "route": ["0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8"]
}
```

## 🛠️ Development

### Environment Variables
Create a `.env.local` file:
```env
NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.mainnet.aptoslabs.com
NEXT_PUBLIC_AGGREGATOR_ADDRESS=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8
```

### Available Scripts
```bash
# Development
pnpm dev              # Start development server
pnpm build            # Build for production
pnpm start            # Start production server
pnpm lint             # Run ESLint
pnpm type-check       # Run TypeScript checks

# Smart Contract
cd aptos-multiswap-aggregator-v3
aptos move compile    # Compile contracts
aptos move test       # Run tests
aptos move publish    # Deploy contracts
```

### Smart Contract Development
```bash
cd aptos-multiswap-aggregator-v3

# Compile with specific address
aptos move compile --package-dir . --named-addresses aggregator=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8

# Deploy to mainnet
aptos move publish --profile mainnet --package-dir . --named-addresses aggregator=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8
```

## 📱 Mobile Features

- **Responsive Design**: Optimized for mobile devices
- **Touch-Friendly**: Large buttons and intuitive gestures
- **Mobile Menu**: Collapsible navigation for small screens
- **Quick Actions**: Easy access to common functions

## 🔒 Security Features

- **MEV Protection**: Built-in protection against front-running
- **Slippage Control**: Customizable slippage tolerance
- **Transaction Deadlines**: Prevent stuck transactions
- **Wallet Integration**: Secure wallet connection

## 🎨 UI/UX Features

- **Dark Theme**: Modern dark interface
- **Animations**: Smooth transitions and loading states
- **Real-time Updates**: Live price and balance updates
- **Error Handling**: Clear error messages and recovery options

## 📊 Analytics & Monitoring

- **Transaction History**: Track all your swaps
- **Price Charts**: Visual price data
- **Gas Estimation**: Real-time gas cost estimates
- **Performance Metrics**: Platform statistics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the docs folder
- **Issues**: Report bugs on GitHub
- **Discord**: Join our community
- **Email**: Contact support team

## 🚀 Deployment

### Frontend Deployment (Vercel)
```bash
# Build the project
pnpm build

# Deploy to Vercel
vercel --prod
```

### Smart Contract Deployment
See `DEPLOYMENT.md` for detailed deployment instructions.

---

**Happy Swapping! 🚀**

*Built with ❤️ on Aptos Blockchain*
