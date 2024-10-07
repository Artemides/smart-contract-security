// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { TokenFactory } from "../../src/boss-bridge/TokenFactory.sol";
import { L1Token } from "../../src/boss-bridge/L1Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory tokenFactory;
    address owner = makeAddr("owner");

    function setUp() public {
        vm.prank(owner);
        tokenFactory = new TokenFactory();
    }

    function testAddToken() public {
        vm.prank(owner);
        address tokenAddress = tokenFactory.deployToken("TEST", type(L1Token).creationCode);
        assertEq(tokenFactory.getTokenAddressFromSymbol("TEST"), tokenAddress);
    }
}
