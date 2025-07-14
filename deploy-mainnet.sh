#!/bin/bash

# AptosSwap Mainnet Deployment Script
# This script will deploy the smart contract and build the frontend for mainnet

set -e

echo "🚀 Starting AptosSwap Mainnet Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Step 1: Clean build cache
print_status "Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache
rm -rf .swc

# Step 2: Install dependencies
print_status "Installing dependencies..."
pnpm install

# Step 3: Build smart contract
print_status "Building smart contract..."
cd aptos-multiswap-aggregator-v3

# Check if aptos CLI is installed
if ! command -v aptos &> /dev/null; then
    print_warning "Aptos CLI not found. Installing..."
    curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3
fi

# Compile the contract
aptos move compile --package-dir . --named-addresses aggregator=0x1

print_success "Smart contract compiled successfully"

# Step 4: Deploy to mainnet (requires user input)
print_warning "To deploy to mainnet, you need to:"
print_warning "1. Have a wallet with APT for gas fees"
print_warning "2. Configure your private key in aptos.config.toml"
print_warning "3. Run: aptos move publish --profile mainnet"

# Step 5: Build frontend for production
print_status "Building frontend for production..."
cd ..

# Copy mainnet environment
cp env.mainnet .env.local

# Build the application
pnpm build

print_success "Frontend built successfully for production"

# Step 6: Create deployment package
print_status "Creating deployment package..."
mkdir -p deployment
cp -r .next deployment/
cp -r public deployment/
cp package.json deployment/
cp next.config.mjs deployment/
cp .env.local deployment/

# Create deployment script
cat > deployment/start.sh << 'EOF'
#!/bin/bash
export NODE_ENV=production
pnpm install --prod
pnpm start
EOF

chmod +x deployment/start.sh

print_success "Deployment package created in ./deployment/"

# Step 7: Create deployment instructions
cat > DEPLOYMENT_INSTRUCTIONS.md << 'EOF'
# AptosSwap Mainnet Deployment Instructions

## Prerequisites
1. Aptos CLI installed
2. Wallet with APT for gas fees
3. Private key configured in aptos.config.toml

## Smart Contract Deployment

1. Navigate to the contract directory:
   ```bash
   cd aptos-multiswap-aggregator-v3
   ```

2. Configure your mainnet profile:
   ```bash
   aptos init --profile mainnet
   ```
   - Enter your private key
   - Use endpoint: https://fullnode.mainnet.aptoslabs.com

3. Deploy the contract:
   ```bash
   aptos move publish --profile mainnet
   ```

4. Note the deployed module address and update .env.local

## Frontend Deployment

### Option 1: Vercel (Recommended)
1. Push code to GitHub
2. Connect repository to Vercel
3. Set environment variables in Vercel dashboard
4. Deploy

### Option 2: Self-hosted
1. Upload deployment package to your server
2. Run: `cd deployment && ./start.sh`

### Option 3: Netlify
1. Push code to GitHub
2. Connect to Netlify
3. Set build command: `pnpm build`
4. Set publish directory: `.next`

## Environment Variables
Update .env.local with your contract addresses after deployment.

## Verification
1. Test wallet connection
2. Test swap functionality
3. Verify contract interactions
EOF

print_success "Deployment instructions created: DEPLOYMENT_INSTRUCTIONS.md"

# Step 8: Create quick deployment script
cat > quick-deploy.sh << 'EOF'
#!/bin/bash

# Quick deployment script for Vercel
echo "🚀 Quick Deploy to Vercel"

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "Installing Vercel CLI..."
    npm install -g vercel
fi

# Deploy to Vercel
echo "Deploying to Vercel..."
vercel --prod

echo "✅ Deployment complete!"
EOF

chmod +x quick-deploy.sh

print_success "Quick deployment script created: quick-deploy.sh"

echo ""
print_success "🎉 AptosSwap Mainnet Deployment Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Configure your private key in aptos.config.toml"
echo "2. Deploy smart contract: cd aptos-multiswap-aggregator-v3 && aptos move publish --profile mainnet"
echo "3. Update contract addresses in .env.local"
echo "4. Deploy frontend: ./quick-deploy.sh (for Vercel) or follow DEPLOYMENT_INSTRUCTIONS.md"
echo ""
echo "For detailed instructions, see: DEPLOYMENT_INSTRUCTIONS.md" 