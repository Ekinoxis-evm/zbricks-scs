# Skill: Frontend Integration (Future)

> Building a web UI to interact with ZBrick contracts.

## Recommended Stack

| Layer | Tool | Why |
|-------|------|-----|
| Framework | Next.js 14+ (App Router) | SSR, API routes, React Server Components |
| Ethereum lib | Viem + Wagmi v2 | Type-safe, modern, built for React |
| Wallet UI | RainbowKit or ConnectKit | Multi-wallet support out of the box |
| Styling | Tailwind CSS | Rapid UI development |
| State | TanStack Query (via Wagmi) | Automatic cache, refetch, loading states |

## Viem + Wagmi Setup

```typescript
// wagmi.config.ts
import { http, createConfig } from 'wagmi';
import { base, baseSepolia } from 'wagmi/chains';

export const config = createConfig({
  chains: [base, baseSepolia],
  transports: {
    [base.id]: http(),
    [baseSepolia.id]: http(),
  },
});
```

## Contract Integration

```typescript
import addresses from '@/deployments/addresses.json';
import AuctionManagerAbi from '@/deployments/abi/AuctionManager.json';

// Read auction state
const { data: auctionState } = useReadContract({
  address: auctionAddress,
  abi: AuctionManagerAbi,
  functionName: 'getAuctionState',
});

// Place a bid (write)
const { writeContract } = useWriteContract();

function placeBid(amount: bigint) {
  writeContract({
    address: auctionAddress,
    abi: AuctionManagerAbi,
    functionName: 'placeBid',
    args: [amount],
  });
}
```

## USDC Approval Flow

Users must approve USDC before bidding:

```typescript
// Step 1: Approve USDC spending
writeContract({
  address: USDC_ADDRESS,
  abi: erc20Abi,
  functionName: 'approve',
  args: [auctionAddress, amount],
});

// Step 2: Place bid (after approval tx confirms)
writeContract({
  address: auctionAddress,
  abi: AuctionManagerAbi,
  functionName: 'placeBid',
  args: [amount],
});
```

## Key Pages to Build

| Page | Features |
|------|----------|
| Auction List | All active auctions from factory, status badges |
| Auction Detail | Current bid, phase, timer, bid form |
| My Bids | User's active bids, withdraw button |
| Admin Panel | Advance phase, finalize, pause/unpause |

## Real-Time Updates

Listen to contract events for live UI:

```typescript
useWatchContractEvent({
  address: auctionAddress,
  abi: AuctionManagerAbi,
  eventName: 'BidPlaced',
  onLogs(logs) {
    // Update UI when new bid arrives
    refetchAuctionState();
  },
});
```

## NFT Metadata Display

```typescript
// Fetch current phase metadata
const { data: tokenURI } = useReadContract({
  address: nftAddress,
  abi: HouseNFTAbi,
  functionName: 'tokenURI',
  args: [tokenId],
});

// tokenURI returns ipfs://... URL
// Resolve via IPFS gateway: https://ipfs.io/ipfs/...
```
