#!/bin/bash

# Verify already deployed contracts with multiple verifiers:
# - Blockscout (open-source blockchain explorer)
# - Basescan/Etherscan (official Etherscan API)
# - Sourcify (decentralized contract verification)
#
# Usage: ./script/verify-etherscan.sh <network>

# Load .env file if it exists
if [ -f .env ]; then
    echo "📄 Loading environment from .env file..."
    # Export only valid variable assignments, stripping inline comments
    export $(grep -v '^#' .env | sed 's/#.*//' | grep '=' | xargs)
fi

NETWORK=$1

if [ -z "$NETWORK" ]; then
    echo "❌ Error: Network not specified"
    echo ""
    echo "Usage: ./script/verify-etherscan.sh <network>"
    echo ""
    echo "Supported networks:"
    echo "  base-sepolia  - Base Sepolia Testnet"
    echo "  base          - Base Mainnet"
    echo ""
    exit 1
fi

# Set RPC URL and verifier endpoints based on network
case $NETWORK in
    base-sepolia)
        RPC_URL="https://sepolia.base.org"
        BLOCKSCOUT_URL="https://base-sepolia.blockscout.com/api/"
        ETHERSCAN_API_URL="https://api-sepolia.basescan.org/api"
        CHAIN_ID=84532
        ;;
    base)
        RPC_URL="https://mainnet.base.org"
        BLOCKSCOUT_URL="https://base.blockscout.com/api/"
        ETHERSCAN_API_URL="https://api.basescan.org/api"
        CHAIN_ID=8453
        ;;
    *)
        echo "❌ Error: Unknown network: $NETWORK"
        exit 1
        ;;
esac

echo "🔍 Multi-Verifier Contract Verification for $NETWORK"
echo "=================================================================="
echo "Network: $NETWORK"
echo "RPC URL: $RPC_URL"
echo "Chain ID: $CHAIN_ID"
echo "=================================================================="
echo ""

# Check for deployment file
DEPLOYMENT_FILE="broadcast/DeployFactory.s.sol/$CHAIN_ID/run-latest.json"

if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "❌ Error: Deployment file not found: $DEPLOYMENT_FILE"
    echo "Deploy contracts first using: ./script/deploy-and-verify.sh $NETWORK"
    exit 1
fi

echo "📄 Using deployment file: $DEPLOYMENT_FILE"
echo ""

# Check for private key
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY environment variable not set"
    echo "Set it in .env file or export PRIVATE_KEY=your_private_key"
    exit 1
fi

# Extract contract addresses from deployment file
HOUSENFT_ADDRESS=$(jq -r '.transactions[] | select(.contractName == "HouseNFT") | .contractAddress' $DEPLOYMENT_FILE | head -1)
FACTORY_ADDRESS=$(jq -r '.transactions[] | select(.contractName == "AuctionFactory") | .contractAddress' $DEPLOYMENT_FILE | head -1)

echo "📋 Contracts to verify:"
echo "  HouseNFT: $HOUSENFT_ADDRESS"
echo "  AuctionFactory: $FACTORY_ADDRESS"
echo ""

# Track verification results
BLOCKSCOUT_SUCCESS=false
ETHERSCAN_SUCCESS=false
SOURCIFY_SUCCESS=false

echo "=================================================================="
echo "1️⃣  VERIFYING WITH BLOCKSCOUT"
echo "=================================================================="
echo ""

# Verify with Blockscout
if forge script script/DeployFactory.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --resume \
    --verify \
    --verifier blockscout \
    --verifier-url $BLOCKSCOUT_URL \
    -vv 2>&1 | tee /tmp/blockscout_verify.log; then
    BLOCKSCOUT_SUCCESS=true
    echo "✅ Blockscout verification completed"
else
    echo "⚠️  Blockscout verification had issues (may already be verified)"
fi

echo ""
echo "=================================================================="
echo "2️⃣  VERIFYING WITH BASESCAN (ETHERSCAN)"
echo "=================================================================="
echo ""

# Check for API key
if [ -z "$BASESCAN_API_KEY" ] && [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "⚠️  Warning: BASESCAN_API_KEY or ETHERSCAN_API_KEY not set in .env"
    echo "Skipping Etherscan verification..."
else
    # Use BASESCAN_API_KEY if set, otherwise fall back to ETHERSCAN_API_KEY
    API_KEY="${BASESCAN_API_KEY:-$ETHERSCAN_API_KEY}"
    
    if forge script script/DeployFactory.s.sol \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --resume \
        --verify \
        --etherscan-api-key $API_KEY \
        -vv 2>&1 | tee /tmp/etherscan_verify.log; then
        ETHERSCAN_SUCCESS=true
        echo "✅ Basescan/Etherscan verification completed"
    else
        echo "⚠️  Basescan/Etherscan verification had issues (may already be verified)"
    fi
fi

echo ""
echo "=================================================================="
echo "3️⃣  VERIFYING WITH SOURCIFY"
echo "=================================================================="
echo ""

# Verify with Sourcify (decentralized verification)
if [ -n "$HOUSENFT_ADDRESS" ]; then
    echo "Verifying HouseNFT on Sourcify..."
    if forge verify-contract \
        --chain-id $CHAIN_ID \
        --verifier sourcify \
        --watch \
        $HOUSENFT_ADDRESS \
        src/HouseNFT.sol:HouseNFT 2>&1 | tee /tmp/sourcify_housenft.log; then
        echo "✅ HouseNFT verified on Sourcify"
    else
        echo "⚠️  HouseNFT Sourcify verification had issues (may already be verified)"
    fi
    echo ""
fi

if [ -n "$FACTORY_ADDRESS" ]; then
    echo "Verifying AuctionFactory on Sourcify..."
    
    # Get constructor args from deployment
    DEPLOYER=$(jq -r '.transactions[0].transaction.from' $DEPLOYMENT_FILE)
    NFT_ADDR=$HOUSENFT_ADDRESS
    USDC_ADDR=$(jq -r '.transactions[] | select(.contractName == "AuctionFactory") | .arguments[2]' $DEPLOYMENT_FILE | head -1)
    
    if forge verify-contract \
        --chain-id $CHAIN_ID \
        --verifier sourcify \
        --watch \
        --constructor-args $(cast abi-encode "constructor(address,address,address)" $DEPLOYER $NFT_ADDR $USDC_ADDR) \
        $FACTORY_ADDRESS \
        src/AuctionFactory.sol:AuctionFactory 2>&1 | tee /tmp/sourcify_factory.log; then
        echo "✅ AuctionFactory verified on Sourcify"
        SOURCIFY_SUCCESS=true
    else
        echo "⚠️  AuctionFactory Sourcify verification had issues (may already be verified)"
    fi
    echo ""
fi

echo ""
echo "=================================================================="
echo "📊 VERIFICATION SUMMARY"
echo "=================================================================="
echo ""
echo "Blockscout:  $([ "$BLOCKSCOUT_SUCCESS" = true ] && echo "✅ Success" || echo "⚠️  Check manually")"
echo "Basescan:    $([ "$ETHERSCAN_SUCCESS" = true ] && echo "✅ Success" || echo "⚠️  Check manually or no API key")"
echo "Sourcify:    $([ "$SOURCIFY_SUCCESS" = true ] && echo "✅ Success" || echo "⚠️  Check manually")"
echo ""
echo "🔗 Verification Links:"
echo ""
echo "Blockscout:"
echo "  HouseNFT:        https://$([ "$CHAIN_ID" = "84532" ] && echo "base-sepolia" || echo "base").blockscout.com/address/$HOUSENFT_ADDRESS"
echo "  AuctionFactory:  https://$([ "$CHAIN_ID" = "84532" ] && echo "base-sepolia" || echo "base").blockscout.com/address/$FACTORY_ADDRESS"
echo ""
echo "Basescan:"
echo "  HouseNFT:        https://$([ "$CHAIN_ID" = "84532" ] && echo "sepolia." || echo "")basescan.org/address/$HOUSENFT_ADDRESS"
echo "  AuctionFactory:  https://$([ "$CHAIN_ID" = "84532" ] && echo "sepolia." || echo "")basescan.org/address/$FACTORY_ADDRESS"
echo ""
echo "Sourcify:"
echo "  Repository:      https://repo.sourcify.dev/contracts/full_match/$CHAIN_ID/"
echo ""
echo "=================================================================="
echo ""

