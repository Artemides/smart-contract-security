/*
    Verification of English Auctiom
    Protocol for selling an NFT in terms of ERC20 token
*/


invariant highestBidAlwaysGreaterOrEqual(address c)
    highestBid() >= bids(c);

invariant highestBidder()
    highestBidder() != 0 => bids(highestBidder()) == highestBid();

