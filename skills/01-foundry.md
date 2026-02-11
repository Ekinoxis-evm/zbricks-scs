# Skill: Foundry Framework

> Rust-based toolkit for Solidity development: compilation, testing, deployment, and verification.

## Tools

| Tool | Purpose |
|------|---------|
| `forge` | Build, test, deploy, verify contracts |
| `cast` | Interact with deployed contracts from CLI |
| `anvil` | Local Ethereum node for development |
| `chisel` | Solidity REPL for quick experiments |

## Commands Used in ZBrick

### Build

```bash
forge build                   # Compile all contracts
forge build --sizes           # Compile + show contract byte sizes (24KB limit)
forge build --force           # Recompile everything from scratch
```

### Test

```bash
forge test                         # Run all tests
forge test -vvv                    # Verbose with stack traces
forge test --match-test testName   # Run specific test
forge test --match-contract Name   # Run specific contract's tests
forge test --gas-report            # Gas consumption per function
forge coverage                     # Code coverage report
forge coverage --report lcov       # Coverage for IDE integration
```

### Deploy

```bash
forge script script/DeployFactory.s.sol:DeployFactory \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api/
```

### Cast (Contract Interaction)

```bash
# Read from contract
cast call <address> "owner()(address)" --rpc-url $RPC_URL
cast call <address> "getAuctionCount()(uint256)" --rpc-url $RPC_URL

# Write to contract
cast send <address> "advancePhase()" --private-key $KEY --rpc-url $RPC_URL

# Encode constructor args
cast abi-encode "constructor(address,address)" $ADDR1 $ADDR2

# Decode data
cast abi-decode "functionName()(uint256,address)" <hex_data>

# Get chain ID
cast chain-id --rpc-url $RPC_URL
```

### Anvil (Local Node)

```bash
anvil                              # Start local node on :8545
anvil --fork-url $RPC_URL          # Fork a live network
anvil --fork-block-number 12345    # Fork at specific block
```

### Format

```bash
forge fmt                  # Auto-format all .sol files
forge fmt --check          # Check formatting without modifying (CI gate)
```

## Configuration (`foundry.toml`)

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = ["@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"]
optimizer = true
optimizer_runs = 200
via_ir = true

[rpc_endpoints]
base_sepolia = "${BASE_SEPOLIA_RPC_URL}"
base = "${BASE_RPC_URL}"

[etherscan]
base-sepolia = { key = "${BASESCAN_API_KEY}" }
base = { key = "${BASESCAN_API_KEY}" }
```

### Key Settings

| Setting | Value | Why |
|---------|-------|-----|
| `optimizer` | `true` | Reduce gas costs |
| `optimizer_runs` | `200` | Balance deploy cost vs call cost |
| `via_ir` | `true` | IR pipeline for deeper optimizations |

## Dependency Management

```bash
forge install foundry-rs/forge-std                   # Standard library
forge install OpenZeppelin/openzeppelin-contracts     # OpenZeppelin
forge update                                          # Update all
forge remove <dep>                                    # Remove dependency
```

Dependencies live as git submodules in `lib/`. Tracked in `.gitmodules`.
