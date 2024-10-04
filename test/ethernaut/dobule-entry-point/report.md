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
