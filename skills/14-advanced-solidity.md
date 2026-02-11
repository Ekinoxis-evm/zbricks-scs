# Skill: Advanced Solidity Patterns (Future)

> Patterns to extend ZBrick with more sophisticated on-chain features.

## EIP-712: Typed Structured Data Signing

Off-chain signed messages for gasless approvals or meta-transactions.

```solidity
bytes32 constant BID_TYPEHASH = keccak256(
    "Bid(address bidder,uint256 amount,uint256 nonce,uint256 deadline)"
);

function placeBidWithSignature(
    address bidder,
    uint256 amount,
    uint256 deadline,
    uint8 v, bytes32 r, bytes32 s
) external {
    bytes32 structHash = keccak256(abi.encode(
        BID_TYPEHASH, bidder, amount, nonces[bidder]++, deadline
    ));
    bytes32 digest = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(digest, v, r, s);
    require(signer == bidder, "Invalid signature");
    // Process bid...
}
```

**Use case:** Allow backend to submit bids on behalf of users (gasless bidding).

## EIP-2981: NFT Royalties

On-chain royalty standard for secondary market sales.

```solidity
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract HouseNFT is ERC721, ERC2981 {
    constructor() {
        _setDefaultRoyalty(treasury, 250); // 2.5% royalty
    }
}
```

## Merkle Proofs: Allowlisted Bidders

Verify bidder is on a whitelist without storing the full list on-chain.

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

bytes32 public merkleRoot;

function placeBid(uint256 amount, bytes32[] calldata proof) external {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(proof, merkleRoot, leaf), "Not allowlisted");
    // Process bid...
}
```

## Permit2: One-Signature Approve + Transfer

Uniswap's Permit2 lets users approve and transfer tokens in one signature.

```solidity
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

IPermit2 public immutable permit2;

function placeBidWithPermit(
    uint256 amount,
    IPermit2.PermitSingle calldata permit,
    bytes calldata signature
) external {
    permit2.permit(msg.sender, permit, signature);
    permit2.transferFrom(msg.sender, address(this), uint160(amount), address(paymentToken));
    // Process bid...
}
```

**Use case:** Users sign once instead of approve tx + bid tx.

## Account Abstraction (ERC-4337)

Smart contract wallets for better UX.

- Gasless transactions (paymaster sponsors gas)
- Social recovery (recover wallet via guardians)
- Session keys (limited permissions for dApps)
- Batch transactions (approve + bid in one click)

## Chainlink Oracles

### Price Feeds

```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

AggregatorV3Interface priceFeed = AggregatorV3Interface(0x...);

function getLatestPrice() public view returns (int) {
    (, int price,,,) = priceFeed.latestRoundData();
    return price; // ETH/USD with 8 decimals
}
```

**Use case:** Display bid amounts in USD, or accept ETH bids with USD-denominated floor.

### VRF (Verifiable Random Function)

```solidity
// Request randomness for tiebreaker or lottery
uint256 requestId = COORDINATOR.requestRandomWords(...);
```

## Upgradeable Contracts (UUPS)

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AuctionManagerV2 is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
```

**Tradeoff:** Adds complexity but allows fixing bugs post-deployment.

## Cross-Chain Messaging

### LayerZero / Chainlink CCIP

```solidity
// Send message to another chain
endpoint.send{value: fee}(
    dstChainId,
    abi.encode(bidder, amount),
    refundAddress,
    zroPaymentAddress,
    adapterParams
);
```

**Use case:** Bid on Base auction from Ethereum or Arbitrum.
