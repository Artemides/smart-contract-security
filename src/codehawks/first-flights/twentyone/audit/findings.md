# Findings

# Medium

## [M-1] Users get unpaid if no sufficient balance for payouts

**Description:** Payouts are collected from players, but they are only sufficient to cover half of the active players in the event that all of them win. Additionally, users can start a new game even when there are not enough funds to cover payouts in the case of wins.

**Impact:** The game is unfair with the winners who might not receive their payout if they win.

**Proof of Concept:**

1. Start a Game =>

   - User Starts a Game (1 ether)
   - `TwentyOne` collected 1 ether only (payouts are 2 ether per winner)

```javascript
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
```

2. Uncovered Payouts
   - 4 player (4 ether)
   - Half players paid only (4 ether covers only 2 winners).
   - Subsequent winners unpaid (revert due to out of funds).

```javascript
    //make win a player
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

    function test_NotEnoughToPayForAll() public {
        address player3 = makeAddr("player3");
        address player4 = makeAddr("player4");
        vm.deal(player3, 1 ether);
        vm.deal(player4, 1 ether);
        //play with 4 players
        vm.prank(player1);
        twentyOne.startGame{ value: 1 ether }();
        vm.prank(player2);
        twentyOne.startGame{ value: 1 ether }();
        vm.prank(player3);
        twentyOne.startGame{ value: 1 ether }();
        vm.prank(player4);
        twentyOne.startGame{ value: 1 ether }();
        //make win half of them
        _makeWin(player1);
        _makeWin(player3);
        //third winner won't be paid (Out of Funds)
        vm.expectRevert();
        _makeWin(player4);
    }
```

**Recommended Mitigation:**

- Start a new game if the worst case covered (all players win).
- Initiate the Game with at least 2 ether.
- Monitor its balance otherwise game unplayable.

```diff

+    uint256 activePlayers;

    function startGame() public payable returns (uint256) {
+        require(_canPayout(),"Could not be payout")
        //impl
+        ++activePlayers;
    }
    function endGame(address player, bool playerWon) internal {
        //impl
+        --activePlayers;
    }

    /**
     * @notice determines if the joined player can be paid out
     */

+    function _canPayout() internal view returns (bool) {
+        return address(this).balance >= (activePlayers + 1) * 2;
+    }

```
