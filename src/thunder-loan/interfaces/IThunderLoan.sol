// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IThunderLoan {
    //e is token minted AssetToken on minting Liquidity?
    //@audit @param token: is IERC20 token
    function repay(address token, uint256 amount) external;
}
