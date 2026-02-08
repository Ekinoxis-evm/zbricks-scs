# Contract Reference

Complete API documentation for the ZBrick Auction System contracts.

## Table of Contents

- [HouseNFT](#housenft)
- [AuctionManager](#auctionmanager)
- [AuctionFactory](#auctionfactory)

---

## HouseNFT

ERC721 NFT contract representing tokenized real estate properties with phase-based metadata.

**Inherits:** ERC721, Ownable

**Address (Base Sepolia):** `0xcd142fccc9685ba2eaeb2b17bf7adcd25cc4beb5`

### Constructor

```solidity
constructor(
    string memory name,
    string memory symbol
) ERC721(name, symbol) Ownable(msg.sender)
```

**Description**: Initializes the HouseNFT contract with name and symbol.

**Parameters:**
- `name`: Name of the NFT collection (e.g., "House NFT")
- `symbol`: Symbol of the NFT collection (e.g., "HOUSE")

**Example:**
```solidity
HouseNFT nft = new HouseNFT("House NFT", "HOUSE");
```

### State Variables

```solidity
uint256 public currentTokenId;
mapping(uint256 => address) public tokenControllers;
mapping(uint256 => string) public tokenBaseURIs;
mapping(uint256 => string) public tokenPhase1URIs;
mapping(uint256 => string) public tokenPhase2URIs;
mapping(uint256 => string) public tokenPhase3URIs;
```

**Description:**
- `currentTokenId`: Counter for minted tokens
- `tokenControllers`: Maps token ID to its controller address (AuctionManager)
- `tokenBaseURIs`: Base metadata URI for each token
- `tokenPhase1URIs`: Phase 1 (Active Bidding) metadata for each token
- `tokenPhase2URIs`: Phase 2 (Grace Period) metadata for each token
- `tokenPhase3URIs`: Phase 3 (Finalized) metadata for each token

### Functions

#### mint
```solidity
function mint(address to) external onlyOwner returns (uint256)
```

**Description**: Mints a new house NFT to the specified address.

**Access**: Owner only  
**Parameters:**
- `to`: Address to receive the NFT

**Returns**: Token ID of the minted NFT

**Example:**
```solidity
uint256 tokenId = nft.mint(auctionManagerAddress);
```

```bash
cast send <NFT_ADDRESS> "mint(address)" <RECIPIENT_ADDRESS> \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### setController
```solidity
function setController(uint256 tokenId, address controller) external onlyOwner
```

**Description**: Sets the controller address for a specific token (typically the AuctionManager).

**Access**: Owner only  
**Parameters:**
- `tokenId`: Token ID to set controller for
- `controller`: Address of the controller

**Example:**
```solidity
nft.setController(1, auctionManagerAddress);
```

```bash
cast send <NFT_ADDRESS> "setController(uint256,address)" 1 <AUCTION_ADDRESS> \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### setBaseURI
```solidity
function setBaseURI(uint256 tokenId, string memory uri) external
```

**Description**: Sets the base URI for a token's metadata.

**Access**: Token controller only  
**Parameters:**
- `tokenId`: Token ID to update
- `uri`: Base metadata URI

**Example:**
```solidity
nft.setBaseURI(1, "ipfs://Qm.../base.json");
```

---

#### setPhase1URI / setPhase2URI / setPhase3URI
```solidity
function setPhase1URI(uint256 tokenId, string memory uri) external
function setPhase2URI(uint256 tokenId, string memory uri) external
function setPhase3URI(uint256 tokenId, string memory uri) external
```

**Description**: Sets the metadata URI for a specific phase.

**Access**: Token controller only  
**Parameters:**
- `tokenId`: Token ID to update
- `uri`: Phase metadata URI

**Example:**
```solidity
nft.setPhase1URI(1, "ipfs://Qm.../phase1.json");
nft.setPhase2URI(1, "ipfs://Qm.../phase2.json");
nft.setPhase3URI(1, "ipfs://Qm.../phase3.json");
```

---

#### advancePhase
```solidity
function advancePhase(uint256 tokenId) external
```

**Description**: Advances to the next metadata phase for the token.

**Access**: Token controller only  
**Parameters:**
- `tokenId`: Token ID to advance

**Phases:**
- Base → Phase 1 (Active Bidding)
- Phase 1 → Phase 2 (Grace Period)
- Phase 2 → Phase 3 (Finalized)

**Example:**
```solidity
nft.advancePhase(1); // Advance token 1 to next phase
```

---

#### tokenURI
```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory)
```

**Description**: Returns the current metadata URI based on the token's phase.

**Access**: Public (view)  
**Parameters:**
- `tokenId`: Token ID to query

**Returns**: Current metadata URI

**Example:**
```solidity
string memory uri = nft.tokenURI(1);
```

```bash
cast call <NFT_ADDRESS> "tokenURI(uint256)" 1 --rpc-url base_sepolia
```

### Events

```solidity
event ControllerSet(uint256 indexed tokenId, address indexed controller);
event BaseURISet(uint256 indexed tokenId, string uri);
event Phase1URISet(uint256 indexed tokenId, string uri);
event Phase2URISet(uint256 indexed tokenId, string uri);
event Phase3URISet(uint256 indexed tokenId, string uri);
event PhaseAdvanced(uint256 indexed tokenId, uint8 newPhase);
```

---

## AuctionManager

Manages the three-phase Dutch auction for a specific house NFT.

**Address (Base Sepolia):** `0x1d5854ef9b5fd15e1f477a7d15c94ea0e795d9a5`

### Constructor

```solidity
constructor(
    address _nftContract,
    uint256 _tokenId,
    address _usdc,
    uint256 _startingPrice,
    uint256 _reservePrice,
    uint256 _floorPrice,
    uint256 _minBidIncrement,
    uint256 _priceDecayRate
) Ownable(msg.sender)
```

**Description**: Initializes the auction with all parameters.

**Parameters:**
- `_nftContract`: Address of the HouseNFT contract
- `_tokenId`: Token ID being auctioned
- `_usdc`: USDC token address
- `_startingPrice`: Initial auction price (e.g., 100,000 USDC = 100000000000)
- `_reservePrice`: Minimum acceptable price (e.g., 50,000 USDC = 50000000000)
- `_floorPrice`: Absolute minimum bid (e.g., 1,000 USDC = 1000000000)
- `_minBidIncrement`: Minimum bid increase percentage (e.g., 500 = 5%)
- `_priceDecayRate`: Price reduction per second (e.g., 1000000 = 1 USDC/second)

**Requirements:** 
- NFT must be owned by this contract before deployment
- All parameters must be valid

**Example:**
```solidity
AuctionManager auction = new AuctionManager(
    nftAddress,
    1,                    // tokenId
    usdcAddress,
    100000000000,        // 100,000 USDC starting
    50000000000,         // 50,000 USDC reserve
    1000000000,          // 1,000 USDC floor
    500,                 // 5% increment
    1000000              // 1 USDC/second decay
);
```

### State Variables

```solidity
IERC721 public immutable nftContract;
uint256 public immutable tokenId;
IERC20 public immutable usdc;

uint256 public immutable startingPrice;
uint256 public immutable reservePrice;
uint256 public immutable floorPrice;
uint256 public immutable minBidIncrement;
uint256 public immutable priceDecayRate;

enum Phase { Phase1, Phase2, Phase3 }
Phase public currentPhase;

uint256 public phase1StartTime;
uint256 public phase2StartTime;
uint256 public phase3StartTime;

uint256 public constant PHASE1_DURATION = 7 days;
uint256 public constant PHASE2_DURATION = 3 days;

address public highestBidder;
uint256 public highestBid;
mapping(address => uint256) public userBids;

bool public paused;
bool public finalized;
```

### Functions

#### placeBid
```solidity
function placeBid(uint256 amount) external whenNotPaused
```

**Description**: Places a bid in the auction.

**Access**: Public  
**Parameters:**
- `amount`: Bid amount in USDC (with 6 decimals)

**Requirements:**
- Auction not paused or finalized
- Amount ≥ floor price
- If existing highest bid: amount ≥ highestBid + minBidIncrement
- User has approved USDC transfer
- Phase 1 or Phase 2 only

**Example:**
```solidity
// 1. Approve USDC
IERC20(usdc).approve(auctionAddress, 10000000000); // 10,000 USDC

// 2. Place bid
auction.placeBid(10000000000);
```

```bash
# Approve USDC
cast send <USDC_ADDRESS> "approve(address,uint256)" <AUCTION_ADDRESS> 10000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia

# Place bid
cast send <AUCTION_ADDRESS> "placeBid(uint256)" 10000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### getCurrentPrice
```solidity
function getCurrentPrice() public view returns (uint256)
```

**Description**: Calculates the current Dutch auction price in Phase 1.

**Access**: Public (view)  
**Returns**: Current price (decreases linearly from starting price to reserve price)

**Formula:**
```
price = startingPrice - (timeElapsed * priceDecayRate)
price = max(price, reservePrice)
```

**Example:**
```solidity
uint256 currentPrice = auction.getCurrentPrice();
```

```bash
cast call <AUCTION_ADDRESS> "getCurrentPrice()" --rpc-url base_sepolia
```

---

#### withdrawBid
```solidity
function withdrawBid() external
```

**Description**: Allows non-winning bidders to withdraw their bids.

**Access**: Public  
**Requirements:**
- Caller is not the highest bidder
- Auction not paused or finalized
- Caller has a bid to withdraw

**Example:**
```solidity
auction.withdrawBid();
```

```bash
cast send <AUCTION_ADDRESS> "withdrawBid()" \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### advancePhase
```solidity
function advancePhase() external onlyOwner
```

**Description**: Manually advances to the next auction phase.

**Access**: Owner only  
**Effects:**
- Phase 1 → Phase 2: Starts grace period
- Phase 2 → Phase 3: Starts finalization
- Updates NFT metadata URI

**Example:**
```solidity
auction.advancePhase();
```

```bash
cast send <AUCTION_ADDRESS> "advancePhase()" \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### finalizeAuction
```solidity
function finalizeAuction() external onlyOwner
```

**Description**: Completes the auction and transfers assets.

**Access**: Owner only  
**Requirements:**
- Must be in Phase 3
- Not already finalized

**Effects:**
- If highest bid exists: Transfers NFT to winner, USDC to owner
- If no bids: Returns NFT to owner
- Sets `finalized = true`

**Example:**
```solidity
auction.finalizeAuction();
```

```bash
cast send <AUCTION_ADDRESS> "finalizeAuction()" \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### pause / unpause
```solidity
function pause() external onlyOwner
function unpause() external onlyOwner
```

**Description**: Emergency pause/unpause auction operations.

**Access**: Owner only

**Example:**
```bash
# Pause
cast send <AUCTION_ADDRESS> "pause()" \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia

# Unpause
cast send <AUCTION_ADDRESS> "unpause()" \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

### View Functions

```solidity
function getPhaseEndTime() public view returns (uint256)
function getRemainingTime() public view returns (uint256)
function isPhaseExpired() public view returns (bool)
```

**Example:**
```bash
cast call <AUCTION_ADDRESS> "getPhaseEndTime()" --rpc-url base_sepolia
cast call <AUCTION_ADDRESS> "getRemainingTime()" --rpc-url base_sepolia
cast call <AUCTION_ADDRESS> "isPhaseExpired()" --rpc-url base_sepolia
```

### Events

```solidity
event BidPlaced(address indexed bidder, uint256 amount);
event BidWithdrawn(address indexed bidder, uint256 amount);
event PhaseAdvanced(Phase newPhase);
event AuctionFinalized(address indexed winner, uint256 finalPrice);
event Paused();
event Unpaused();
```

---

## AuctionFactory

Factory contract for deploying new auction instances.

**Address (Base Sepolia):** `0x14899b6946b7e39445859f7c5f8fd635e4073a09`

### Constructor

```solidity
constructor(address _usdc) Ownable(msg.sender)
```

**Parameters:**
- `_usdc`: USDC token address for all auctions

### Functions

#### createAuction
```solidity
function createAuction(
    address nftContract,
    uint256 tokenId,
    uint256 startingPrice,
    uint256 reservePrice,
    uint256 floorPrice,
    uint256 minBidIncrement,
    uint256 priceDecayRate
) external onlyOwner returns (address)
```

**Description**: Deploys a new AuctionManager instance.

**Access**: Owner only  
**Parameters:**
- `nftContract`: HouseNFT contract address
- `tokenId`: Token ID to auction
- `startingPrice`: Initial price (e.g., 100000000000 = 100k USDC)
- `reservePrice`: Reserve price (e.g., 50000000000 = 50k USDC)
- `floorPrice`: Minimum bid (e.g., 1000000000 = 1k USDC)
- `minBidIncrement`: Min increase (e.g., 500 = 5%)
- `priceDecayRate`: Decay rate (e.g., 1000000 = 1 USDC/second)

**Returns**: Address of the deployed AuctionManager

**Example:**
```bash
cast send <FACTORY_ADDRESS> \
    "createAuction(address,uint256,uint256,uint256,uint256,uint256,uint256)" \
    <NFT_ADDRESS> \
    1 \
    100000000000 \
    50000000000 \
    1000000000 \
    500 \
    1000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

---

#### getAuctions
```solidity
function getAuctions() external view returns (address[] memory)
```

**Description**: Returns all deployed auction addresses.

**Example:**
```bash
cast call <FACTORY_ADDRESS> "getAuctions()" --rpc-url base_sepolia
```

### Events

```solidity
event AuctionCreated(
    address indexed auction,
    address indexed nftContract,
    uint256 indexed tokenId
);
```

---

## Integration Example

### ethers.js v6

```javascript
import { ethers } from 'ethers';
import HouseNFTABI from './deployments/abi/HouseNFT.json';
import AuctionManagerABI from './deployments/abi/AuctionManager.json';

const provider = new ethers.JsonRpcProvider('https://sepolia.base.org');
const signer = new ethers.Wallet(privateKey, provider);

// Connect to contracts
const nft = new ethers.Contract(
  '0xcd142fccc9685ba2eaeb2b17bf7adcd25cc4beb5',
  HouseNFTABI,
  signer
);

const auction = new ethers.Contract(
  '0x1d5854ef9b5fd15e1f477a7d15c94ea0e795d9a5',
  AuctionManagerABI,
  signer
);

// Place a bid (10,000 USDC)
const amount = ethers.parseUnits('10000', 6);
await auction.placeBid(amount);

// Get current price
const price = await auction.getCurrentPrice();
console.log('Current price:', ethers.formatUnits(price, 6), 'USDC');
```

### viem

```typescript
import { createPublicClient, createWalletClient, http } from 'viem';
import { baseSepolia } from 'viem/chains';
import HouseNFTABI from './deployments/abi/HouseNFT.json';
import AuctionManagerABI from './deployments/abi/AuctionManager.json';

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http()
});

const walletClient = createWalletClient({
  chain: baseSepolia,
  transport: http()
});

// Place a bid
const { request } = await publicClient.simulateContract({
  address: '0x1d5854ef9b5fd15e1f477a7d15c94ea0e795d9a5',
  abi: AuctionManagerABI,
  functionName: 'placeBid',
  args: [10000000000n] // 10,000 USDC
});

await walletClient.writeContract(request);
```

---

## USDC Decimals

⚠️ **Important:** USDC uses 6 decimals (not 18 like ETH)

```javascript
// Correct: 1,000 USDC = 1000 * 10^6
const amount = 1000000000; // 1,000.000000 USDC

// Wrong:
const wrong = ethers.parseEther('1000'); // This is 1000 * 10^18
```

---

## Security Considerations

1. **Always approve USDC** before calling `placeBid()`
2. **Check auction phase** before interacting
3. **Verify contract addresses** on block explorer
4. **Test with small amounts** first on testnet
5. **Monitor events** for auction state changes
6. **Withdraw bids** if outbid to free up capital

---

## Testing

Run the comprehensive test suite:

```bash
forge test -vvv
```

63 tests covering all contract functionality including:
- Bidding mechanics
- Phase transitions
- Access control
- Edge cases
- Fuzz testing