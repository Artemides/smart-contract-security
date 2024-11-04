/*
* Verificaiton of erc20
*/


methods {
    function totalSupply() external returns uint256 envfree;
    function transferFrom(address,address,uint256) external;
    function transfer(address,uint256) external;
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address,address) external returns uint256 envfree;
    function _owner()external returns address envfree;
}

rule integrity_of_transferFrom(){
    //whenever a transferFrom occurs, owner's balance is decreased and recipient is increased by amount
    //executor allowances are also decreased
    //without affecting others balances

    env e;
    address sender;
    address recipient;
    require(sender != recipient);

    uint256 amount;
    require amount != 0;
    
    mathint recipientBalanceBefore = balanceOf(recipient);
    
    uint256 senderAllowanceBefore = allowance(sender, e.msg.sender);

    transferFrom(e,sender,recipient,amount);

    uint256 senderAllowance = allowance(sender, e.msg.sender);
    mathint recipientBalance = balanceOf(recipient);
    
    assert senderAllowanceBefore > senderAllowance, "Allowance must decrease after a transfer";
    assert recipientBalanceBefore + amount ==  recipientBalance, "Recipient balance not increases";
}

rule only_owners_may_change_totalSupply(method f){
    //totalSupply modifiers
    //mint transfer transferFrom burn
    env e;

    uint256 supplyBefore = totalSupply();

    calldataarg args;
    f(e,args);

    uint256 supplyAfter = totalSupply();

    assert  supplyAfter != supplyBefore => e.msg.sender == _owner() ;
}

rule doesNotAffectThirdPartyBalance(method f){
    env e;
    address from;
    address to;  
    address user;
    require (from != user) && (to != user);
    uint256 userBalanceBefore = balanceOf(user);
    callFunctionWithParams(e,f,from,to);

    assert  balanceOf(user) == userBalanceBefore, "User affected by other protocol operations";    
}

rule onlyCertainFunctionCanModifyBalances(method f){
    address user;
    uint256 balanceBefore = balanceOf(user);
    env e;
    calldataarg args;
    f(e,args);
    
    assert balanceBefore != balanceOf(user) => (
        f.selector == sig:transfer(address,uint256).selector ||
        f.selector == sig:transferFrom(address,address,uint256).selector ||
        f.selector == sig:mint(address,uint256).selector ||
        f.selector == sig:burn(address,uint256).selector
    ), 
    "Balances changed from functions other than, transfer, transferFom, mint or burn";
    
}

function callFunctionWithParams(env e,method f, address from, address to){
    uint256 amount;
    if(f.selector == sig:transfer(address, uint256).selector){
        require e.msg.sender != from;
        transfer(e,to,amount);
    } else if (f.selector == sig:allowance(address,address).selector){
        allowance(e,from,to);
    } else if (f.selector == sig:approve(address,uint256).selector){
        approve(e,to,amount);
    } else if (f.selector == sig:transferFrom(address, address, uint256).selector) {
        transferFrom(e, from, to, amount);
    } else if (f.selector == sig:increaseAllowance(address, uint256).selector) {
        increaseAllowance(e, to, amount);
    } else if (f.selector == sig:decreaseAllowance(address, uint256).selector) {
        decreaseAllowance(e, to, amount);
    } else if (f.selector == sig:mint(address, uint256).selector) {
        mint(e, to, amount);
    } else if (f.selector == sig:burn(address, uint256).selector) {
        burn(e, from, amount);
    } else{
        calldataarg args;
        f(e,args);
    }
}