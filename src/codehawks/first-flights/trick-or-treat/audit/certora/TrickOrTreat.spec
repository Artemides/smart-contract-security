/*
    TrickOrTreat Formal Verification
*/



methods {
    function addTreat(string memory _name, uint256 _rate, string memory _metadataURI)  external;
    function trickOrTreat(string name) external;
    function treatList(string Message) external returns (string, uint256, string) envfree;
    function nextTokenId() external returns uint256 envfree;
    function resolveTrick(uint256) external;
    function ownerOf(uint256) external returns address envfree;
    function tokenIdToTreatName(uint256) external returns string envfree;
    function pendingNFTsAmountPaid(uint256) external returns uint256 envfree;
}

ghost bool treatOverridden;
ghost mathint treatsWithZeroPrice;
ghost mapping(uint256 => address) pendingNFTsMirror;
ghost mapping(uint256 => uint256) pendingAmountMirror;
ghost mapping(address => uint256) callMirror;


//listen to writes at treatList(name).name
hook Sstore treatList[KEY string str].cost uint256 cost{
    if(cost < 1){
        treatsWithZeroPrice = treatsWithZeroPrice + 1;
    }
}

hook Sstore pendingNFTs[KEY uint256 tokenId] address buyer {
    pendingNFTsMirror[tokenId] = buyer;
}
hook Sstore pendingNFTsAmountPaid[KEY uint256 tokenId] uint256 amount {
    pendingAmountMirror[tokenId] = amount;
}
hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    callMirror[addr] = value;
}

function emptyTreat() returns (string, uint256, string){
    return ("",0,"");
}

function getTreatName(string _name) returns string{
    string name; uint256 cost; string metadataURI;
    ( name,  cost,  metadataURI) = treatList(_name);
    return name;
}
/*
    only treats with cost above zero are able to be tricked    
*/
invariant treatCostsAlwaysAboutZero()
    treatsWithZeroPrice == 0;


/*
    treats cannot override already added treats
*/
invariant treatsCannotBeOverriden(string name)
     getTreatName(name) == ""
     {
        preserved addTreat(string _name, uint256 _rate, string _metadataURI) with (env e){
        }
     }
    
/*
    Resolving pending treats alaways const 2 * cost 
*/

rule userGetsRepaidIfEthSentExceeds(string name){
    uint256 cost;
    string s;
    (s, cost, s)  = treatList(name);
    require cost > 0;
    
    env e; 
    require(e.msg.sender != 0);
    require(e.msg.value > 0);

    uint256 preBalance = nativeBalances[e.msg.sender];    
    uint256 tokenId = nextTokenId();

    callMirror[e.msg.sender] = 0;
    trickOrTreat(e,name);

    require (pendingNFTsMirror[tokenId] == 0);

    uint256 repay = callMirror[e.msg.sender];
    callMirror[e.msg.sender] = 0;
    
    //repay == sent - requiredCost
    mathint requiredCost = e.msg.value - repay;

    assert requiredCost == cost/2 || requiredCost == cost || requiredCost == 2 * cost, "Required cost not sppookied as half, exact or double";
}

/*
    Note: Pending treats can be resolved at double price
*/

rule onlyPendingTricksAreResolved(uint256 tokenId){
    env e;
    resolveTrick(e,tokenId);

    address owner = ownerOf(tokenId);
    assert owner == e.msg.sender;
    
}

/*
    Note: Resolved Trick costs double
*/

rule resolvedTricksCostsDouble(uint256 tokenId){
    string name = tokenIdToTreatName(tokenId);
    uint256 cost;
    string s;
    (s, cost, s)  = treatList(name);
    env e;

    callMirror[e.msg.sender] = 0;
    resolveTrick(e,tokenId);
    //prevPaid
    //Paid
    //refund = totalPaid - reqCost
    //reqCost =totalPaid - refdund
    uint256 repay = callMirror[e.msg.sender];
    callMirror[e.msg.sender] = 0;
    mathint requiredCost = e.msg.value + pendingNFTsAmountPaid(tokenId) - repay;

    assert requiredCost == 2 * cost, "Required cost not sppookied as half, exact or double";
}
