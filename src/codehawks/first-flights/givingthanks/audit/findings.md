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

# Low

# [L-1] `_registry` should be set instead of msg.sender at construction

**Description:** during construction the `CharityRegistry` is being set as `msg.sender` instead of `_registry` param.

```javascript
    constructor(address _registry) ERC721("DonationReceipt", "DRC") {
    @>  registry = CharityRegistry(msg.sender);
        owner = msg.sender;
        tokenCounter = 0;
    }
```

**Impact:** Donation cannot proceed unless `CharityRegistry` gets updated

**Proof of Concept:**

CharityRegistry wronly instantiated at construction. Hence, Donations cannot proceed.

- **Owner - Deployer:** deploy the protocol (`_registry` param unused)

```javascript
   function testImpededDonations() public {
        // run setUp which deploys as follows
        // new GivingThanks(address(registryContract));
        vm.deal(donor, 10 ether);
        vm.expectRevert();
        vm.prank(donor);
        charityContract.donate{ value: 1 ether }(charity);
    }
```
