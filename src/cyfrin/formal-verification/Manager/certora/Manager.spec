

methods{
    function getCurrentManager(uint256)external returns address envfree;
    function getPendingManager(uint256) external returns address envfree;
    function isActiveManager(address) external returns bool envfree;
    function createFund(uint256) external;
    function claimManagement(uint256 fundId) external;
}

function isManaged(uint256 fundId) returns bool{
    return getCurrentManager(fundId) != 0;
}

invariant managerIsActive(uint256 fundId)
    isManaged(fundId) <=> isActiveManager(getCurrentManager(fundId))
    {
        preserved claimManagement(uint256 fundId2) with (env e){
            requireInvariant uniqueManager(fundId,fundId2);
        }
    }


invariant uniqueManager(uint256 fundId,uint256 fundId2)
    ((fundId != fundId2) && isManaged(fundId)) => (getCurrentManager(fundId) != getCurrentManager(fundId2)) 
    {
        preserved {
            requireInvariant managerIsActive(fundId);
            requireInvariant managerIsActive(fundId2);
        }
    }

