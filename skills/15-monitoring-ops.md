# Skill: Monitoring & Operations (Future)

> Tools for watching live contracts, managing treasuries, and responding to incidents.

## Contract Monitoring

### Tenderly

Real-time alerts on contract events and state changes.

```bash
# Install CLI
npm install -g @tenderly/cli

# Monitor a contract
tenderly export --project zbrick --network base
```

- Transaction simulation before broadcast
- Revert debugging with full stack trace
- Alert on: large bids, phase changes, pause events, failed txs
- Gas profiling per function call

### OpenZeppelin Defender (Sentinel)

Automated monitoring and response.

```yaml
# Monitor for emergency events
sentinel:
  name: "ZBrick Pause Monitor"
  network: base
  addresses:
    - "0x..."  # AuctionManager
  conditions:
    - event: Paused(address)
  notification:
    - type: slack
      channel: "#zbrick-alerts"
```

### Custom Alerts (Simple)

```typescript
// Node.js watcher
import { createPublicClient, http, parseAbiItem } from 'viem';
import { base } from 'viem/chains';

const client = createPublicClient({ chain: base, transport: http() });

client.watchContractEvent({
  address: auctionAddress,
  abi: AuctionManagerAbi,
  eventName: 'BidPlaced',
  onLogs: (logs) => {
    for (const log of logs) {
      if (log.args.totalBid > 50_000_000n * 10n ** 6n) {
        sendSlackAlert(`Large bid: $${log.args.totalBid / 10n ** 6n}M from ${log.args.bidder}`);
      }
    }
  },
});
```

## Treasury Management

### Gnosis Safe

Multi-signature wallet for holding auction proceeds.

- Require 2-of-3 or 3-of-5 signatures for withdrawals
- Transaction builder for batch operations
- Spending limits for operational accounts

### Safe SDK (Programmatic)

```typescript
import Safe from '@safe-global/protocol-kit';

const safe = await Safe.init({
  provider: rpcUrl,
  safeAddress: treasuryAddress,
});

// Propose a transaction
const tx = await safe.createTransaction({
  transactions: [{
    to: recipientAddress,
    value: '0',
    data: encodedFunctionCall,
  }],
});
```

## Incident Response Playbook

### Scenario: Vulnerability Discovered

```
1. PAUSE     → Call auction.pause() immediately
2. ASSESS    → Determine scope and affected funds
3. COMMUNICATE → Notify users via frontend banner
4. FIX       → Deploy fix or use emergencyWithdraw
5. UNPAUSE   → Resume operations after verification
```

### Scenario: Phase Stuck (Admin Unavailable)

```
1. Contact admin key holders
2. If emergency: use emergencyWithdrawNFT() + emergencyWithdrawFunds()
3. If key lost: funds recoverable by bidders via withdrawBid()
```

### Emergency Functions Available

| Function | What It Does | When to Use |
|----------|-------------|-------------|
| `pause()` | Stops all bid operations | Vulnerability found |
| `unpause()` | Resumes operations | After fix verified |
| `emergencyWithdrawFunds()` | Sends all USDC to owner | Contract compromised |
| `emergencyWithdrawNFT()` | Returns NFT to owner | Auction abandoned |

## Analytics

### Dune Analytics

SQL queries over blockchain data.

```sql
-- Total bid volume per auction
SELECT
  auction_address,
  SUM(amount) / 1e6 as total_volume_usd,
  COUNT(DISTINCT bidder) as unique_bidders
FROM zbrick.AuctionManager_BidPlaced
GROUP BY auction_address
ORDER BY total_volume_usd DESC
```

### Key Metrics to Track

| Metric | Source |
|--------|--------|
| Total bids per auction | `BidPlaced` events |
| Unique bidders | `BidPlaced` distinct addresses |
| Average bid size | Sum of amounts / count |
| Phase duration actual vs configured | `PhaseAdvanced` timestamps |
| Withdrawal rate | `BidWithdrawn` / `BidPlaced` |
| Participation fee revenue | `hasPaid` count * fee amount |
