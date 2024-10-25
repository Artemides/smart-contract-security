# Findings

## Ignore

1. Weak `RNG` random number generated

# High

## [H-1] Central Authotities `Owner` can still manipulate tricked `Treats`

**Description:** `Owners` can manipulate the price of an already tricked `Treat`, changing their cost and value, affecting potential `trades` between user with revaluations which affect either positively or negatively initial user `investment`.

**Impact:** users might not find an attractive Protocol or so, due to potential cost `increasement` or `decreasement` made by Central Authority or Protocol's owner.

**Proof of concept:**

```javascript
     function testTreatCostManipulation() public {
        protocol.addTreat("candy", 0.1 ether, "");

        vm.prank(user);
        //send 0.2 ether in case of price tricked at double
        protocol.trickOrTreat{ value: 0.2 ether }("candy");

        protocol.setTreatCost("candy", 0.0001 ether);
        protocol.setTreatCost("candy", 0);
    }
```

**Recommended Mitigation:**

It might depend on the protocol's purpose, changing as follows:

Allowing `Protocol:Owner` treat manipulation, ungrants `Treat:Owners` to take controll over what they have paid for, allowing `Treat:Owner` grants them the freedom of rescaling `costs` as they wish. Hence, Locking `cost` updates once trickedTreats will keep their original values forever.

Although, depending on the protocol, keeping costs, may be considered downsides if meant for `Profitable Approach`.

## [H-2] `SpookySwap:Treat` overrdies previous tokens having the same name

**Description:** Adding treats with the same same, overrides added treats, affecting `treatList[_treatName]` access, which queries the latests.

**Impact:** overrides causing invalidad queries `treatList[_treatName]` makes `SpookySwap:setTreatCost` to update cost of latest treat, whereas by `SpookySwap:trickOrTreat` latests treat will be minted. besides, treats overriden are unusable and waste protocol's resources.

**Proof of concept:**

```javascript
    function testTreatOverrides() public {
        protocol.addTreat("candy", 0.1 ether, "uri1");
        protocol.addTreat("candy", 0.2 ether, "uri2");
        uint256 tokenId3 = protocol.nextTokenId();
        protocol.addTreat("candy", 0.3 ether, "uri3");
        //confirm 3 treats were added
        uint256 treats = (protocol.getTreats()).length;
        assertEq(treats, 3);
        //update latest "candy token"
        protocol.setTreatCost("candy", 0.5 ether);
        //token 1 and 2 are not accesible by no means
        (string memory name, uint256 cost,) = protocol.treatList("candy");

        assert(cost == 0.5 ether && Strings.equal(name, "candy"));
        //TrickOrTreat are applied to latest candy
        vm.prank(user);
        //Buy candy "will purchase third"
        protocol.trickOrTreat{ value: 1 ether }("candy");

        string memory uri = protocol.tokenURI(tokenId3);
        assert(Strings.equal(uri, "uri3"));
    }
```

**Recommneded Mitigation:**
Implement a mapping that indicates which treat name has been already added ti `treatList[_treatName]`, check name uniqueness before adding

```diff
    contract SpookySwap is ERC721URIStorage, Ownable(msg.sender), ReentrancyGuard {
+       mapping(string  => bool) public exists
        /* impl */
        function addTreat(string memory _name, uint256 _rate, string memory _metadataURI) public onlyOwner {
+           require(!exists[_name], "Treat already added");
            treatList[_name] = Treat(_name, _rate, _metadataURI);
            treatNames.push(_name);
            emit TreatAdded(_name, _rate, _metadataURI);
        }
    }

    }
```

# Medium

## [M-1] Lack of `zero-cost` check by `SpookySwap:addTreat`, unables `Treats` of being `SpookySwap:setTreatCost` and `SpookySwap:trickOrTreat`.

**Description:** By adding a new `Treat` either by constructing or calling `SpookySwap:addTreat` no checks for `zero-prices` are set. Consequently by calling`SpookySwap:setTreatCost`, only those with `prices` greater than `0` are allowed to be updated. as well as by calling `SpookySwap:setTreatCost` that updates `Treats` to `zero-cost`, making them unvaluable.

**Impact:** stuck `Treats` in the Protocol, unabling them to be `SpookySwap:trickOrTreat`, having them unusable which effectively waste protocol's resources. although it does not risk `Protocol:funds`.

**Proof of concept:**

```javascript
    function testLackOfZeroCostVerification() public {
        vm.expectEmit();
        emit TreatAdded("candy", 0, "");
        protocol.addTreat("candy", 0, "");

        vm.expectRevert(bytes("Treat must cost something."));
        protocol.setTreatCost("candy", 1 ether);

        vm.expectRevert(bytes("Treat cost not set."));
        protocol.trickOrTreat{ value: 0.1 ether }("candy");
    }
```

**Recommneded Mitigation:**

- Add `zero-check` validation by `SpookySwap:addTreat` and `SpookySwap:setTreatCost`.

```diff
    function addTreat(string memory _name, uint256 _rate, string memory _metadataURI) public onlyOwner {
+       require(_rate > 0);
        treatList[_name] = Treat(_name, _rate, _metadataURI);
        treatNames.push(_name);
        emit TreatAdded(_name, _rate, _metadataURI);
    }

    //@audit treats added with zero-Price won't ever be allowed to be updated
    function setTreatCost(string memory _treatName, uint256 _cost) public onlyOwner {
        //q treats having the same _treatName override one to another;
+       require(_cost > 0);
        require(treatList[_treatName].cost > 0, "Treat must cost something.");
        treatList[_treatName].cost = _cost;
    }
```

# [M-1] Ambiguity in Shared Metadata Usage, NFT treat are expected to be unique in design `ERC721`

**Description:** Without no specification if sharing metadata is itended to do so, `SpookySwap:trickOrTreat` ties a `Treat` along with `tokenId` then attaches a `metadata` as tokenURI, which contradicts the expected uniqueness of NFT's.

**Impact:** Although it does not affect protocol funds, it assignss same metadata to multile `tokenIds`, leading to user confusion, as buyers expect to buy unique `Treats`, as they aren't unique they are devaluated.

**Proof of concept:**

```javascript
    function testSameMetadaForMultipleTokenIds() public {
        protocol.addTreat("candy", 0.1 ether, "uri1");
        uint256 tokenId1 = protocol.nextTokenId();
        vm.prank(user);
        protocol.trickOrTreat{ value: 0.2 ether }("candy");

        uint256 tokenId2 = protocol.nextTokenId();
        vm.prank(user2);
        protocol.trickOrTreat{ value: 0.2 ether }("candy");

        string memory metadata1 = protocol.tokenURI(tokenId1);
        string memory metadata2 = protocol.tokenURI(tokenId2);

        assert(Strings.equal(metadata1, metadata2));
    }
```

**Recommended Mitigation:**

- Enforce `treat` minting, is assiged with unique metadata
