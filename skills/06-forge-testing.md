# Skill: Forge Testing

> Writing and running Solidity tests with Foundry's Forge framework.

## Test Structure

```
test/
├── HouseNFT.t.sol           # NFT tests
├── AuctionManager.t.sol      # Auction logic tests
└── mocks/
    └── MockUSDC.sol          # Fake ERC20 for testing
```

## Test File Pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HouseNFT.sol";
import "./mocks/MockUSDC.sol";

contract AuctionManagerTest is Test {
    HouseNFT nft;
    MockUSDC usdc;
    address bidder1 = makeAddr("bidder1");
    address bidder2 = makeAddr("bidder2");

    function setUp() public {
        usdc = new MockUSDC();
        nft = new HouseNFT();
        // ... setup factory, create auction
    }

    function testPlaceBid() public {
        deal(address(usdc), bidder1, 1_000_000e6);
        vm.startPrank(bidder1);
        usdc.approve(address(auction), 1_000_000e6);
        auction.placeBid(500_000e6);
        vm.stopPrank();

        assertEq(auction.currentHighBid(), 500_000e6);
        assertEq(auction.currentLeader(), bidder1);
    }
}
```

## Key Test Cheatcodes

### Identity & Impersonation

```solidity
vm.prank(addr);              // Next call comes from addr
vm.startPrank(addr);         // All calls come from addr until stopPrank
vm.stopPrank();

makeAddr("label");           // Create labeled address deterministically
```

### Time Manipulation

```solidity
vm.warp(block.timestamp + 7 days);   // Jump forward in time
vm.roll(block.number + 100);          // Jump forward in blocks
skip(3600);                            // Skip 1 hour
rewind(3600);                          // Go back 1 hour
```

### Funding Accounts

```solidity
deal(address(token), recipient, amount);  // Set ERC20 balance
vm.deal(addr, 1 ether);                   // Set ETH balance
```

### Expecting Reverts

```solidity
vm.expectRevert("Bid too low");
auction.placeBid(100);

vm.expectRevert(abi.encodeWithSelector(BidTooLow.selector, 100, 1000));
auction.placeBid(100);
```

### Expecting Events

```solidity
vm.expectEmit(true, true, false, true);
emit BidPlaced(bidder1, 500e6, 500e6);
auction.placeBid(500e6);
```

## Mock Contracts

```solidity
// test/mocks/MockUSDC.sol
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;  // Match real USDC
    }
}
```

## Running Tests

```bash
forge test                              # All tests
forge test -vv                          # Show test names and status
forge test -vvv                         # Show stack traces on failure
forge test -vvvv                        # Show everything including setup
forge test --match-test testPlaceBid    # Run specific test
forge test --match-contract Auction     # Run tests in matching contracts
forge test --gas-report                 # Gas per function call
forge coverage                          # Code coverage
forge coverage --report lcov            # lcov format for tooling
```

## Test Categories to Cover

| Category | What to Test |
|----------|-------------|
| Happy path | Normal operations succeed |
| Access control | Unauthorized calls revert |
| Edge cases | Zero values, max values, boundary conditions |
| State transitions | Phase changes, finalization |
| Reentrancy | Multiple calls in one tx |
| Math | Overflow, precision, rounding |
| Events | Correct events emitted |

## Fork Testing

Test against live contract state:

```bash
forge test --fork-url https://sepolia.base.org -vvv
```

```solidity
function testWithLiveState() public {
    // Interact with real USDC on Base Sepolia
    IERC20 usdc = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);
    // ...
}
```
