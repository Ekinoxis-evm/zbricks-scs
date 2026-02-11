# Skill: Security & Auditing (Future)

> Tools and techniques for finding vulnerabilities before attackers do.

## Static Analysis

### Slither

Automated vulnerability scanner by Trail of Bits.

```bash
pip install slither-analyzer
slither .
slither . --print human-summary
slither . --detect reentrancy-eth,unchecked-transfer
```

Common detectors: reentrancy, unchecked return values, shadowed variables, uninitialized storage, tx.origin usage.

### Aderyn

Rust-based Solidity static analyzer (faster than Slither).

```bash
cargo install aderyn
aderyn .
```

## Symbolic Execution

### Mythril

Finds reachable bugs via symbolic execution.

```bash
pip install mythril
myth analyze src/AuctionManager.sol --solc-json foundry.toml
```

### Halmos

Symbolic testing inside Foundry — write tests that prove properties for ALL inputs.

```solidity
function check_bidNeverExceedsBalance(uint256 amount) public {
    // Halmos proves this for ALL possible amounts
    auction.placeBid(amount);
    assert(usdc.balanceOf(address(auction)) >= auction.currentHighBid());
}
```

```bash
pip install halmos
halmos --function check_
```

## Fuzzing

### Foundry Fuzz Testing

```solidity
function testFuzz_BidAmount(uint256 amount) public {
    vm.assume(amount > 0 && amount < type(uint128).max);
    // Foundry generates random amounts
    auction.placeBid(amount);
}
```

```bash
forge test --fuzz-runs 10000
```

### Invariant Testing

Define properties that must ALWAYS hold:

```solidity
function invariant_totalBidsMatchBalance() public {
    uint256 totalBids = 0;
    address[] memory allBidders = auction.getBidders();
    for (uint i = 0; i < allBidders.length; i++) {
        totalBids += auction.userBids(allBidders[i]);
    }
    assertEq(usdc.balanceOf(address(auction)), totalBids);
}
```

## Mutation Testing

### Gambit

Introduces bugs into your code to verify your tests catch them.

```bash
gambit mutate --solc-remappings @openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/ src/AuctionManager.sol
```

## Audit Preparation Checklist

- [ ] All tests pass with 90%+ coverage
- [ ] Slither reports zero high/medium findings
- [ ] Fuzz tests run with 100K+ runs
- [ ] Invariant tests defined for critical properties
- [ ] NatSpec documentation complete
- [ ] Access control documented
- [ ] Upgrade path documented (if applicable)
- [ ] Known limitations documented

## Common Vulnerabilities to Watch

| Vulnerability | Mitigation in ZBrick |
|---------------|---------------------|
| Reentrancy | `ReentrancyGuard` + CEI pattern |
| Access control bypass | `Ownable` + `onlyAdmin` modifiers |
| Integer overflow | Solidity 0.8+ built-in checks |
| Unchecked ERC20 returns | Using OpenZeppelin's safe transfers |
| Front-running | Continuous clearing auction design |
| Denial of service | Pull-based refunds, no loops over users |
| Flash loan attacks | Participation fee + multi-phase design |
