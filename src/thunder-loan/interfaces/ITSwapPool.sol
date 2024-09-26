// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

interface ITSwapPool {
    //e query sport price of token in terms of Weth
    function getPriceOfOnePoolTokenInWeth() external view returns (uint256);
}
