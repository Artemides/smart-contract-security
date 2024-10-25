// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "./../../../../src/codehawks/first-flights/trick-or-treat/TrickOrTreat.sol";

contract TrickOrTreatTest is Test {
    SpookySwap protocol;
    address user = makeAddr("user");

    event TreatAdded(string name, uint256 cost, string metadataURI);

    function setUp() public {
        vm.deal(user, 1 ether);
        SpookySwap.Treat[] memory treats;
        protocol = new SpookySwap(treats);
    }

    function testDeploysSettingInitialTreats(SpookySwap.Treat[] memory treats) public {
        SpookySwap _protocol = new SpookySwap(treats);
        uint256 addedTreats = (_protocol.getTreats()).length;
        assertEq(addedTreats, treats.length);
    }

    function testLackOfZeroCostVerification() public {
        vm.expectEmit();
        emit TreatAdded("candy", 0, "");
        protocol.addTreat("candy", 0, "");

        vm.expectRevert(bytes("Treat must cost something."));
        protocol.setTreatCost("candy", 1 ether);

        vm.expectRevert(bytes("Treat cost not set."));
        protocol.trickOrTreat{ value: 0.1 ether }("candy");
    }

    function testTreatCostManipulation() public {
        protocol.addTreat("candy", 0.1 ether, "");

        vm.prank(user);
        //send 0.2 ether in case of price tricked at double
        protocol.trickOrTreat{ value: 0.2 ether }("candy");

        protocol.setTreatCost("candy", 0.0001 ether);
        protocol.setTreatCost("candy", 0);
    }
}
