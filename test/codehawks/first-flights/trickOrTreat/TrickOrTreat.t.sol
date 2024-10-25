// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "./../../../../src/codehawks/first-flights/trick-or-treat/TrickOrTreat.sol";

contract TrickOrTreatTest is Test {
    SpookySwap protocol;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    event TreatAdded(string name, uint256 cost, string metadataURI);

    function setUp() public {
        vm.deal(user, 1 ether);
        vm.deal(user2, 1 ether);

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

    function testTreatOverrides() public {
        protocol.addTreat("candy", 0.1 ether, "uri1");
        protocol.addTreat("candy", 0.2 ether, "uri2");
        uint256 tokenId3 = protocol.nextTokenId();
        protocol.addTreat("candy", 0.3 ether, "uri3");
        //confirm 3 treats were added
        uint256 treats = (protocol.getTreats()).length;
        assertEq(treats, 3);
        //update latest "candy token"
        protocol.setTreatCost("candy", 0.5 ether);
        //token 1 and 2 are not accesible by no means
        (string memory name, uint256 cost,) = protocol.treatList("candy");

        assert(cost == 0.5 ether && Strings.equal(name, "candy"));
        //TrickOrTreat are applied to latest candy
        vm.prank(user);
        //Buy candy "will purchase third"
        protocol.trickOrTreat{ value: 1 ether }("candy");

        string memory uri = protocol.tokenURI(tokenId3);
        assert(Strings.equal(uri, "uri3"));
    }

    function testSameMetadaForMultipleTokenIds() public {
        protocol.addTreat("candy", 0.1 ether, "uri1");
        uint256 tokenId1 = protocol.nextTokenId();
        vm.prank(user);
        protocol.trickOrTreat{ value: 0.2 ether }("candy");

        uint256 tokenId2 = protocol.nextTokenId();
        vm.prank(user2);
        protocol.trickOrTreat{ value: 0.2 ether }("candy");

        string memory metadata1 = protocol.tokenURI(tokenId1);
        string memory metadata2 = protocol.tokenURI(tokenId2);

        assert(Strings.equal(metadata1, metadata2));
    }
}