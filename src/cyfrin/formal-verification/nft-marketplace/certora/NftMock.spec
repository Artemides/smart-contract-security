/*
* verification of NFTMock
*/


methods {
    function totalSuply() external returns uint256 envfree;
    function balanceOf(address minter) external envfree;
    function mint() external;
}

invariant totalSupplyNotNegative()
    totalSuply() >= 0;   

rule minting_mints_one_nft() {
    env e;
    address minter;
    require(e.msg.value == 0);
    require(e.msg.sender == minter);
    uint256 balanceBefore = balanceOf(minter);

    currentContract.mint(e);

    uint256 balanceAfter = balanceOf(minter);
    assert balanceAfter  ==  balanceBefore + 1, "Should mint only 1 nft token";
    
}
   
rule totalSuply_never_changes(method func){
    uint256 totalSuplyBefore = totalSuply();

    env e;
    calldataarg arg;
    func(e,arg);
    
    assert totalSuply() == totalSuplyBefore, "Total Supply never changes";
    
}