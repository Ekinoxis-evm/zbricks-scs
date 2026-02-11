# Skill: Contract Verification

> Verifying smart contracts on Blockscout, Etherscan/Basescan, and Sourcify so anyone can read and audit the source code on-chain.

## Why Verify

- Lets users read your contract code on the explorer
- Enables "Write Contract" UI for direct interaction
- Builds trust — verified = transparent
- Required for professional projects

## Blockscout (Primary for Base)

### Auto-verify during deployment

```bash
forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api/
```

### Manual verify after deployment

```bash
# Simple contract (no constructor args)
forge verify-contract <ADDRESS> src/HouseNFT.sol:HouseNFT \
  --chain-id 84532 \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api/

# Contract with constructor args
forge verify-contract <ADDRESS> src/AuctionFactory.sol:AuctionFactory \
  --chain-id 84532 \
  --constructor-args $(cast abi-encode "constructor(address,address)" $NFT $USDC) \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api/
```

### Blockscout URLs

| Network | Explorer | API |
|---------|----------|-----|
| Base Sepolia | `https://base-sepolia.blockscout.com` | `https://base-sepolia.blockscout.com/api/` |
| Base Mainnet | `https://base.blockscout.com` | `https://base.blockscout.com/api/` |

## Etherscan / Basescan

### Setup

1. Get free API key at [basescan.org](https://basescan.org)
2. Add to `.env`: `BASESCAN_API_KEY=your_key`

### Verify

```bash
# Auto-verify during deployment
forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Manual verify
forge verify-contract <ADDRESS> src/HouseNFT.sol:HouseNFT \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

# Check verification status
forge verify-check <GUID> \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY
```

### Etherscan URLs

| Network | Explorer |
|---------|----------|
| Base Sepolia | `https://sepolia.basescan.org` |
| Base Mainnet | `https://basescan.org` |

## Sourcify

No API key required. Uses metadata hash for full/partial match.

```bash
forge verify-contract <ADDRESS> src/HouseNFT.sol:HouseNFT \
  --chain-id 84532 \
  --verifier sourcify
```

### Match Types

| Type | Meaning |
|------|---------|
| **Full match** | Source + metadata hash match exactly |
| **Partial match** | Source matches, metadata differs (compiler settings, etc.) |

## Verification Strategy for ZBrick

```
1. Deploy with --verify --verifier blockscout     (auto, during deploy)
   ↓ if it fails
2. Run verify-contracts.sh                         (manual blockscout retry)
   ↓ optionally
3. Run verify-etherscan.sh                         (secondary on Basescan)
   ↓ optionally
4. forge verify-contract --verifier sourcify       (tertiary, no key needed)
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| "Already verified" | Contract was previously verified | Nothing to do, check explorer |
| Constructor args mismatch | Encoded args don't match deployment | Use `cast abi-encode` with exact values |
| Compiler version mismatch | Local vs explorer compiler differs | Ensure `foundry.toml` optimizer/via_ir matches |
| "Contract not found" | Wrong address or chain ID | Double-check address and `--chain-id` |
| Timeout on auto-verify | Explorer API slow | Retry manually with `forge verify-contract` |
| Proxy not showing source | Only implementation is verified | Use explorer's "Is this a proxy?" feature |

## Verification for Factory-Created Contracts

AuctionManager contracts are created by AuctionFactory, not deployed directly. To verify:

```bash
# Get the exact constructor args from the creation tx
# Then verify with those args
forge verify-contract <AUCTION_MANAGER_ADDRESS> \
  src/AuctionManager.sol:AuctionManager \
  --chain-id 84532 \
  --constructor-args $(cast abi-encode "constructor(address,address,address,uint256,uint256[4],uint256,uint256,bool,uint256,address)" ...) \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api/
```

Alternatively, if the factory is verified and uses `new`, Blockscout often auto-verifies child contracts.
