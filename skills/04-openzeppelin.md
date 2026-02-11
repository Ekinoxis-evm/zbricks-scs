# Skill: OpenZeppelin Security

> Battle-tested, audited smart contract libraries. ZBrick uses OpenZeppelin v5.5.0.

## Installation

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

Remapping in `foundry.toml`:
```toml
remappings = ["@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"]
```

## Libraries Used in ZBrick

### ERC721 — NFT Standard

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract HouseNFT is ERC721 {
    constructor() ERC721("ZBRICKS", "ZBR") {}
}
```

Core functions inherited: `ownerOf`, `transferFrom`, `approve`, `balanceOf`, `tokenURI`.

### Ownable — Single-Admin Access Control

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionFactory is Ownable {
    constructor() Ownable(msg.sender) {}

    function createAuction(...) external onlyOwner { ... }
}
```

| Function | Purpose |
|----------|---------|
| `owner()` | Returns current owner |
| `onlyOwner` | Modifier restricting to owner |
| `transferOwnership(newOwner)` | Transfer control |
| `renounceOwnership()` | Permanently remove owner |

### Pausable — Emergency Stop

```solidity
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AuctionManager is Pausable {
    function placeBid(uint256 amount) external whenNotPaused { ... }
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
```

### ReentrancyGuard — Reentrancy Protection

```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AuctionManager is ReentrancyGuard {
    function withdrawBid() external nonReentrant {
        // Safe from reentrancy attacks
    }
}
```

**When to use:** Any function that transfers tokens/ETH and modifies state.

### EnumerableSet — Efficient Data Structure

```solidity
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

using EnumerableSet.AddressSet for EnumerableSet.AddressSet;
EnumerableSet.AddressSet private bidders;

bidders.add(msg.sender);     // O(1)
bidders.remove(msg.sender);  // O(1)
bidders.contains(addr);      // O(1)
bidders.length();             // O(1)
bidders.at(index);            // O(1)
bidders.values();             // Returns address[]
```

### IERC20 — Token Interface

```solidity
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

IERC20 public immutable paymentToken;  // USDC

// Transfer tokens from user to contract
paymentToken.transferFrom(msg.sender, address(this), amount);

// Transfer tokens from contract to user
paymentToken.transfer(recipient, amount);
```

## OpenZeppelin v5 vs v4 Key Differences

| Feature | v4 | v5 |
|---------|----|----|
| Ownable constructor | `Ownable()` | `Ownable(initialOwner)` |
| Access control | `onlyOwner` | Same, but explicit initial owner |
| Custom errors | String reverts | Custom errors (gas efficient) |
| Solidity version | `^0.8.0` | `^0.8.20` |

## Other Useful OpenZeppelin Contracts (Not Yet Used)

| Contract | Purpose | When to Add |
|----------|---------|-------------|
| `AccessControl` | Role-based permissions (multiple roles) | When you need more than just owner |
| `ERC721Enumerable` | On-chain token enumeration | If you need `tokenOfOwnerByIndex` |
| `ERC721URIStorage` | Per-token URI storage | Alternative to custom phase URIs |
| `TimelockController` | Delayed execution | For governance/upgrade safety |
| `ERC2981` | On-chain royalties | Secondary market royalty enforcement |
| `MerkleProof` | Whitelist verification | Allowlisted bidders |
