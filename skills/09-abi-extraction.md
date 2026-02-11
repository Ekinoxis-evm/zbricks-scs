# Skill: ABI & Artifact Extraction

> Extract contract ABIs and addresses from Foundry build artifacts for frontend integration.

## The Tool: `extractDeployment.js`

Node.js script that reads Foundry output and creates clean deployment files for frontends.

## Usage

```bash
node script/extractDeployment.js all     # All chains
node script/extractDeployment.js 84532   # Base Sepolia only
node script/extractDeployment.js 8453    # Base Mainnet only
node script/extractDeployment.js abi     # Just ABIs (no broadcast needed)
```

## Output

```
deployments/
├── addresses.json           # Contract addresses per chain
└── abi/
    ├── HouseNFT.json        # HouseNFT ABI
    ├── AuctionFactory.json  # AuctionFactory ABI
    └── AuctionManager.json  # AuctionManager ABI
```

### addresses.json

```json
{
  "8453": {
    "chainId": 8453,
    "chainName": "Base Mainnet",
    "explorer": "https://base.blockscout.com",
    "timestamp": "2026-02-09T21:37:04.762Z",
    "contracts": {
      "HouseNFT": "0x776b8158269fbd7fd6a91a0514b8850777ac0227",
      "AuctionFactory": "0x3347f6a853e04281daa0314f49a76964f010366f"
    }
  }
}
```

## How It Works

1. Reads `broadcast/DeployFactory.s.sol/<chainId>/run-latest.json`
2. Parses transaction receipts for `CREATE` transactions
3. Maps contract names to deployed addresses
4. Reads `out/<Contract>.sol/<Contract>.json` for ABIs
5. Writes clean JSON files to `deployments/`

## Frontend Integration

```typescript
// React / Next.js example
import addresses from '@/deployments/addresses.json';
import HouseNFTAbi from '@/deployments/abi/HouseNFT.json';
import AuctionFactoryAbi from '@/deployments/abi/AuctionFactory.json';
import AuctionManagerAbi from '@/deployments/abi/AuctionManager.json';

const chainId = 8453; // Base Mainnet
const config = addresses[chainId];

// With ethers.js
const nft = new ethers.Contract(config.contracts.HouseNFT, HouseNFTAbi, signer);

// With viem/wagmi
const { data } = useReadContract({
  address: config.contracts.HouseNFT,
  abi: HouseNFTAbi,
  functionName: 'tokenURI',
  args: [1n],
});
```

## Where ABIs Come From

Foundry compiles contracts to `out/`:

```
out/
├── HouseNFT.sol/
│   └── HouseNFT.json          # Full artifact (ABI + bytecode + metadata)
├── AuctionFactory.sol/
│   └── AuctionFactory.json
└── AuctionManager.sol/
    └── AuctionManager.json
```

The extraction script pulls just the `abi` field from each artifact.
