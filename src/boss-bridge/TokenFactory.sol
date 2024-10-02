// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title TokenFactory
 * @dev Allows the owner to deploy new ERC20 contracts
 * @dev This contract will be deployed on both an L1 & an L2
 */
contract TokenFactory is Ownable {
    //q tokens migh have the same symbol?
    mapping(string tokenSymbol => address tokenAddress)
        private s_tokenToAddress;

    event TokenDeployed(string symbol, address addr);

    //i central authority risk
    constructor() Ownable(msg.sender) {}

    /*
     * @dev Deploys a new ERC20 contract
     * @param symbol The symbol of the new token
     * @param contractBytecode The bytecode of the new token
     */

    //@audit bytecode on different chains might differ: create won't work on ZkSync

    function deployToken(
        string memory symbol,
        bytes memory contractBytecode
    ) public onlyOwner returns (address addr) {
        assembly {
            addr := create(
                0,
                add(contractBytecode, 0x20),
                mload(contractBytecode)
            )
        }
        s_tokenToAddress[symbol] = addr;
        emit TokenDeployed(symbol, addr);
    }

    function getTokenAddressFromSymbol(
        string memory symbol
    ) public view returns (address addr) {
        return s_tokenToAddress[symbol];
    }
}
