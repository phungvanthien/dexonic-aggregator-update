# AptosSwap Mainnet Deployment Guide

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)
```bash
# Build and prepare for deployment
./deploy-simple.sh

# Deploy smart contract to mainnet
./deploy-contract.sh

# Deploy frontend to Vercel
./deploy-vercel.sh
```

### Option 2: Manual Deployment
Follow the detailed steps below.

---

## 📋 Prerequisites

1. **Aptos CLI** - For smart contract deployment
2. **Node.js & pnpm** - For frontend build
3. **Vercel account** - For frontend hosting (optional)
4. **APT tokens** - For gas fees (recommended: 1-2 APT)

---

## 🔧 Smart Contract Deployment

### Step 1: Install Aptos CLI
```bash
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3
```

### Step 2: Prepare Wallet
1. Create a new wallet or use existing one
2. Ensure you have APT for gas fees
3. Get your private key ready

### Step 3: Configure Mainnet Profile
```bash
cd aptos-multiswap-aggregator-v3
aptos init --profile mainnet --network mainnet
```
- Enter your private key when prompted
- Use endpoint: `https://fullnode.mainnet.aptoslabs.com`

### Step 4: Deploy Contract
```bash
# Compile
aptos move compile --package-dir . --named-addresses aggregator=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8

# Deploy
aptos move publish --profile mainnet --package-dir . --named-addresses aggregator=0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8
```

### Step 5: Get Contract Address
```bash
aptos account list --profile mainnet
```
Note the deployed module address for the next step.

---

## 🌐 Frontend Deployment

### Option A: Vercel (Recommended)

#### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

#### Step 2: Login to Vercel
```bash
vercel login
```

#### Step 3: Deploy
```bash
./deploy-vercel.sh
```

#### Step 4: Configure Environment Variables
In Vercel dashboard:
1. Go to your project settings
2. Add environment variables:
   - `NEXT_PUBLIC_APTOS_NETWORK=mainnet`
   - `NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.mainnet.aptoslabs.com/v1`
   - `NEXT_PUBLIC_AGGREGATOR_CONTRACT=<your_deployed_contract_address>`

### Option B: Self-Hosted

#### Step 1: Build Application
```bash
./deploy-simple.sh
```

#### Step 2: Upload to Server
```bash
# Upload deployment folder to your server
scp -r deployment/ user@your-server:/path/to/app/

# SSH into server and start
ssh user@your-server
cd /path/to/app
chmod +x start.sh
./start.sh
```

### Option C: Netlify

#### Step 1: Push to GitHub
```bash
git add .
git commit -m "Deploy to mainnet"
git push origin main
```

#### Step 2: Connect to Netlify
1. Go to [netlify.com](https://netlify.com)
2. Connect your GitHub repository
3. Set build command: `pnpm build`
4. Set publish directory: `.next`
5. Add environment variables in Netlify dashboard

---

## ⚙️ Environment Configuration

### Update .env.local
```bash
# Copy mainnet environment
cp env.mainnet .env.local

# Edit with your contract addresses
nano .env.local
```

### Required Environment Variables
```env
NEXT_PUBLIC_APTOS_NETWORK=mainnet
NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.mainnet.aptoslabs.com/v1
NEXT_PUBLIC_AGGREGATOR_CONTRACT=<your_contract_address>
NEXT_PUBLIC_LIQUIDSWAP_CONTRACT=0x190d44266241744264b964a37b8f09863167a12d3e70cda39376cfb4e3561e12
NEXT_PUBLIC_ECONIA_CONTRACT=0xc0deb00c405f84c85dc13442e305df75d9b58c5481e6824349a528b0b78d4bb5
```

---

## 🧪 Testing

### 1. Test Wallet Connection
- Connect Petra wallet
- Connect Pontem wallet
- Verify wallet detection

### 2. Test Swap Functionality
- Try swapping small amounts
- Test different tokens
- Verify transaction success

### 3. Test Contract Integration
- Check contract calls
- Verify gas estimation
- Test error handling

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Contract Deployment Fails
- Check APT balance
- Verify private key
- Check network connectivity

#### 2. Frontend Build Fails
```bash
# Clean and rebuild
rm -rf .next
rm -rf node_modules/.cache
pnpm install
pnpm build
```

#### 3. Wallet Connection Issues
- Check browser console for errors
- Verify wallet extension is installed
- Check network configuration

#### 4. Environment Variables Not Loading
- Restart development server
- Check .env.local file
- Verify variable names

---

## 📊 Monitoring

### 1. Contract Monitoring
- Monitor contract transactions
- Check gas usage
- Track contract interactions

### 2. Frontend Monitoring
- Monitor user interactions
- Track error rates
- Monitor performance

### 3. Network Monitoring
- Monitor Aptos network status
- Check RPC endpoint health
- Track transaction success rates

---

## 🔒 Security Considerations

### 1. Private Key Security
- Never commit private keys to git
- Use environment variables
- Consider hardware wallets for large amounts

### 2. Contract Security
- Audit smart contract code
- Test thoroughly on testnet
- Monitor for vulnerabilities

### 3. Frontend Security
- Use HTTPS in production
- Implement proper CORS
- Sanitize user inputs

---

## 📈 Post-Deployment

### 1. Documentation
- Update README.md
- Document deployment process
- Create user guides

### 2. Monitoring Setup
- Set up error tracking
- Configure analytics
- Monitor performance

### 3. Community
- Announce launch
- Share documentation
- Gather feedback

---

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section
2. Review console logs
3. Test on testnet first
4. Check Aptos network status
5. Verify wallet configuration

---

## 📝 Checklist

- [ ] Aptos CLI installed
- [ ] Wallet with APT configured
- [ ] Smart contract deployed
- [ ] Contract address noted
- [ ] Frontend built successfully
- [ ] Environment variables configured
- [ ] Frontend deployed
- [ ] Wallet connection tested
- [ ] Swap functionality tested
- [ ] Error handling verified
- [ ] Documentation updated

---

**🎉 Congratulations! Your AptosSwap is now live on mainnet!** 