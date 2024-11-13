# Giving Thanks Report

## High

## Medium

## [M-1] wrong verification at `CharityRegistry:isVerified` function

**Description:** `CharityRegistry:isVerified` function uses `registeredCharities` instead of `verifiedCharities` to properly determine `Charities` verification.

`registeredCharities` is intented for registering only.

```javascript
    function isVerified(address charity) public view returns (bool) {
        //
      @> return registeredCharities[charity];
    }
```

**Impact:** Any registered `Charity` is able to receive donations at `GivingThanks:donate`.

**Proof of Concept:**

1. **Donor:** calls donate to an any charity.
2. **Charity:** at least registered bypasses `CharityRegistry:isVerified` check.
3. **Charity:** receives donation amount.
4. **Donor:** receives the Donation Receipt NFT.

```javascript
    function testRegisteredCharitiesReceiveDonations() public {
        address anyCharity = makeAddr("anyCharity");
        //only register
        registryContract.registerCharity(anyCharity);
        vm.deal(donor, 10 ether);
        vm.prank(donor);
        charityContract.donate{ value: 1 ether }(anyCharity);

        assertEq(anyCharity.balance, 1 ether);
    }
```

**Recommended Mitigation:**

- use `verifiedCharities` as it should.

```diff
    function isVerified(address charity) public view returns (bool) {
-       return registeredCharities[charity];
+       return verifiedCharities[charity];
    }
```
