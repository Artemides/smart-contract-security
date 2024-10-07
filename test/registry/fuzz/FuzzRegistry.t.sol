// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Registry} from "../../../src/registry/Registry.sol";

contract RegistryTest is Test {
    Registry registry;
    address alice;

    error PaymentNotEnough(uint256 expected, uint256 actual);

    function setUp() public {
        alice = makeAddr("alice");

        registry = new Registry();
    }

    // function test_RegistrySuccessfull(uint256 _value) public {
    //     uint256 priceOffset = 0.5 ether;
    //     uint256 price = registry.PRICE();

    //     uint256 value = bound(_value, price, price + priceOffset);

    //     vm.deal(alice, value);
    //     vm.prank(alice);
    //     registry.register{value: value}();
    //     uint256 change = value > price ? value - price : 0;

    //     uint256 endingBalance = address(alice).balance;
    //     uint256 expectedEndingBalance = value - price + change;

    //     assertEq(endingBalance, expectedEndingBalance, "Change not received");
    //     assertTrue(registry.isRegistered(alice), "Ungeristered");
    // }

    function test_RegistryUnSuccessfull(uint256 value) public {
        uint256 price = registry.PRICE();
        if (value > price) {
            return;
        }

        vm.deal(alice, value);
        vm.expectRevert(
            abi.encodeWithSelector(PaymentNotEnough.selector, price, value)
        );
        vm.prank(alice);
        registry.register{value: value}();
    }
    /** Code your fuzz test here */
}
