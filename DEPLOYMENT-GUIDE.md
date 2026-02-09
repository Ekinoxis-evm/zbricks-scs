# ZBrick Deployment Guide

Clean, streamlined deployment process for the ZBrick auction system on Base networks.

---

## 🚀 Quick Start

### Before You Begin

```bash
# 1. Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2. Setup environment
cp .env.example .env
# Edit .env and add your PRIVATE_KEY

# 3. Compile contracts
forge build

# 4. Get testnet ETH
# Visit: https://coinbase.com/faucets/base-ethereum-goerli-faucet
```

---

## 📋 The 4 Essential Scripts

### 1️⃣ Deploy Infrastructure (Once Per Network)

**Deploy shared contracts:** HouseNFT + AuctionFactory

```bash
# Deploy to Base Sepolia (testnet)
./script/deploy-and-verify.sh base-sepolia

# Deploy to Base Mainnet (production)
./script/deploy-and-verify.sh base
```

**What happens:**
- ✅ HouseNFT contract deployed ("ZBRICKS" collection)
- ✅ AuctionFactory contract deployed
- ✅ Both automatically verified on Blockscout
- ✅ Factory set as trusted in NFT contract

**Save the addresses to `.env`:**
```bash
# Copy addresses from the output
NFT_ADDRESS=0x...
FACTORY_ADDRESS=0x...
```

---

### 2️⃣ Create Auction (Per Property)

**Deploy individual auction for each property**

**Configure in `.env`:**
```bash
# Required - Treasury and Metadata
AUCTION_TREASURY=0xYourGnosisSafeAddress
AUCTION_PHASE_0_URI=ipfs://QmYourPhase0Hash
AUCTION_PHASE_1_URI=ipfs://QmYourPhase1Hash
AUCTION_PHASE_2_URI=ipfs://QmYourPhase2Hash
AUCTION_PHASE_3_URI=ipfs://QmYourPhase3Hash

# Optional - Has Defaults (see Configuration Reference below)
AUCTION_FLOOR_PRICE=10000000000000        # Default: $10M
AUCTION_PARTICIPATION_FEE=1000000000      # Default: $1,000
AUCTION_MIN_BID_INCREMENT=5               # Default: 5%
AUCTION_OPEN_DURATION=604800              # Default: 7 days
AUCTION_BIDDING_DURATION=1209600          # Default: 14 days
AUCTION_EXECUTION_PERIOD=2592000          # Default: 30 days
```

**Run:**
```bash
# Base Sepolia
forge script script/CreateAuction.s.sol:CreateAuction \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  -vvvv

# Base Mainnet
forge script script/CreateAuction.s.sol:CreateAuction \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  -vvvv
```

**What happens:**
- ✅ New NFT minted with auto-incrementing token ID
- ✅ Phase metadata URIs set on NFT
- ✅ AuctionManager deployed for this property
- ✅ NFT transferred to auction contract
- ✅ Auction ready for bidding

---

### 3️⃣ Extract ABIs & Addresses

**Get contract ABIs and deployment addresses for frontend**

```bash
# Extract only ABIs (works before deployment!)
node script/extractDeployment.js abi

# Extract all networks (ABIs + addresses)
node script/extractDeployment.js all

# Extract specific network
node script/extractDeployment.js 84532  # Base Sepolia
node script/extractDeployment.js 8453   # Base Mainnet
```

**Generates:**
```
deployments/
├── abi/
│   ├── HouseNFT.json           # NFT contract ABI
│   ├── AuctionFactory.json     # Factory contract ABI
│   └── AuctionManager.json     # Auction contract ABI
├── addresses.json              # All deployments by chain
└── README.md                   # Integration guide
```

**Frontend usage:**
```javascript
const addresses = require('./deployments/addresses.json');
const auctionAbi = require('./deployments/abi/AuctionManager.json');

// Get contract for Base Sepolia
const chainId = '84532';
const auctionAddress = addresses[chainId].contracts.AuctionManager;

// Use with ethers.js or viem
const contract = new ethers.Contract(auctionAddress, auctionAbi, provider);
```

**💡 Pro Tip:** Run `node script/extractDeployment.js abi` anytime after `forge build` to get ABIs - no deployment needed!

---

### 4️⃣ Verify Contracts (If Needed)

**Re-verify contracts if auto-verification failed**

```bash
# Base Sepolia
./script/verify-contracts.sh base-sepolia

# Base Mainnet
./script/verify-contracts.sh base
```

**When to use:**
- Auto-verification timeout during deployment
- Want to re-verify with updated source
- Verification failed due to network issues

---

## 🔄 Complete Workflows

### First Deployment (Testnet)

```bash
# 1. Setup
cp .env.example .env
# Add PRIVATE_KEY to .env

# 2. Compile
forge build

# 3. Extract ABIs (optional - for frontend development)
node script/extractDeployment.js abi

# 4. Deploy infrastructure
./script/deploy-and-verify.sh base-sepolia

# 5. Save addresses to .env
NFT_ADDRESS=0x...
FACTORY_ADDRESS=0x...

# 6. Configure auction in .env
AUCTION_TREASURY=0x...
AUCTION_PHASE_0_URI=ipfs://Qm...
AUCTION_PHASE_1_URI=ipfs://Qm...
AUCTION_PHASE_2_URI=ipfs://Qm...
AUCTION_PHASE_3_URI=ipfs://Qm...

# 7. Create first auction
forge script script/CreateAuction.s.sol:CreateAuction \
  --rpc-url https://sepolia.base.org \
  --broadcast

# 8. Extract deployment data
node script/extractDeployment.js all
```

---

### Adding More Properties

```bash
# 1. Update .env with new property metadata
AUCTION_PHASE_0_URI=ipfs://QmNewProperty...
AUCTION_PHASE_1_URI=ipfs://QmNewProperty...
AUCTION_PHASE_2_URI=ipfs://QmNewProperty...
AUCTION_PHASE_3_URI=ipfs://QmNewProperty...

# 2. Create auction (reuses existing infrastructure)
forge script script/CreateAuction.s.sol:CreateAuction \
  --rpc-url https://sepolia.base.org \
  --broadcast

# 3. Update frontend data
node script/extractDeployment.js all
```

---

### Production Deployment

```bash
# 1. Deploy infrastructure to mainnet
./script/deploy-and-verify.sh base

# 2. Update .env with mainnet addresses
NFT_ADDRESS=0x...
FACTORY_ADDRESS=0x...

# 3. Configure production auction
AUCTION_TREASURY=0xYourProductionGnosisSafe
AUCTION_PHASE_0_URI=ipfs://Qm...
# ... set all phase URIs

# 4. Create auction
forge script script/CreateAuction.s.sol:CreateAuction \
  --rpc-url https://mainnet.base.org \
  --broadcast

# 5. Extract for production frontend
node script/extractDeployment.js 8453
```

---

---

## ⚙️ Configuration Reference

### USDC Amounts (6 decimals)
```
$1,000      = 1000000000       (1,000 × 10⁶)
$100,000    = 100000000000     (100,000 × 10⁶)
$1,000,000  = 1000000000000    (1,000,000 × 10⁶)
$10,000,000 = 10000000000000   (10,000,000 × 10⁶)
```

### Time Durations (seconds)
```
1 day   = 86400
7 days  = 604800
14 days = 1209600
30 days = 2592000
```

### Supported Networks
```
base-sepolia  # Base Sepolia Testnet (Chain ID: 84532)
base          # Base Mainnet (Chain ID: 8453)
```

### Default Auction Parameters

| Parameter | Default Value | Description |
|-----------|--------------|-------------|
| `AUCTION_FLOOR_PRICE` | `10000000000000` | $10M minimum bid |
| `AUCTION_PARTICIPATION_FEE` | `1000000000` | $1,000 entry fee |
| `AUCTION_MIN_BID_INCREMENT` | `5` | 5% minimum increase |
| `AUCTION_OPEN_DURATION` | `604800` | 7 days (Phase 0) |
| `AUCTION_BIDDING_DURATION` | `1209600` | 14 days (Phase 1) |
| `AUCTION_EXECUTION_PERIOD` | `2592000` | 30 days (Phase 2) |

**Note:** Only set in `.env` if you want to override defaults.

---

## 🛠️ Admin Operations

After auction deployment, manage via contract interactions:

```solidity
// Advance to next phase (after minimum duration)
auctionManager.advancePhase();

// Finalize auction (after phase 2 complete)
auctionManager.finalizeAuction();

// Withdraw winning bid to treasury
auctionManager.withdrawProceeds();

// Emergency controls (admin only)
auctionManager.pause();
auctionManager.unpause();
auctionManager.emergencyWithdrawNFT();
auctionManager.emergencyWithdrawFunds();
```

**Interaction methods:**
- **Blockscout:** Use "Write Contract" tab on verified contracts
- **Foundry:** `cast send <contract> "<function>" --rpc-url <url> --private-key <key>`
- **Gnosis Safe:** Recommended for production (multi-sig security)
- **Frontend:** Build admin dashboard for your team

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| **"PRIVATE_KEY not set"** | Add to `.env`: `PRIVATE_KEY=0x...` |
| **"NFT_ADDRESS not set"** | Deploy infrastructure first (Step 1) |
| **"Verification failed"** | Wait 30s, then run `./script/verify-contracts.sh <network>` |
| **"Treasury must be set"** | Add to `.env`: `AUCTION_TREASURY=0x...` |
| **"Phase URI must be set"** | Upload metadata to IPFS, add all 4 URIs to `.env` |
| **"Insufficient funds"** | Fund wallet with ETH for gas fees |
| **"Contract must own NFT"** | Factory transfers NFT atomically - check factory is trusted |
| **"export: not valid"** | Fix `.env` format - use `.env.example` as template |

### Common `.env` Mistakes

✅ **Correct:**
```bash
PRIVATE_KEY=0xabc123
AUCTION_TREASURY=0x1234567890
```

❌ **Incorrect:**
```bash
PRIVATE_KEY="0xabc123"      # No quotes
export PRIVATE_KEY=0xabc123  # No export keyword
PRIVATE_KEY = 0xabc123       # No spaces around =
```

---

## 📊 Deployment Checklist

### Before Mainnet Deployment

- [ ] Tested full auction flow on Base Sepolia
- [ ] Verified all contracts on block explorer
- [ ] Treasury is Gnosis Safe (not EOA)
- [ ] All phase metadata uploaded to IPFS/Arweave
- [ ] Confirmed metadata URIs are accessible
- [ ] Reviewed auction parameters (floor price, fees, durations)
- [ ] Admin wallet is secure (hardware wallet recommended)
- [ ] Emergency procedures documented
- [ ] Team trained on admin operations

### Post-Deployment

- [ ] Extracted ABIs and addresses for frontend
- [ ] Verified contracts on Blockscout
- [ ] Tested admin functions (advance phase, etc.)
- [ ] Set up monitoring for auction events
- [ ] Configured alerts for treasury transactions
- [ ] Documented all deployed addresses
- [ ] Backed up deployment artifacts

---

## 📚 Additional Resources

- **[README.md](README.md)** - Complete project overview and features
- **[CONTRACT-REFERENCE.md](CONTRACT-REFERENCE.md)** - Full contract API documentation
- **[AUCTION-FLOW.md](AUCTION-FLOW.md)** - Detailed auction mechanics guide
- **[.env.example](.env.example)** - Configuration template with all options

---

## 💡 Tips & Best Practices

### Development
- Use Base Sepolia for testing - it's free and fast
- Run `forge test` before every deployment
- Keep deployment logs for audit trail
- Version control your `.env.example` (never `.env`!)

### Production
- Always use Gnosis Safe as treasury
- Set admin to multisig for security
- Start with conservative phase durations
- Monitor auction events in real-time
- Have emergency procedures ready

### Frontend Integration
- Extract ABIs early with `node script/extractDeployment.js abi`
- ABIs are the same across all networks
- Use chain ID to select correct addresses
- Cache contract instances per chain
- Handle network switching gracefully

---

**Questions?** Check the main [README.md](README.md) for detailed documentation or open an issue on GitHub.
