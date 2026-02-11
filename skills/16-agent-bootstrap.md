# Skill: Agent Bootstrap Prompt

> Copy-paste context to load up a new AI agent (Claude, GPT, Cursor, etc.) for this project.

## Quick Bootstrap (Short Version)

```
You are working on ZBrick — a real estate auction platform on Base (L2).

Stack: Foundry, Solidity ^0.8.20, OpenZeppelin v5.5.0, USDC payments.

3 contracts:
- HouseNFT (ERC721) — NFTs with 4-phase metadata
- AuctionFactory — deploys isolated AuctionManager instances
- AuctionManager — 3-phase continuous clearing auction per property

Chains: Base Mainnet (8453), Base Sepolia (84532).
Payment: USDC (6 decimals).
Verification: Blockscout primary, Basescan secondary.

Key files: src/, script/, test/, deployments/, foundry.toml
Docs: README.md, DEPLOYMENT-GUIDE.md, CONTRACT-REFERENCE.md, AUCTION-FLOW.md
Skills reference: skills/ folder
```

## Full Bootstrap (Detailed Version)

```
You are working on ZBrick, a production smart contract system for tokenized
real estate auctions. Here is everything you need to know:

=== ARCHITECTURE ===
Factory pattern: deploy HouseNFT + AuctionFactory once per chain,
then create unlimited AuctionManager instances (one per property).

HouseNFT (src/HouseNFT.sol)
  - ERC721 "ZBRICKS" / "ZBR"
  - 4-phase metadata URIs per token (phases 0-3)
  - Admin + controller + trusted factory access control
  - Base Sepolia: 0x2452791d09506e21eb2936f5748c5006965fb325
  - Base Mainnet: 0x776b8158269fbd7fd6a91a0514b8850777ac0227

AuctionFactory (src/AuctionFactory.sol)
  - Ownable, creates AuctionManagers atomically
  - Validates NFT ownership, deploys, sets controller, transfers NFT
  - Base Sepolia: 0x9be95601c0b39705170b2424821aaab437be181c
  - Base Mainnet: 0x3347f6a853e04281daa0314f49a76964f010366f

AuctionManager (src/AuctionManager.sol)
  - Ownable + Pausable + ReentrancyGuard
  - 3-phase auction (Open → Bidding → Execution → Finalized)
  - Continuous clearing: highest bidder wins, others get full refund
  - USDC bidding, incremental bids, optional participation fee
  - Pull-based refunds, emergency controls

=== TOOLS & DEPENDENCIES ===
- Foundry (forge, cast, anvil) — build, test, deploy
- OpenZeppelin v5.5.0 — ERC721, Ownable, Pausable, ReentrancyGuard, EnumerableSet
- Solidity ^0.8.20 with optimizer (200 runs, via_ir)

=== CHAINS ===
- Base Sepolia (84532): USDC 0x036CbD53842c5426634e7929541eC2318f3dCF7e
- Base Mainnet (8453): USDC 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913

=== KEY FILES ===
Contracts:     src/HouseNFT.sol, src/AuctionFactory.sol, src/AuctionManager.sol
Tests:         test/HouseNFT.t.sol, test/AuctionManager.t.sol, test/mocks/MockUSDC.sol
Deploy:        script/DeployFactory.s.sol, script/CreateAuction.s.sol
Shell scripts: script/deploy-and-verify.sh, script/verify-contracts.sh
Extraction:    script/extractDeployment.js
Config:        foundry.toml, .env.example
Artifacts:     deployments/addresses.json, deployments/abi/
CI:            .github/workflows/test.yml

=== DOCUMENTATION ===
README.md            — project overview
DEPLOYMENT-GUIDE.md  — step-by-step deployment
CONTRACT-REFERENCE.md — full API reference
AUCTION-FLOW.md      — auction mechanics
skills/              — detailed skills reference (16 files)

=== PATTERNS ===
- Checks-Effects-Interactions on all value transfers
- Pull-based refunds (users call withdrawBid)
- Atomic operations (factory creates everything in one tx)
- Event-driven state tracking for frontends
- Custom errors over require strings
- Immutable constructor params, no upgradeable proxies

=== COMMANDS ===
forge build               — compile
forge test -vvv           — run tests
forge fmt                 — format code
./script/deploy-and-verify.sh base-sepolia  — deploy + verify
node script/extractDeployment.js all        — extract ABIs
```

## Per-Task Prompts

### "Add a new contract feature"
```
Read src/AuctionManager.sol first. Follow existing patterns:
Checks-Effects-Interactions, custom errors, events for state changes.
Add tests in test/AuctionManager.t.sol. Run forge test -vvv.
```

### "Deploy to a new chain"
```
Read script/DeployFactory.s.sol. Add the new chain's USDC address
in the if/else block. Add RPC to foundry.toml. Deploy with
./script/deploy-and-verify.sh <network>. Run extractDeployment.js.
```

### "Build the frontend"
```
Read skills/12-frontend-integration.md. Use deployments/addresses.json
and deployments/abi/ for contract config. Stack: Next.js + Viem + Wagmi.
```

### "Audit the contracts"
```
Read skills/11-security-auditing.md. Run slither, check for reentrancy,
access control, and integer issues. Write fuzz tests and invariant tests.
```

### "Set up event indexing"
```
Read skills/13-indexing-subgraphs.md. Index events: BidPlaced,
BidWithdrawn, PhaseAdvanced, AuctionFinalized, AuctionCreated.
Recommended: Ponder for TypeScript-first approach.
```
