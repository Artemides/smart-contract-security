// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying;

    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
    }

    // non-LGT erc20 tokens transfer vault balances to a recipient
    // if accidentally tokens are sent to vault use sweep to recover all

    // LGT and ERC20 with DelegateERC20  ->
    //    if delegate -> swaps for DET
    //    else -> recovers ERC20

    // malicious DelegateERC20 can Swap then Recover
    // anyone can drain LGT or DET tokens the first time depending on delegation

    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
        console.log(">>>Balance", token.balanceOf(address(this)));
    }
}
