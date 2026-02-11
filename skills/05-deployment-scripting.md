# Skill: Deployment Scripting

> Forge scripts and shell wrappers for deploying and configuring ZBrick contracts.

## Two-Phase Model

```
Phase 1: Infrastructure (once per chain)
  DeployFactory.s.sol → HouseNFT + AuctionFactory

Phase 2: Per-Property (once per auction)
  CreateAuction.s.sol → Mint NFT + Set URIs + Create AuctionManager
```

## Forge Script Pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HouseNFT.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        HouseNFT nft = new HouseNFT();
        // ... more deployments

        vm.stopBroadcast();

        // Console output (not in broadcast)
        console.log("HouseNFT:", address(nft));
    }
}
```

### Key `vm` Cheatcodes for Scripts

| Cheatcode | Purpose |
|-----------|---------|
| `vm.envUint("KEY")` | Read uint from .env |
| `vm.envAddress("KEY")` | Read address from .env |
| `vm.envString("KEY")` | Read string from .env |
| `vm.envOr("KEY", default)` | Read with fallback default |
| `vm.startBroadcast(key)` | Start recording txs with signer |
| `vm.stopBroadcast()` | Stop recording txs |
| `block.chainid` | Current chain ID (for multi-chain logic) |

## Running Scripts

### Infrastructure Deployment

```bash
# With auto-verification (Blockscout)
forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api/

# Or use the wrapper script
./script/deploy-and-verify.sh base-sepolia
./script/deploy-and-verify.sh base
```

### Auction Creation

```bash
forge script script/CreateAuction.s.sol:CreateAuction \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast -vvvv
```

## Shell Wrapper Pattern

```bash
#!/bin/bash
set -e          # Exit on any error
source .env     # Load environment variables

NETWORK=$1

case $NETWORK in
  base-sepolia)
    RPC_URL="https://sepolia.base.org"
    VERIFIER_URL="https://base-sepolia.blockscout.com/api/"
    ;;
  base)
    RPC_URL="https://mainnet.base.org"
    VERIFIER_URL="https://base.blockscout.com/api/"
    ;;
esac

forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url $VERIFIER_URL
```

## Broadcast Artifacts

After `--broadcast`, Foundry saves tx details in:

```
broadcast/
└── DeployFactory.s.sol/
    ├── 84532/
    │   ├── run-latest.json      # Most recent deployment
    │   └── run-1707512345.json  # Timestamped history
    └── 8453/
        └── run-latest.json
```

These contain: deployed addresses, tx hashes, gas used, constructor args.

## Configuration Parameters

| Parameter | Env Var | Default |
|-----------|---------|---------|
| Floor price | `AUCTION_FLOOR_PRICE` | 10,000,000 USDC |
| Participation fee | `AUCTION_PARTICIPATION_FEE` | 1,000 USDC |
| Min bid increment | `AUCTION_MIN_BID_INCREMENT` | 5% |
| Phase 0 duration | `AUCTION_OPEN_DURATION` | 7 days |
| Phase 1 duration | `AUCTION_BIDDING_DURATION` | 14 days |
| Phase 2 duration | `AUCTION_EXECUTION_PERIOD` | 30 days |
| Treasury | `AUCTION_TREASURY` | (required) |
| Phase URIs | `AUCTION_PHASE_*_URI` | (required) |

## Dry Run vs Live

```bash
# Dry run (simulate, no broadcast)
forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY

# Live (add --broadcast)
forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast
```

Always dry-run first. Check the simulated output before broadcasting.
