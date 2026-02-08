# Auction Flow Documentation

> 📖 **[← Back to README](README.md)** | **[View Contract Reference](CONTRACT-REFERENCE.md)**

Complete guide to the multi-phase Continuous Clearing Auction (CCA) mechanism used in the ZBrick real estate tokenization system.

---

## Table of Contents

1. [Overview](#overview)
2. [Auction Phases](#auction-phases)
   - [Phase 0: Initial Reveal](#phase-0-initial-reveal-48-hours)
   - [Phase 1: Second Reveal](#phase-1-second-reveal-24-hours)
   - [Phase 2: Final Reveal](#phase-2-final-reveal-24-hours)
   - [Phase 3: Post-Auction](#phase-3-post-auction)
3. [Bidding Mechanics](#bidding-mechanics)
4. [Refund System](#refund-system)
5. [NFT Metadata Evolution](#nft-metadata-evolution)
6. [State Transitions](#state-transitions)
7. [Example Scenarios](#example-scenarios)
8. [Security Considerations](#security-considerations)

---

## Overview

The ZBrick auction system implements a **4-phase Continuous Clearing Auction (CCA)** designed for progressive reveal of real estate tokenization:

### Auction Type: Continuous Clearing Auction (CCA)

**Key Principle**: Only the winner pays. All other bidders receive full refunds.

### Phase Structure

| Phase | Duration | Bidding | Metadata Reveal | Description |
|-------|----------|---------|-----------------|-------------|
| **Phase 0** | 48 hours | ✅ Active | Initial | Basic property information |
| **Phase 1** | 24 hours | ✅ Active | Second | Additional details revealed |
| **Phase 2** | 24 hours | ✅ Active | Final | Complete information |
| **Phase 3** | Indefinite | ❌ Closed | Winner | Post-finalization |

**Total Duration**: 96 hours (4 days) minimum

### Core Features

- 💰 **Winner-Takes-All**: Only final winner pays, all others refunded
- 🔄 **Continuous Bidding**: New bids accepted throughout phases 0-2
- 📈 **Progressive Reveal**: More property info revealed each phase
- 🔒 **Phase Locking**: Each phase's winner locked when advancing
- 💸 **Pull Refunds**: Safe withdrawal pattern for outbid participants
- ⏸️ **Emergency Pause**: Admin can pause for safety

---

## Auction Phases

### Phase 0: Initial Reveal (48 hours)

**Duration**: 48 hours (configurable, minimum 24h)  
**Status**: Bidding Active  
**NFT Metadata**: Basic information

#### What Happens

- Auction starts immediately upon deployment
- Initial property metadata revealed (Phase 0 URI)
- Bidders can start placing bids
- Each new bid must exceed current highest bid
- Previous highest bidder automatically moved to refund queue

#### Bidding Requirements

```solidity
// Minimum bid: Must exceed current highest bid
require(amount > currentHighBid, "Bid too low");

// USDC approval required
IERC20(usdc).approve(auctionAddress, bidAmount);

// Place bid
auction.placeBid(bidAmount);
```

#### State Variables During Phase 0

```solidity
currentPhase = 0
currentLeader = <highest bidder address>
currentHighBid = <highest bid amount>
phases[0].revealed = false  // Not locked yet
phases[0].startTime = <deployment timestamp>
phases[0].minDuration = 48 hours
```

#### Example Timeline

```
Day 0, 00:00 - Auction starts
Day 0, 02:00 - Alice bids 1000 USDC (currentLeader: Alice)
Day 0, 06:00 - Bob bids 1200 USDC (currentLeader: Bob, Alice refunded 1000 USDC)
Day 1, 12:00 - Carol bids 1500 USDC (currentLeader: Carol, Bob refunded 1200 USDC)
Day 2, 00:00 - Phase 0 duration complete, ready to advance
```

#### Phase 0 End Conditions

- ✅ 48 hours elapsed (automatic readiness)
- ✅ Admin calls `advancePhase()` after duration met

---

### Phase 1: Second Reveal (24 hours)

**Duration**: 24 hours (configurable, minimum 24h)  
**Status**: Bidding Active  
**NFT Metadata**: Second reveal

#### What Happens

- Admin calls `advancePhase()` to start Phase 1
- Phase 0 winner and bid locked in `phases[0]`
- Phase 0 marked as `revealed = true`
- New metadata URI revealed (Phase 1 URI)
- Bidding continues with new baseline

#### Phase Advancement Process

```solidity
// Admin checks readiness
uint256 timeLeft = auction.getTimeRemaining();
require(timeLeft == 0, "Phase 0 not complete");

// Advance auction phase
auction.advancePhase();  // Locks Phase 0, starts Phase 1

// Advance NFT metadata
houseNFT.advancePhase(1);  // Updates to Phase 1 URI
```

#### State Variables During Phase 1

```solidity
currentPhase = 1
phases[0].revealed = true           // Phase 0 locked
phases[0].leader = <Phase 0 winner>
phases[0].highBid = <Phase 0 high bid>
phases[1].startTime = <phase 1 start timestamp>
phases[1].minDuration = 24 hours
phases[1].revealed = false          // Not locked yet
```

#### Bidding Continues

- Previous highest bidder from Phase 0 can bid again
- New bidders can join
- Must exceed current highest bid in Phase 1
- All previous refunds remain available for withdrawal

#### Example Timeline

```
Day 2, 00:01 - Admin advances to Phase 1
                Phase 0 locked: Carol won with 1500 USDC
Day 2, 02:00 - Dave bids 1600 USDC (currentLeader: Dave)
Day 2, 08:00 - Carol bids 1800 USDC (currentLeader: Carol, Dave refunded 1600 USDC)
Day 3, 00:00 - Phase 1 duration complete, ready to advance
```

---

### Phase 2: Final Reveal (24 hours)

**Duration**: 24 hours (configurable, minimum 24h)  
**Status**: Bidding Active (Last Chance)  
**NFT Metadata**: Complete information

#### What Happens

- Admin calls `advancePhase()` to start Phase 2
- Phase 1 winner and bid locked in `phases[1]`
- Phase 1 marked as `revealed = true`
- Final metadata URI revealed (Phase 2 URI)
- Last opportunity for bidding

#### Phase Advancement Process

```solidity
// Admin checks readiness
uint256 timeLeft = auction.getTimeRemaining();
require(timeLeft == 0, "Phase 1 not complete");

// Advance auction phase
auction.advancePhase();  // Locks Phase 1, starts Phase 2

// Advance NFT metadata
houseNFT.advancePhase(2);  // Updates to Phase 2 URI
```

#### State Variables During Phase 2

```solidity
currentPhase = 2
phases[1].revealed = true           // Phase 1 locked
phases[1].leader = <Phase 1 winner>
phases[1].highBid = <Phase 1 high bid>
phases[2].startTime = <phase 2 start timestamp>
phases[2].minDuration = 24 hours
phases[2].revealed = false          // Not locked yet
```

#### Final Bidding Round

- All property information revealed
- Bidders make informed final decisions
- Most competitive phase typically
- Last chance to participate

#### Example Timeline

```
Day 3, 00:01 - Admin advances to Phase 2
                Phase 1 locked: Carol won with 1800 USDC
Day 3, 04:00 - Eve bids 2000 USDC (currentLeader: Eve)
Day 3, 12:00 - Carol bids 2200 USDC (currentLeader: Carol, Eve refunded 2000 USDC)
Day 3, 20:00 - Eve bids 2500 USDC (currentLeader: Eve, Carol refunded 2200 USDC)
Day 4, 00:00 - Phase 2 duration complete, ready to finalize
```

---

### Phase 3: Post-Auction

**Duration**: Indefinite  
**Status**: Bidding Closed  
**NFT Metadata**: Winner reveal

#### What Happens

- Admin calls `finalizeAuction()` to complete auction
- Phase 2 winner and bid locked in `phases[2]`
- `finalized = true`
- NFT transferred to winner
- Winner's payment held in contract
- All other bidders can withdraw refunds

#### Finalization Process

```solidity
// Admin checks readiness
require(currentPhase == 2, "Must be in Phase 2");
uint256 timeLeft = auction.getTimeRemaining();
require(timeLeft == 0, "Phase 2 not complete");
require(currentLeader != address(0), "No winner");

// Finalize auction
auction.finalizeAuction();  // Transfers NFT, locks Phase 2

// Advance NFT to final metadata
houseNFT.advancePhase(3);  // Updates to Phase 3 URI (winner reveal)
```

#### State Variables After Finalization

```solidity
currentPhase = 2  // Stays at 2
finalized = true
phases[2].revealed = true
phases[2].leader = <Final winner>
phases[2].highBid = <Final winning bid>
```

#### Post-Finalization Actions

**Winner**:
- ✅ Owns NFT (automatically transferred)
- ❌ Cannot withdraw (they won, payment held)
- ✅ Can view winner metadata (Phase 3 URI)

**Other Bidders**:
- ✅ Can withdraw full refunds at any time
- ✅ No fees, no penalties
- ✅ Pull refunds when convenient

**Admin**:
- ✅ Can withdraw proceeds (winning bid amount)
- ✅ Can only withdraw once
- ✅ Can transfer admin role if needed

#### Example Timeline

```
Day 4, 00:01 - Admin finalizes auction
                Phase 2 locked: Eve won with 2500 USDC
                NFT transferred to Eve
Day 4, 00:02 - Admin advances NFT to Phase 3 metadata
                Winner reveal displayed
Day 4, 01:00 - Carol withdraws refund (2200 USDC)
Day 4, 02:00 - Dave withdraws refund (1600 USDC)
Day 5, 00:00 - Admin withdraws proceeds (2500 USDC)
```

---

## Bidding Mechanics

### How Bidding Works

#### 1. Check Current State

```solidity
// Get auction state
(uint8 phase, address leader, uint256 highBid, bool finalized, bool biddingOpen) 
    = auction.getAuctionState();

require(biddingOpen, "Bidding closed");
require(!finalized, "Auction ended");
```

```bash
cast call <AUCTION_ADDRESS> "getAuctionState()" --rpc-url base_sepolia
```

#### 2. Prepare Bid Amount

```javascript
// Frontend: Convert USDC amount to 6 decimals
const bidAmountUSDC = 1000; // 1000 USDC
const bidAmountWei = ethers.utils.parseUnits(bidAmountUSDC.toString(), 6);
// Result: 1000000000 (1000 * 10^6)
```

```solidity
// Solidity: USDC has 6 decimals
uint256 bidAmount = 1000 * 10**6; // 1000 USDC
```

#### 3. Approve USDC Transfer

```solidity
// Approve auction to spend USDC
IERC20(usdc).approve(auctionAddress, bidAmount);
```

```bash
cast send <USDC_ADDRESS> \
    "approve(address,uint256)" \
    <AUCTION_ADDRESS> \
    1000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

```javascript
// Frontend
const usdcContract = new ethers.Contract(usdcAddress, usdcABI, signer);
const approveTx = await usdcContract.approve(auctionAddress, bidAmountWei);
await approveTx.wait();
```

#### 4. Place Bid

```solidity
auction.placeBid(bidAmount);
```

```bash
cast send <AUCTION_ADDRESS> \
    "placeBid(uint256)" \
    1000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

```javascript
// Frontend
const auctionContract = new ethers.Contract(auctionAddress, auctionABI, signer);
const bidTx = await auctionContract.placeBid(bidAmountWei);
await bidTx.wait();
```

### What Happens When You Bid

```solidity
// Internal auction logic when placeBid() is called:

// 1. Validate bid
require(amount > currentHighBid, "Bid too low");
require(currentPhase <= 2, "Bidding closed");
require(!paused, "Auction paused");
require(!finalized, "Auction finalized");

// 2. Handle previous leader (if exists)
if (currentLeader != address(0)) {
    refundBalance[currentLeader] += currentHighBid;  // Add to refund queue
}

// 3. Update state
currentLeader = msg.sender;
currentHighBid = amount;

// 4. Transfer USDC
usdc.transferFrom(msg.sender, address(this), amount);

// 5. Emit event
emit BidPlaced(currentPhase, msg.sender, amount);
```

### Bid Requirements

| Requirement | Description |
|-------------|-------------|
| **Amount** | Must exceed `currentHighBid` |
| **Phase** | Must be Phase 0, 1, or 2 |
| **Status** | Auction not paused, not finalized |
| **Balance** | Bidder has sufficient USDC |
| **Approval** | Auction approved to spend USDC |

---

## Refund System

### Pull Payment Pattern

The auction uses a **pull payment pattern** for refunds, which is safer than push payments.

#### Why Pull Pattern?

- ✅ **Gas Efficient**: No loops pushing to multiple addresses
- ✅ **Safer**: No reentrancy attacks via refund recipients
- ✅ **User Control**: Users withdraw when convenient
- ✅ **Always Available**: Can withdraw even if auction paused

### How Refunds Work

```solidity
// When you're outbid:
// 1. Your previous bid moved to refundBalance mapping
refundBalance[yourAddress] += yourPreviousBid;

// 2. You can withdraw anytime
uint256 refund = refundBalance[yourAddress];
auction.withdraw();

// 3. Refund transferred to you
usdc.transfer(msg.sender, refund);
refundBalance[yourAddress] = 0;
```

### Checking Your Refund

```solidity
// Contract call
uint256 myRefund = auction.getBidderRefund(myAddress);
```

```bash
cast call <AUCTION_ADDRESS> \
    "getBidderRefund(address)" \
    <YOUR_ADDRESS> \
    --rpc-url base_sepolia
```

```javascript
// Frontend
const refund = await auctionContract.getBidderRefund(userAddress);
const refundUSDC = ethers.utils.formatUnits(refund, 6);
console.log(`Your refund: ${refundUSDC} USDC`);
```

### Withdrawing Refunds

```solidity
// Contract call
auction.withdraw();
```

```bash
cast send <AUCTION_ADDRESS> "withdraw()" \
    --private-key $PRIVATE_KEY \
    --rpc-url base_sepolia
```

```javascript
// Frontend
async function withdrawRefund() {
    const refund = await auctionContract.getBidderRefund(userAddress);
    
    if (refund.isZero()) {
        alert('No refund available');
        return;
    }
    
    const tx = await auctionContract.withdraw();
    await tx.wait();
    
    alert(`Withdrew ${ethers.utils.formatUnits(refund, 6)} USDC`);
}
```

### Refund Timeline Example

```
Timeline:
--------
Day 0, 02:00 - Alice bids 1000 USDC
               currentLeader: Alice (1000 USDC held)
               
Day 0, 06:00 - Bob bids 1200 USDC
               refundBalance[Alice] = 1000 USDC  ← Refund available
               currentLeader: Bob (1200 USDC held)
               
Day 0, 08:00 - Alice withdraws refund
               Alice receives 1000 USDC back
               
Day 1, 12:00 - Carol bids 1500 USDC
               refundBalance[Bob] = 1200 USDC  ← Refund available
               currentLeader: Carol (1500 USDC held)
               
Day 4, 00:00 - Auction finalized, Carol wins
               Carol's 1500 USDC held by admin
               Bob can withdraw 1200 USDC anytime
```

### Important Notes

- ✅ Can withdraw refunds even if auction paused
- ✅ Can withdraw refunds even after auction finalized
- ✅ No time limit to withdraw
- ✅ No penalties or fees
- ❌ Current leader cannot withdraw (they're winning!)
- ❌ Winner cannot withdraw after finalization (they won, payment held)

---

## NFT Metadata Evolution

The HouseNFT contract returns different metadata URIs based on the current phase.

### Metadata Structure

```json
{
  "name": "123 Main Street, City, State",
  "description": "Description varies by phase",
  "image": "ipfs://QmXYZ.../image.png",
  "external_url": "https://zbrick.io/property/1",
  "attributes": [
    {"trait_type": "Address", "value": "123 Main Street"},
    {"trait_type": "City", "value": "City Name"},
    {"trait_type": "State", "value": "State"},
    {"trait_type": "Square Feet", "value": "2000"},
    {"trait_type": "Bedrooms", "value": "3"},
    {"trait_type": "Bathrooms", "value": "2"},
    {"trait_type": "Phase", "value": "Phase 0"}
  ]
}
```

### Phase 0 Metadata (Initial Reveal)

**URI**: `phaseURIs[0]`  
**Information Level**: Basic

```json
{
  "name": "Residential Property - Phase 0",
  "description": "A tokenized residential property. Bidding is active in Phase 0.",
  "image": "ipfs://Qm.../phase0-exterior.png",
  "attributes": [
    {"trait_type": "Property Type", "value": "Residential"},
    {"trait_type": "Location", "value": "General Area"},
    {"trait_type": "Phase", "value": "Phase 0"},
    {"trait_type": "Status", "value": "Bidding Active"}
  ]
}
```

**What's Revealed**:
- Property type (residential, commercial, etc.)
- General location (city/area)
- Basic features
- Exterior photos

**What's Hidden**:
- Exact address
- Interior photos
- Detailed floor plans
- Property history
- Current tenants (if any)

---

### Phase 1 Metadata (Second Reveal)

**URI**: `phaseURIs[1]`  
**Information Level**: Detailed

```json
{
  "name": "123 Main Street - Phase 1",
  "description": "Additional property details revealed. Bidding continues in Phase 1.",
  "image": "ipfs://Qm.../phase1-interior.png",
  "attributes": [
    {"trait_type": "Address", "value": "123 Main Street"},
    {"trait_type": "City", "value": "Springfield"},
    {"trait_type": "State", "value": "IL"},
    {"trait_type": "Square Feet", "value": "2000"},
    {"trait_type": "Bedrooms", "value": "3"},
    {"trait_type": "Bathrooms", "value": "2"},
    {"trait_type": "Year Built", "value": "2015"},
    {"trait_type": "Phase", "value": "Phase 1"},
    {"trait_type": "Status", "value": "Bidding Active"},
    {"trait_type": "Phase 0 Winner", "value": "0x123..."}
  ]
}
```

**What's Revealed**:
- Exact address
- Property specifications
- Interior photos
- Floor plans
- Phase 0 auction results

**What's Hidden**:
- Detailed inspection reports
- Financial documents
- Tenant agreements
- Complete property history

---

### Phase 2 Metadata (Final Reveal)

**URI**: `phaseURIs[2]`  
**Information Level**: Complete

```json
{
  "name": "123 Main Street - Complete Information",
  "description": "All property information revealed. Final bidding phase.",
  "image": "ipfs://Qm.../phase2-complete.png",
  "attributes": [
    {"trait_type": "Address", "value": "123 Main Street"},
    {"trait_type": "City", "value": "Springfield"},
    {"trait_type": "State", "value": "IL"},
    {"trait_type": "Square Feet", "value": "2000"},
    {"trait_type": "Bedrooms", "value": "3"},
    {"trait_type": "Bathrooms", "value": "2"},
    {"trait_type": "Year Built", "value": "2015"},
    {"trait_type": "Last Appraised Value", "value": "$350,000"},
    {"trait_type": "Monthly Rental Income", "value": "$2,500"},
    {"trait_type": "Property Tax", "value": "$4,200/year"},
    {"trait_type": "Phase", "value": "Phase 2"},
    {"trait_type": "Status", "value": "Final Bidding"},
    {"trait_type": "Phase 0 Winner", "value": "0x123..."},
    {"trait_type": "Phase 1 Winner", "value": "0x456..."}
  ]
}
```

**What's Revealed**:
- Complete property documentation
- Inspection reports
- Financial details
- Tenant information
- Property history
- Phase 1 auction results
- All previous winners

---

### Phase 3 Metadata (Winner Reveal)

**URI**: `phaseURIs[3]`  
**Information Level**: Post-Auction

```json
{
  "name": "123 Main Street - SOLD",
  "description": "Property sold to winning bidder.",
  "image": "ipfs://Qm.../phase3-sold.png",
  "attributes": [
    {"trait_type": "Address", "value": "123 Main Street"},
    {"trait_type": "Status", "value": "Sold"},
    {"trait_type": "Sale Price", "value": "2500 USDC"},
    {"trait_type": "Winner", "value": "0x789..."},
    {"trait_type": "Finalized", "value": "2024-01-15"},
    {"trait_type": "Phase 0 Winner", "value": "0x123..."},
    {"trait_type": "Phase 1 Winner", "value": "0x456..."},
    {"trait_type": "Phase 2 Winner", "value": "0x789..."}
  ]
}
```

**What's Revealed**:
- Final sale information
- Winner address
- All phase winners
- Complete auction history

---

### How Metadata Updates

```solidity
// Admin advances auction phase
auction.advancePhase();  // Phase 0 → Phase 1

// Admin advances NFT metadata
houseNFT.advancePhase(1);  // Metadata Phase 0 → Phase 1

// NFT now returns Phase 1 URI
string memory uri = houseNFT.tokenURI(1);
// Returns: phaseURIs[1]
```

### Frontend Display

```javascript
// Fetch current metadata
async function displayNFT() {
    const currentPhase = await nftContract.currentPhase();
    const tokenURI = await nftContract.tokenURI(1);
    
    // Fetch metadata from IPFS/storage
    const response = await fetch(tokenURI);
    const metadata = await response.json();
    
    // Display
    document.getElementById('nft-name').textContent = metadata.name;
    document.getElementById('nft-description').textContent = metadata.description;
    document.getElementById('nft-image').src = metadata.image;
    document.getElementById('current-phase').textContent = currentPhase;
    
    // Display attributes
    metadata.attributes.forEach(attr => {
        console.log(`${attr.trait_type}: ${attr.value}`);
    });
}

// Listen for phase changes
nftContract.on("PhaseAdvanced", async (newPhase) => {
    console.log(`NFT advanced to phase ${newPhase}`);
    await displayNFT(); // Refresh display
});
```

---

## State Transitions

### State Diagram

```
┌─────────────┐
│   Deploy    │
│  Contracts  │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│    Phase 0          │  48 hours minimum
│  Initial Reveal     │  Bidding: ✅ Active
│  Bidding Active     │  Metadata: Basic Info
└──────┬──────────────┘
       │ advancePhase()
       │ (after 48h)
       ▼
┌─────────────────────┐
│    Phase 1          │  24 hours minimum
│  Second Reveal      │  Bidding: ✅ Active
│  Bidding Active     │  Metadata: Detailed Info
│  Phase 0 Locked     │  Phase 0: ✅ Revealed
└──────┬──────────────┘
       │ advancePhase()
       │ (after 24h)
       ▼
┌─────────────────────┐
│    Phase 2          │  24 hours minimum
│  Final Reveal       │  Bidding: ✅ Active
│  Bidding Active     │  Metadata: Complete Info
│  Phase 1 Locked     │  Phase 0-1: ✅ Revealed
└──────┬──────────────┘
       │ finalizeAuction()
       │ (after 24h)
       ▼
┌─────────────────────┐
│  Post-Auction       │  Indefinite
│  Finalized          │  Bidding: ❌ Closed
│  NFT Transferred    │  Metadata: Winner Info
│  Phase 2 Locked     │  All Phases: ✅ Revealed
└─────────────────────┘
```

### Transition Requirements

#### Phase 0 → Phase 1

```solidity
// Requirements
require(currentPhase == 0, "Must be Phase 0");
require(block.timestamp >= phases[0].startTime + phases[0].minDuration, "Duration not met");
require(!paused, "Auction paused");
require(!finalized, "Already finalized");

// Actions
1. Lock Phase 0 data (leader, highBid)
2. Mark phases[0].revealed = true
3. Set currentPhase = 1
4. Set phases[1].startTime = block.timestamp
5. Emit PhaseAdvanced(1)

// Separate NFT update (admin)
houseNFT.advancePhase(1);
```

#### Phase 1 → Phase 2

```solidity
// Requirements
require(currentPhase == 1, "Must be Phase 1");
require(block.timestamp >= phases[1].startTime + phases[1].minDuration, "Duration not met");
require(!paused, "Auction paused");
require(!finalized, "Already finalized");

// Actions
1. Lock Phase 1 data (leader, highBid)
2. Mark phases[1].revealed = true
3. Set currentPhase = 2
4. Set phases[2].startTime = block.timestamp
5. Emit PhaseAdvanced(2)

// Separate NFT update (admin)
houseNFT.advancePhase(2);
```

#### Phase 2 → Finalized

```solidity
// Requirements
require(currentPhase == 2, "Must be Phase 2");
require(block.timestamp >= phases[2].startTime + phases[2].minDuration, "Duration not met");
require(currentLeader != address(0), "No winner");
require(!finalized, "Already finalized");

// Actions
1. Lock Phase 2 data (leader, highBid)
2. Mark phases[2].revealed = true
3. Set finalized = true
4. Transfer NFT to winner: houseNFT.transferFrom(address(this), currentLeader, 1)
5. Emit AuctionFinalized(currentLeader, currentHighBid)

// Separate NFT update (admin)
houseNFT.advancePhase(3);
```

---

## Example Scenarios

### Scenario 1: Single Bidder Throughout

```
Timeline:
--------
Day 0, 00:00 - Auction starts (Phase 0)
Day 0, 02:00 - Alice bids 1000 USDC
               currentLeader: Alice (1000 USDC)

Day 2, 00:00 - Phase 0 complete (48h)
               Admin advances to Phase 1
               Phase 0 locked: Alice won with 1000 USDC

Day 3, 00:00 - Phase 1 complete (24h)
               No new bids
               Admin advances to Phase 2
               Phase 1 locked: Alice won with 1000 USDC

Day 4, 00:00 - Phase 2 complete (24h)
               No new bids
               Admin finalizes auction
               Phase 2 locked: Alice won with 1000 USDC
               NFT transferred to Alice
               Alice pays 1000 USDC total

Result: Alice wins all phases with 1000 USDC
```

---

### Scenario 2: Competitive Bidding War

```
Timeline:
--------
Day 0, 00:00 - Auction starts (Phase 0)

Day 0, 02:00 - Alice bids 1000 USDC
               currentLeader: Alice (1000 USDC)

Day 0, 06:00 - Bob bids 1200 USDC
               refundBalance[Alice] = 1000 USDC
               currentLeader: Bob (1200 USDC)

Day 1, 12:00 - Carol bids 1500 USDC
               refundBalance[Bob] = 1200 USDC
               currentLeader: Carol (1500 USDC)

Day 2, 00:00 - Phase 0 complete
               Admin advances to Phase 1
               Phase 0 locked: Carol won with 1500 USDC

Day 2, 04:00 - Dave sees detailed info, bids 1600 USDC
               refundBalance[Carol] = 1500 USDC
               currentLeader: Dave (1600 USDC)

Day 2, 08:00 - Carol withdraws 1500 USDC refund

Day 2, 12:00 - Carol bids 1800 USDC (new info convinced her)
               refundBalance[Dave] = 1600 USDC
               currentLeader: Carol (1800 USDC)

Day 3, 00:00 - Phase 1 complete
               Admin advances to Phase 2
               Phase 1 locked: Carol won with 1800 USDC

Day 3, 04:00 - Eve sees complete info, bids 2000 USDC
               refundBalance[Carol] = 1800 USDC
               currentLeader: Eve (2000 USDC)

Day 3, 12:00 - Carol withdraws 1800 USDC refund

Day 3, 20:00 - Carol makes final bid: 2200 USDC
               refundBalance[Eve] = 2000 USDC
               currentLeader: Carol (2200 USDC)

Day 4, 00:00 - Phase 2 complete
               Admin finalizes auction
               Phase 2 locked: Carol won with 2200 USDC
               NFT transferred to Carol
               Carol pays 2200 USDC total

Post-Auction:
Day 4, 01:00 - Alice already withdrew (1000 USDC)
Day 4, 02:00 - Bob withdraws refund (1200 USDC)
Day 4, 03:00 - Dave withdraws refund (1600 USDC)
Day 4, 04:00 - Eve withdraws refund (2000 USDC)
Day 5, 00:00 - Admin withdraws proceeds (2200 USDC)

Result: 
- Carol wins with 2200 USDC final bid
- All other bidders fully refunded
- Total refunds paid: 5800 USDC
- Only Carol pays (net: 2200 USDC)
```

---

### Scenario 3: Emergency Pause

```
Timeline:
--------
Day 0, 00:00 - Auction starts (Phase 0)
Day 0, 02:00 - Alice bids 1000 USDC
Day 0, 06:00 - Bob bids 1200 USDC

Day 1, 00:00 - Admin discovers suspicious activity
               Admin calls pause()
               paused = true

Day 1, 02:00 - Alice tries to withdraw refund
               ✅ Success! (withdrawals not blocked)
               Alice receives 1000 USDC

Day 1, 04:00 - Carol tries to bid
               ❌ Rejected: "Auction paused"

Day 1, 06:00 - Admin calls advancePhase()
               ❌ Rejected: "Auction paused"

Day 1, 12:00 - Admin resolves issue
               Admin calls unpause()
               paused = false

Day 1, 14:00 - Carol bids 1500 USDC
               ✅ Success! Bidding resumed
               refundBalance[Bob] = 1200 USDC
               currentLeader: Carol (1500 USDC)

Auction continues normally...
```

---

### Scenario 4: Late Stage Dramatic Increase

```
Timeline:
--------
Phase 0 (48 hours):
  Day 0 - Only small bids: max 1000 USDC
  Phase 0 locked: Alice won with 1000 USDC

Phase 1 (24 hours):
  Day 2 - Address revealed, bids up to 1500 USDC
  Phase 1 locked: Bob won with 1500 USDC

Phase 2 (24 hours):
  Day 3, 00:01 - Complete info revealed
  Day 3, 00:30 - Investor Carol analyzes financials
  Day 3, 02:00 - Carol bids 5000 USDC! (3.3x previous)
                 refundBalance[Bob] = 1500 USDC
                 currentLeader: Carol (5000 USDC)
  
  Day 3, 04:00 - Dave counters: 5500 USDC
                 refundBalance[Carol] = 5000 USDC
  
  Day 3, 08:00 - Carol withdraws 5000 USDC
  Day 3, 10:00 - Carol final bid: 6000 USDC
                 refundBalance[Dave] = 5500 USDC
                 currentLeader: Carol (6000 USDC)

Day 4, 00:00 - Finalized
               Carol wins with 6000 USDC
               40% of bids happened in last 24 hours

Result: Complete information triggered aggressive bidding
```

---

## Security Considerations

### For Bidders

#### Before Bidding

```javascript
// 1. Verify contract addresses on block explorer
const expectedNFT = "0xcd142fccc9685ba2eaeb2b17bf7adcd25cc4beb5";
const expectedAuction = "0x1d5854ef9b5fd15e1f477a7d15c94ea0e795d9a5";

// 2. Check auction state
const state = await auction.getAuctionState();
console.log("Phase:", state._currentPhase);
console.log("Bidding open:", state._biddingOpen);
console.log("Finalized:", state._finalized);

// 3. Verify USDC approval
const allowance = await usdc.allowance(myAddress, auctionAddress);
console.log("Current allowance:", ethers.utils.formatUnits(allowance, 6));

// 4. Check your USDC balance
const balance = await usdc.balanceOf(myAddress);
console.log("USDC balance:", ethers.utils.formatUnits(balance, 6));
```

#### During Bidding

```javascript
// 1. Use exact USDC amounts (6 decimals)
const bidAmount = ethers.utils.parseUnits("1000", 6); // Correct
// NOT: ethers.utils.parseEther("1000") // Wrong! (18 decimals)

// 2. Check current high bid before bidding
const currentHighBid = await auction.currentHighBid();
if (bidAmount.lte(currentHighBid)) {
    alert("Bid must be higher than current bid");
    return;
}

// 3. Monitor for outbids
auction.on("BidPlaced", (phase, bidder, amount) => {
    if (bidder !== myAddress && amount.gt(myBid)) {
        alert("You've been outbid!");
    }
});

// 4. Withdraw refunds promptly
const refund = await auction.getBidderRefund(myAddress);
if (refund.gt(0)) {
    await auction.withdraw();
}
```

#### Common Mistakes to Avoid

```javascript
// ❌ WRONG: Using 18 decimals for USDC
const wrongAmount = ethers.utils.parseEther("1000"); // 1000 * 10^18

// ✅ CORRECT: Using 6 decimals for USDC
const correctAmount = ethers.utils.parseUnits("1000", 6); // 1000 * 10^6

// ❌ WRONG: Bidding without approval
await auction.placeBid(amount); // Will fail

// ✅ CORRECT: Approve first
await usdc.approve(auctionAddress, amount);
await auction.placeBid(amount);

// ❌ WRONG: Assuming you can withdraw as current leader
if (await auction.currentLeader() === myAddress) {
    await auction.withdraw(); // Will fail
}

// ✅ CORRECT: Only withdraw if you have refund
const refund = await auction.getBidderRefund(myAddress);
if (refund.gt(0)) {
    await auction.withdraw();
}
```

---

### For Admin

#### Phase Management

```javascript
// 1. Check time remaining before advancing
const timeLeft = await auction.getTimeRemaining();
if (timeLeft > 0) {
    console.log(`Wait ${timeLeft} seconds before advancing`);
    return;
}

// 2. Advance auction and NFT together
await auction.advancePhase(); // Auction phase
await houseNFT.advancePhase(newPhase); // NFT metadata

// 3. Monitor for errors
try {
    await auction.advancePhase();
} catch (error) {
    if (error.message.includes("Duration not met")) {
        console.log("Wait longer before advancing");
    } else if (error.message.includes("Already revealed")) {
        console.log("Phase already advanced");
    }
}
```

#### Emergency Procedures

```javascript
// 1. Pause if suspicious activity detected
await auction.pause();
console.log("Auction paused, investigating...");

// 2. Users can still withdraw (safe)
// ... investigate issue ...

// 3. Resume when safe
await auction.unpause();
console.log("Auction resumed");

// 4. If critical issue, do NOT finalize
// Allow all users to withdraw refunds
// Consider redeployment with fixes
```

---

### For Developers

#### Integration Checklist

```javascript
// 1. Event listeners with error handling
auction.on("BidPlaced", async (phase, bidder, amount) => {
    try {
        await updateUI(phase, bidder, amount);
    } catch (error) {
        console.error("UI update failed:", error);
    }
});

// 2. Regular state polling
setInterval(async () => {
    try {
        const state = await auction.getAuctionState();
        updateDisplay(state);
    } catch (error) {
        console.error("State fetch failed:", error);
    }
}, 30000); // Every 30 seconds

// 3. Transaction monitoring
const tx = await auction.placeBid(amount);
console.log("Transaction sent:", tx.hash);
const receipt = await tx.wait();
console.log("Transaction confirmed:", receipt.blockNumber);

// 4. Graceful error handling
async function safeBid(amount) {
    try {
        // Check allowance
        const allowance = await usdc.allowance(user, auction.address);
        if (allowance.lt(amount)) {
            await usdc.approve(auction.address, amount);
        }
        
        // Place bid
        const tx = await auction.placeBid(amount);
        await tx.wait();
        return { success: true };
    } catch (error) {
        return { 
            success: false, 
            error: error.message 
        };
    }
}
```

---

## Summary

### Key Takeaways

1. **Auction Type**: Continuous Clearing Auction (CCA) - only winner pays
2. **Duration**: 96 hours (4 days) minimum across 3 bidding phases
3. **Progressive Reveal**: More property info revealed each phase
4. **Refund System**: Pull-based, safe, always available
5. **Phase Locking**: Each phase's winner recorded when advancing
6. **NFT Evolution**: Metadata changes with each phase
7. **Emergency Controls**: Admin can pause if needed
8. **User Safety**: Withdrawals never blocked, even when paused

### Best Practices

**For Bidders**:
- ✅ Verify contract addresses
- ✅ Use 6 decimals for USDC
- ✅ Approve USDC before bidding
- ✅ Monitor for outbids
- ✅ Withdraw refunds promptly

**For Admin**:
- ✅ Coordinate phase advancement (auction + NFT)
- ✅ Monitor for suspicious activity
- ✅ Use pause sparingly
- ✅ Withdraw proceeds after finalization

**For Developers**:
- ✅ Listen to events for real-time updates
- ✅ Poll state regularly
- ✅ Handle errors gracefully
- ✅ Test thoroughly on testnet

---

**For detailed API reference, see [CONTRACT-REFERENCE.md](./CONTRACT-REFERENCE.md)**  
**For quick deployment, see [README.md](./README.md)**