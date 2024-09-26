// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import {ITSwapPool} from "../interfaces/ITSwapPool.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OracleUpgradeable is Initializable {
    //i make sure factory and pool are trusty and bug-free
    address private s_poolFactory;
    //i make sure to initialize Oracle once deployed
    function __Oracle_init(
        address poolFactoryAddress
    ) internal onlyInitializing {
        __Oracle_init_unchained(poolFactoryAddress);
    }

    function __Oracle_init_unchained(
        address poolFactoryAddress
    ) internal onlyInitializing {
        s_poolFactory = poolFactoryAddress;
    }
    //@audit price manipulation is a risk in Token-Weth TSwapPool
    function getPriceInWeth(address token) public view returns (uint256) {
        address swapPoolOfToken = IPoolFactory(s_poolFactory).getPool(token);
        return ITSwapPool(swapPoolOfToken).getPriceOfOnePoolTokenInWeth();
    }

    function getPrice(address token) external view returns (uint256) {
        return getPriceInWeth(token);
    }

    function getPoolFactoryAddress() external view returns (address) {
        return s_poolFactory;
    }
}
