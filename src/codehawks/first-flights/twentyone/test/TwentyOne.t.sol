// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { TwentyOne } from "../TwentyOne.sol";

contract TwentyOneTest is Test {
    TwentyOne public twentyOne;

    address player1 = address(0x123);
    address player2 = address(0x456);

    function setUp() public {
        twentyOne = new TwentyOne();
        vm.deal(player1, 10 ether); // Fund player1 with 10 ether
        vm.deal(player2, 10 ether); // Fund player2 with 10 ether
    }

    function test_StartGame() public {
        vm.startPrank(player1); // Start acting as player1

        uint256 initialBalance = player1.balance;

        // Start the game with 1 ether bet
        twentyOne.startGame{ value: 1 ether }();

        // Check that the player's balance decreased by 1 ether
        assertEq(player1.balance, initialBalance - 1 ether);

        // Check that the player's hand has two cards
        uint256[] memory playerCards = twentyOne.getPlayerCards(player1);
        assertEq(playerCards.length, 2);

        vm.stopPrank();
    }

    function test_Hit() public {
        vm.startPrank(player1); // Start acting as player1

        twentyOne.startGame{ value: 1 ether }();

        // Initial hand size should be 2
        uint256[] memory initialCards = twentyOne.getPlayerCards(player1);
        assertEq(initialCards.length, 2);

        // Player hits (takes another card)
        twentyOne.hit();

        // Hand size should increase to 3
        uint256[] memory updatedCards = twentyOne.getPlayerCards(player1);
        assertEq(updatedCards.length, 3);

        vm.stopPrank();
    }

    function test_Call_PlayerWins() public {
        vm.startPrank(player1); // Start acting as player1

        twentyOne.startGame{ value: 1 ether }();

        // Mock the dealer's behavior to ensure player wins
        // Simulate dealer cards by manipulating state
        vm.mockCall(
            address(twentyOne),
            abi.encodeWithSignature("dealersHand(address)", player1),
            abi.encode(18) // Dealer's hand total is 18
        );

        uint256 initialPlayerBalance = player1.balance;

        // Player calls to compare hands
        twentyOne.call();

        // Check if the player's balance increased (prize payout)
        uint256 finalPlayerBalance = player1.balance;
        assertGt(finalPlayerBalance, initialPlayerBalance);

        vm.stopPrank();
    }

    function test_NotEnoughToPayout() public {
        vm.startPrank(player1); // Start acting as player1

        twentyOne.startGame{ value: 1 ether }();

        // Mock the dealer's behavior to ensure player wins
        // Simulate dealer cards by manipulating state
        vm.mockCall(
            address(twentyOne),
            abi.encodeWithSignature("dealersHand(address)", player1),
            abi.encode(18) // Dealer's hand total is 18
        );

        // Player calls to compare hands
        // Reverted due to OutOfFunds
        vm.expectRevert();
        twentyOne.call();

        vm.stopPrank();
    }

    function test_NotEnoughToPayForAll() public {
        address player3 = makeAddr("player3");
        address player4 = makeAddr("player4");
        vm.deal(player3, 1 ether);
        vm.deal(player4, 1 ether);

        vm.prank(player1);
        twentyOne.startGame{ value: 1 ether }();
        vm.prank(player2);
        twentyOne.startGame{ value: 1 ether }();
        vm.prank(player3);
        twentyOne.startGame{ value: 1 ether }();
        vm.prank(player4);
        twentyOne.startGame{ value: 1 ether }();

        _makeWin(player1);
        _makeWin(player3);
        vm.expectRevert();
        _makeWin(player4);
    }

    function testCardsHigherThan13() public {
        uint256 randomIdx;
        while (randomIdx < 21) {
            randomIdx = uint256(keccak256(abi.encodePacked(block.timestamp, player1, block.prevrandao))) % 52;
            vm.warp(block.timestamp + 1);
        }

        vm.startPrank(player1);
    }

    function _makeWin(address player) internal {
        vm.startPrank(player); // Start acting as player1

        vm.mockCall(
            address(twentyOne),
            abi.encodeWithSignature("dealersHand(address)", player),
            abi.encode(18) // Dealer's hand total is 18
        );
        twentyOne.call();
        vm.stopPrank();
    }
}
