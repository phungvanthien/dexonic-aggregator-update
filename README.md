# Aptos DEX Aggregator

A decentralized exchange (DEX) aggregator built on Aptos that finds the best swap routes across multiple DEXs with multi-hop routing support.

## Features

- **Multi-DEX Aggregation**: Supports multiple DEXs including Liquidswap and Econia
- **Multi-Hop Routing**: Finds optimal routes through intermediate tokens
- **Slippage Protection**: Configurable slippage tolerance
- **Quote Caching**: Caches quotes for better performance
- **Admin Controls**: Pausable contracts with admin functions
- **Event System**: Comprehensive event logging for tracking

## Architecture

The aggregator consists of two main modules:

1. **`multiswap_aggregator`**: Main aggregator logic with routing and swap execution
2. **`aptosdoge`**: Example token for testing (AptosDoge)

### Key Components

- **AggregatorConfig**: Configuration settings for fees, slippage, and supported DEXs
- **DEXRegistry**: Registry of pools and markets from different DEXs
- **QuoteCache**: Cached quotes for performance optimization
- **SwapEvents**: Event system for tracking swaps and quotes

## Prerequisites

1. **Aptos CLI**: Install the Aptos CLI
   ```bash
   curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3
   ```

2. **Initialize Aptos Account**: Set up your Aptos account
   ```bash
   aptos init
   ```

## Quick Start

### 1. Clone and Navigate
```bash
cd aptos-multiswap-aggregator
```

### 2. Deploy Contracts (Windows)
```bash
deploy.bat
```

### 3. Deploy Contracts (Linux/Mac)
```bash
chmod +x deploy.sh
./deploy.sh
```

### 4. Manual Deployment
If you prefer manual deployment:

```bash
# Compile contracts
aptos move compile

# Deploy contracts
aptos move publish

# Initialize aggregator
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::initialize

# Initialize AptosDoge token
aptos move run --function-id <YOUR_ADDRESS>::aptosdoge::initialize

# Setup default pools
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::setup_default_pools

# Mint AptosDoge for testing
aptos move run --function-id <YOUR_ADDRESS>::aptosdoge::mint --args <YOUR_ADDRESS> 1000000000
```

## Usage

### Simulate a Swap
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::simulate_swap \
  --type-args 0x1::aptos_coin::AptosCoin <YOUR_ADDRESS>::aptosdoge::AptosDoge \
  --args 10000000
```

### Execute a Swap
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::swap_exact_input \
  --type-args 0x1::aptos_coin::AptosCoin <YOUR_ADDRESS>::aptosdoge::AptosDoge \
  --args "u64:0" "u64:10000000" "u64:18446744073709551615"
```

### Get Quote Details
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::get_quote_details \
  --type-args 0x1::aptos_coin::AptosCoin <YOUR_ADDRESS>::aptosdoge::AptosDoge \
  --args 10000000
```

## Configuration

### Default Settings
- **Platform Fee**: 0.3% (30 basis points)
- **Max Slippage**: 5% (500 basis points)
- **Quote Cache Duration**: 5 minutes
- **Max Route Hops**: 3
- **Min Liquidity Threshold**: 1,000

### Update Configuration
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::update_config \
  --args <FEE_RECIPIENT> <PLATFORM_FEE> <MAX_SLIPPAGE> <CACHE_DURATION> <MAX_HOPS> <MIN_LIQUIDITY>
```

## Admin Functions

### Pause/Unpause
```bash
# Pause
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::pause

# Unpause
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::unpause
```

### Add Supported Token
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::add_supported_token \
  --args <TOKEN_ADDRESS>
```

### Add Liquidswap Pool
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::add_liquidswap_pool \
  --args <POOL_KEY> <LIQUIDITY> <FEE>
```

### Add Econia Market
```bash
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::add_econia_market \
  --args <MARKET_KEY> <LIQUIDITY> <FEE> <MARKET_ID>
```

## Testing

### Run Tests
```bash
aptos move test
```

### Test Specific Functions
```bash
# Test swap simulation
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::simulate_swap \
  --type-args 0x1::aptos_coin::AptosCoin <YOUR_ADDRESS>::aptosdoge::AptosDoge \
  --args 10000000

# Test actual swap
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::swap_exact_input \
  --type-args 0x1::aptos_coin::AptosCoin <YOUR_ADDRESS>::aptosdoge::AptosDoge \
  --args "u64:0" "u64:10000000" "u64:18446744073709551615"
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 1 | E_NOT_ADMIN | Only admin can perform this action |
| 2 | E_INSUFFICIENT_AMOUNT | Input amount is insufficient |
| 3 | E_SLIPPAGE_EXCEEDED | Slippage tolerance exceeded |
| 4 | E_INVALID_DEX | Invalid DEX identifier |
| 5 | E_SWAP_FAILED | Swap execution failed |
| 6 | E_POOL_NOT_FOUND | No pool found for token pair |
| 7 | E_DEADLINE_EXCEEDED | Transaction deadline exceeded |
| 8 | E_INVALID_ROUTE | Invalid swap route |
| 9 | E_QUOTE_EXPIRED | Quote has expired |
| 10 | E_INSUFFICIENT_LIQUIDITY | Insufficient liquidity in pool |
| 11 | E_MAX_HOPS_EXCEEDED | Route exceeds maximum hops |

## Development

### Project Structure
```
aptos-multiswap-aggregator/
├── sources/
│   ├── aggregator.move      # Main aggregator logic
│   └── aptosdoge.move       # Example token
├── tests/
│   └── aggregator_test.move # Test cases
├── scripts/
│   └── deploy_and_setup.ts  # Deployment script
├── Move.toml                # Move package configuration
├── aptos.config.toml        # Aptos configuration
├── deploy.bat              # Windows deployment script
├── deploy.sh               # Linux/Mac deployment script
└── README.md               # This file
```

### Adding New DEXs

1. Add DEX identifier constant
2. Implement quote function (`get_<dex>_quote`)
3. Implement swap execution function (`execute_<dex>_swap`)
4. Add to supported DEXs list in configuration

### Adding New Tokens

1. Create token module following `aptosdoge.move` pattern
2. Add token to supported tokens list
3. Create pools/markets for the token

## Security Considerations

- **Admin Controls**: Only deployer can call admin functions
- **Pausable**: Contracts can be paused in emergency
- **Slippage Protection**: Configurable slippage tolerance
- **Deadline Protection**: Transactions expire after deadline
- **Input Validation**: All inputs are validated

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions and support:
- Create an issue on GitHub
- Check the Aptos documentation: https://aptos.dev/
- Join the Aptos Discord: https://discord.gg/aptos

## 🔮 Roadmap

- [ ] Integration with additional DEXs
- [ ] Cross-chain bridging support
- [ ] Advanced order types (limit orders, stop-loss)
- [ ] MEV protection
- [ ] Mobile SDK
- [ ] Analytics dashboard
- [ ] Governance token integration

## 📁 Project Structure

\`\`\`
aptos-multiswap-aggregator/
├── Move.toml                    # Move package configuration
├── README.md                    # This file
├── sources/
│   └── aggregator.move         # Main aggregator smart contract
├── scripts/
│   └── simulate_best_path.ts   # TypeScript simulation and testing
├── tests/
│   └── aggregator_test.move    # Move unit tests
├── examples/
│   └── user_swap_example.move  # Example usage scripts
├── .aptos/
│   └── config.yaml            # Aptos CLI configuration
└── aptos.config.toml          # Project configuration
\`\`\`

## 🛠️ Installation & Setup

### Prerequisites

1. **Aptos CLI**: Install from [Aptos Labs](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli)
2. **Node.js**: Version 16+ for TypeScript scripts
3. **Move**: Comes with Aptos CLI

### Setup Steps

1. **Clone and Navigate**:
   \`\`\`bash
   cd aptos-multiswap-aggregator
   \`\`\`

2. **Initialize Aptos Account**:
   \`\`\`bash
   aptos init
   \`\`\`

3. **Install Dependencies**:
   \`\`\`bash
   npm install aptos
   \`\`\`

4. **Compile Move Code**:
   \`\`\`bash
   aptos move compile
   \`\`\`

5. **Run Tests**:
   \`\`\`bash
   aptos move test
   \`\`\`

## 🔧 Smart Contract Functions

### Core Functions

- `initialize(admin: &signer)`: Initialize the aggregator
- `get_best_quote<InputCoin, OutputCoin>(input_amount: u64)`: Get best quote across DEXs
- `swap_exact_input<InputCoin, OutputCoin>(...)`: Execute swap with best rate
- `simulate_swap<InputCoin, OutputCoin>(input_amount: u64)`: Simulate swap without execution

### Admin Functions

- `update_config(...)`: Update platform configuration
- `pause(admin: &signer)`: Pause the contract
- `unpause(admin: &signer)`: Unpause the contract

### View Functions

- `get_config()`: Get current configuration
- `simulate_swap(...)`: Preview swap results

## 💱 Usage Examples

### Basic Swap

```move
use aggregator::multiswap_aggregator;

// Swap 1 APT for USDC with 1% slippage tolerance
multiswap_aggregator::swap_exact_input<AptosCoin, USDC>(
    &user,
    100000000, // 1 APT
    99000000,  // Min 99 USDC (1% slippage)
    deadline
);
