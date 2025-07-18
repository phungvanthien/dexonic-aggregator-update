# 🚀 Hướng dẫn thiết lập và chạy Dexonic Dex Aggregator

## 📋 Yêu cầu hệ thống

- **Node.js**: v18+ (khuyến nghị v20+)
- **npm**: v8+ hoặc **pnpm**: v8+
- **Aptos CLI**: v7.6.0+
- **Git**: để clone repository

## 🛠️ Cài đặt

### **Bước 1: Clone repository**
```bash
git clone <repository-url>
cd Dexonic Dex Aggregator
```

### **Bước 2: Cài đặt dependencies**
```bash
# Sử dụng pnpm (khuyến nghị)
pnpm install

# Hoặc sử dụng npm
npm install
```

### **Bước 3: Thiết lập Aptos CLI**
```bash
# Khởi tạo Aptos CLI với mainnet
aptos init --profile local
# Chọn "mainnet" khi được hỏi
```

### **Bước 4: Build dự án**
```bash
pnpm build
```

### **Bước 5: Chạy development server**
```bash
pnpm dev
```

## 🌐 Truy cập ứng dụng

Sau khi chạy thành công, bạn có thể truy cập:

- **Localhost**: http://localhost:3000
- **Network**: http://127.0.0.1:3000

## 📱 Các trang chính

### **🏠 Trang chủ** (`/`)
- Landing page với giới thiệu dự án
- Các tính năng chính
- Testimonials và FAQ

### **💱 Trang Swap** (`/swap`)
- Giao diện swap token
- Kết nối ví Petra
- Chọn token và nhập số lượng
- Xem quotes và thực hiện swap

### **💬 Trang Chat** (`/chat`)
- Real-time chat community
- Multiple chat rooms
- User profiles và stats

### **👤 Trang Profile** (`/profile`)
- Thông tin người dùng
- Transaction history
- User statistics

## 🔧 Cấu hình Smart Contracts

### **Deploy Smart Contracts**
```bash
# Di chuyển vào thư mục smart contracts
cd aptos-multiswap-aggregator-v3

# Compile contracts
aptos move compile

# Deploy contracts
aptos move publish

# Initialize aggregator
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::initialize
```

### **Test Smart Contracts**
```bash
# Test swap simulation
aptos move run --function-id <YOUR_ADDRESS>::multiswap_aggregator::simulate_swap \
  --type-args 0x1::aptos_coin::AptosCoin <YOUR_ADDRESS>::USDC::USDC \
  --args 10000000
```