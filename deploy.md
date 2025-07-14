# AptosSwap Smart Contract Deployment

## Deployment Information

**Deployment Date**: January 2025  
**Network**: Aptos Mainnet  
**Deployment Status**: ✅ Successfully Deployed  

## Smart Contract Addresses

### Main Contracts
- **Aggregator Contract**: `0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::multiswap_aggregator_v2`
- **AptosDoge Token**: `0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::aptosdoge::AptosDoge`

### Admin Wallet
- **Admin Address**: `0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8`
- **Receiver Address**: `0xed401eb09b9b70ba2b258f979534cbe1766b035b7ec67d9636a121099751a16a`

## Contract Functions

### Aggregator Functions
- `initialize()` - Initialize the aggregator
- `simulate_swap()` - Simulate token swaps
- `execute_swap()` - Execute token swaps
- `setup_default_pools()` - Setup default liquidity pools
- `get_config()` - Get aggregator configuration

### AptosDoge Token Functions
- `initialize()` - Initialize the AptosDoge token
- `mint()` - Mint new tokens (admin only)
- `transfer()` - Transfer tokens between addresses

## Integration Details

### Frontend Configuration
The frontend is configured to use these contract addresses:
- Aggregator: `0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8`
- API Endpoint: `/api/simulate-swap`

### Environment Variables
```env
NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.mainnet.aptoslabs.com
NEXT_PUBLIC_AGGREGATOR_ADDRESS=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8
```

## Verification Links

- **Aptos Explorer**: https://explorer.aptoslabs.com/account/0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8?network=mainnet
- **Contract Source**: Available in `aptos-multiswap-aggregator-v3/sources/`

## Deployment Commands Used

```bash
# Compile contracts
aptos move compile --package-dir . --named-addresses aggregator=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8

# Deploy to mainnet
aptos move publish --profile mainnet --package-dir . --named-addresses aggregator=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8
```

## Supported Tokens

| Token | Symbol | Address | Decimals |
|-------|--------|---------|----------|
| Aptos Coin | APT | `0x1::aptos_coin::AptosCoin` | 8 |
| AptosDoge | APDOGE | `0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::aptosdoge::AptosDoge` | 8 |
| USD Coin | USDC | `0xa2eda21a58856fda86451436513b867c97eecb4ba099da5775520e0f7492e852::coin::T` | 6 |
| Tether USD | USDT | `0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b::coin::T` | 6 |
| Wrapped ETH | WETH | `0xcc8a89c8dce9693d354449f1f73e60e14e347417854f029db5bc8e7454008abb::coin::T` | 8 |

## DEX Integration

- **Liquidswap**: `0x190d44266241744264b964a37b8f09863167a12d3e70cda39376cfb4e3561e12`
- **Econia**: `0xc0deb00c405f84c85dc13442e305df75d9b58c5481e6824349a528b0b78d4bb5`

## Testing Commands

```bash
# Check contract configuration
aptos move view --function-id 0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::multiswap_aggregator_v2::get_config

# Simulate swap
aptos move view --function-id 0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::multiswap_aggregator_v2::simulate_swap --type-args 0x1::aptos_coin::AptosCoin 0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::aptosdoge::AptosDoge --args "u64:10000000"
```

## Notes

- The contracts are deployed on Aptos mainnet
- Admin functions require the admin wallet to be connected
- All transactions require APT for gas fees
- The aggregator supports cross-address swaps
- Real-time price quotes are available through the API

---

**Deployment completed successfully! 🚀** 