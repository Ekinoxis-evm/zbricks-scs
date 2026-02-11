# Skill: Solidity Patterns

> Design patterns and coding conventions used across ZBrick smart contracts.

## Patterns Applied

### Factory Pattern (`AuctionFactory.sol`)

Deploy isolated contract instances from a single factory:

```solidity
function createAuction(...) external onlyOwner returns (address) {
    AuctionManager auction = new AuctionManager(
        address(nftContract), address(paymentToken), ...
    );
    auctions.push(address(auction));
    isAuction[address(auction)] = true;
    return address(auction);
}
```

**Why:** Each property gets its own AuctionManager with isolated state, treasury, and admin.

### Checks-Effects-Interactions (`AuctionManager.sol`)

```solidity
function withdrawBid() external nonReentrant whenNotPaused {
    // 1. CHECKS
    uint256 amount = userBids[msg.sender];
    require(amount > 0, "No bid");

    // 2. EFFECTS (state changes first)
    userBids[msg.sender] = 0;
    bidders.remove(msg.sender);

    // 3. INTERACTIONS (external calls last)
    paymentToken.transfer(msg.sender, amount);
}
```

### Pull-Based Refunds

Users call `withdrawBid()` to get their funds back. The contract never pushes funds.

**Why:** Push-based refunds can fail (gas limits, malicious receivers), locking the contract.

### Incremental Bidding

Users add to existing bids instead of replacing them:

```solidity
function placeBid(uint256 amount) external {
    paymentToken.transferFrom(msg.sender, address(this), amount);
    userBids[msg.sender] += amount;
    _recalculateLeader();
}
```

### State Machine (Phase Progression)

```
Phase 0 (Open) → Phase 1 (Bidding) → Phase 2 (Execution) → Finalized
```

Each phase has a minimum duration. `advancePhase()` checks:

```solidity
require(block.timestamp >= phases[currentPhase].startTime + phaseDurations[currentPhase]);
```

### Atomic Operations

Factory creates auctions in one transaction: deploy + set controller + transfer NFT.

```solidity
AuctionManager auction = new AuctionManager(...);
nftContract.setController(tokenId, address(auction));
nftContract.transferFrom(address(this), address(auction), tokenId);
```

If any step fails, the entire transaction reverts. No partial state.

### Custom Errors

```solidity
error BidTooLow(uint256 amount, uint256 minimum);
error PhaseNotComplete(uint256 currentPhase, uint256 timeRemaining);
error AuctionAlreadyFinalized();
```

**Why:** Cheaper than `require` with string messages. More structured for frontend parsing.

### Event-Driven State Tracking

```solidity
event BidPlaced(address indexed bidder, uint256 amount, uint256 totalBid);
event PhaseAdvanced(uint256 indexed newPhase, uint256 timestamp);
event AuctionFinalized(address indexed winner, uint256 amount);
```

**Why:** Frontends and indexers listen to events, not storage reads.

## Solidity Conventions

| Convention | Example |
|-----------|---------|
| Version | `pragma solidity ^0.8.20;` |
| Naming | `camelCase` functions, `PascalCase` contracts, `UPPER_CASE` constants |
| Visibility | Explicit on all functions and state variables |
| Immutables | `immutable` for values set once in constructor |
| NatSpec | `@notice`, `@param`, `@return` on public functions |

## Contract Sizes

The EVM has a 24,576 byte limit per contract. Check with:

```bash
forge build --sizes
```

If close to limit: split into libraries, use shorter error messages, reduce public functions.
