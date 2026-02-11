# Skill: Environment Configuration & Secrets

> Managing private keys, API keys, and deployment parameters securely.

## File Structure

```
.env              # Actual secrets (NEVER committed)
.env.example      # Template with placeholders (committed)
.gitignore        # Must include .env
```

## `.env` Template

```bash
# === WALLET ===
PRIVATE_KEY=0x_your_private_key_here

# === NETWORK RPC ===
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_RPC_URL=https://mainnet.base.org

# === VERIFICATION ===
BASESCAN_API_KEY=your_basescan_api_key

# === DEPLOYED INFRASTRUCTURE (after Phase 1 deploy) ===
NFT_ADDRESS=0x_nft_address
FACTORY_ADDRESS=0x_factory_address

# === AUCTION CONFIG (for Phase 2: CreateAuction) ===
AUCTION_TREASURY=0x_gnosis_safe_address
AUCTION_ADMIN=0x_admin_address

# Metadata URIs (IPFS)
AUCTION_PHASE_0_URI=ipfs://Qm.../0.json
AUCTION_PHASE_1_URI=ipfs://Qm.../1.json
AUCTION_PHASE_2_URI=ipfs://Qm.../2.json
AUCTION_PHASE_3_URI=ipfs://Qm.../3.json

# Optional overrides (have defaults)
AUCTION_FLOOR_PRICE=10000000000000          # $10M in USDC (6 decimals)
AUCTION_PARTICIPATION_FEE=1000000000        # $1,000 in USDC
AUCTION_MIN_BID_INCREMENT=5                 # 5%
AUCTION_OPEN_DURATION=604800                # 7 days in seconds
AUCTION_BIDDING_DURATION=1209600            # 14 days
AUCTION_EXECUTION_PERIOD=2592000            # 30 days
```

## Reading in Forge Scripts

```solidity
uint256 deployerKey = vm.envUint("PRIVATE_KEY");
address treasury = vm.envAddress("AUCTION_TREASURY");
string memory uri = vm.envString("AUCTION_PHASE_0_URI");

// With defaults
uint256 floor = vm.envOr("AUCTION_FLOOR_PRICE", uint256(10_000_000e6));
```

## Reading in Shell Scripts

```bash
source .env
echo $PRIVATE_KEY  # Available as shell variable
```

## Security Rules

| Rule | Why |
|------|-----|
| `.env` in `.gitignore` | Never commit secrets |
| Use `.env.example` with placeholders | Document what's needed without exposing values |
| Treasury = multisig (Gnosis Safe) | No single point of failure for funds |
| Separate deployer from admin | Deployer key can be rotated after deployment |
| Never hardcode keys in scripts | Keys only come from env vars |
| Use different keys per chain | Compromise on testnet doesn't affect mainnet |

## Secrets Needed Per Role

| Role | Secrets Needed |
|------|---------------|
| Developer | `PRIVATE_KEY` (testnet), `BASE_SEPOLIA_RPC_URL` |
| Deployer | `PRIVATE_KEY` (mainnet), `BASE_RPC_URL`, `BASESCAN_API_KEY` |
| Operator | `PRIVATE_KEY` (admin), deployed addresses |
| Frontend | Deployed addresses + ABIs only (no secrets) |
