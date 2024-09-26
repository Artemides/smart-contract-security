// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

interface IPoolFactory {
    //e function use to retrieve the asociated Pool
    function getPool(address tokenAddress) external view returns (address);
}
