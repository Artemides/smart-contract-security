/*
*verification of BadGasNftMarketplace
*/

using NftMarketplace as market;
using GasBadNftMarketplace as gasMarket;

methods {
    function _.safeTransferFrom(address,address,uint256) external => DISPATCHER(true);

    function _.onERC721Receive(address,address,uint256,bytes) external returns bytes4;
    
    function getListing(address, uint256) external returns INftMarketplace.Listing envfree;

    function getProceeds(address) external returns uint256 envfree;
}

ghost mathint listingUpdatesCount {
    init_state axiom listingUpdatesCount == 0;
}
ghost mathint log4Count {
    init_state axiom log4Count == 0;
}

hook Sstore s_listings[KEY address nft][KEY uint256 tokenId].price uint256 price{
     listingUpdatesCount = listingUpdatesCount + 1;
}

hook LOG4(uint offset,uint length,bytes32 t1,bytes32 t2,bytes32 t3,bytes32 t4){
    log4Count = log4Count + 1;
}

invariant anytime_mapping_updates_emit_evets()
    listingUpdatesCount <= log4Count;


rule any_function_execution_maintains_same_state_on_both_contracts(method f, method g)
    filtered {
        f -> f.selector == g.selector
    }
{
    env e;
    calldataarg args;

    address seller;

    address user;
    uint256 tokenId;

    require(market.getProceeds(e,seller).price == gasMarket.getProceeds(e,seller).price);
    require(market.getListing(e,user,tokenId).price == gasMarket.getListing(e,user,tokenId).price);
    require(market.getListing(e,user,tokenId).seller == gasMarket.getListing(e,user,tokenId).seller);

    market.f(e,arg);
    gasMarket.g(e.arg);

    assert(market.getProceeds(e,seller).price == gasMarket.getProceeds(e,seller).price);
    assert(market.getListing(e,user,tokenId).price == gasMarket.getListing(e,user,tokenId).price);
    assert(market.getListing(e,user,tokenId).seller == gasMarket.getListing(e,user,tokenId).seller);


}