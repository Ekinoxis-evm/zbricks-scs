# Skill: Indexing & Subgraphs (Future)

> Index blockchain events into queryable databases for fast frontend reads.

## Why Index

- `eth_getLogs` is slow for complex queries
- No built-in way to sort, filter, or paginate on-chain
- Frontends need fast reads — indexers provide this

## Option 1: Ponder (Recommended for ZBrick)

TypeScript-first indexer. Runs locally or on a server.

```typescript
// ponder.config.ts
import { createConfig } from '@ponder/core';
import AuctionManagerAbi from './deployments/abi/AuctionManager.json';

export default createConfig({
  networks: {
    base: { chainId: 8453, transport: http(process.env.BASE_RPC_URL) },
  },
  contracts: {
    AuctionManager: {
      network: 'base',
      abi: AuctionManagerAbi,
      address: '0x...', // or factory pattern
      startBlock: 12345678,
    },
  },
});
```

```typescript
// src/index.ts
import { ponder } from '@/generated';

ponder.on('AuctionManager:BidPlaced', async ({ event, context }) => {
  await context.db.Bid.create({
    id: event.log.id,
    bidder: event.args.bidder,
    amount: event.args.amount,
    totalBid: event.args.totalBid,
    timestamp: event.block.timestamp,
    auctionAddress: event.log.address,
  });
});
```

## Option 2: The Graph (Decentralized)

Hosted or self-hosted subgraph.

```yaml
# subgraph.yaml
dataSources:
  - kind: ethereum
    name: AuctionManager
    network: base
    source:
      address: "0x..."
      abi: AuctionManager
      startBlock: 12345678
    mapping:
      kind: ethereum/events
      handlers:
        - event: BidPlaced(indexed address,uint256,uint256)
          handler: handleBidPlaced
```

```typescript
// src/mapping.ts
export function handleBidPlaced(event: BidPlaced): void {
  let bid = new Bid(event.transaction.hash.toHex());
  bid.bidder = event.params.bidder;
  bid.amount = event.params.amount;
  bid.save();
}
```

## Option 3: Custom Event Listener

Lightweight Node.js listener with a database.

```typescript
import { createPublicClient, http } from 'viem';
import { base } from 'viem/chains';

const client = createPublicClient({ chain: base, transport: http() });

client.watchContractEvent({
  address: auctionAddress,
  abi: AuctionManagerAbi,
  eventName: 'BidPlaced',
  onLogs: async (logs) => {
    for (const log of logs) {
      await db.bids.insert({
        bidder: log.args.bidder,
        amount: log.args.amount.toString(),
        block: log.blockNumber,
      });
    }
  },
});
```

## Events to Index from ZBrick

| Event | Source | What to Store |
|-------|--------|---------------|
| `BidPlaced` | AuctionManager | bidder, amount, totalBid, timestamp |
| `BidWithdrawn` | AuctionManager | bidder, amount, timestamp |
| `PhaseAdvanced` | AuctionManager | newPhase, timestamp |
| `AuctionFinalized` | AuctionManager | winner, amount, timestamp |
| `AuctionCreated` | AuctionFactory | auctionAddress, tokenId, admin |
| `Transfer` | HouseNFT | from, to, tokenId |

## Comparison

| Feature | Ponder | The Graph | Custom |
|---------|--------|-----------|--------|
| Language | TypeScript | AssemblyScript | Any |
| Hosting | Self-hosted | Decentralized or hosted | Self-hosted |
| Setup speed | Fast | Medium | Fast |
| GraphQL API | Yes | Yes | No (build your own) |
| Factory support | Yes | Yes (templates) | Manual |
| Cost | Server costs | GRT tokens or hosted fees | Server costs |
