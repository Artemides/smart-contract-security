# Findings

## Ignore

1. Weak `RNG` random number generated

# High

## [H-1] Central Authotities `Owner` can still manipulate `tricked/pending Treats`.

**Description:**

Although there's no sufficient specification whether it's itended to do so, meaning `Spooky Surprise`.

`Owners` can manipulate the price of an `already tricked Treat`, changing their cost, affecting `SpookySwap:resolveTrick` either for cheaper or expensiver later cost, as well as potential `trades` between users with revaluations either positively or negatively in contrast to initial user `investment`.

**Impact:** users might not find an attractive Protocol or so, due to potential cost `increasement` or `decreasement` made by Central Authority or Protocol's owner.

**Proof of concept:**

```javascript
    function resolveTrick(uint256 tokenId) public payable nonReentrant {
        require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

        string memory treatName = tokenIdToTreatName[tokenId];
    @>  Treat memory treat = treatList[treatName];
    @>  uint256 requiredCost = treat.cost * 2; // Double price
        uint256 amountPaid = pendingNFTsAmountPaid[tokenId];
        uint256 totalPaid = amountPaid + msg.value;

    @>  require(totalPaid >= requiredCost, "Insufficient ETH sent to complete purchase");

      /*
        ...impl..
      */
    }

```

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

**Impact:** overrides causing invalidad queries `treatList[_treatName]` makes `SpookySwap:setTreatCost` to update cost of latest treat, whereas by `SpookySwap:trickOrTreat` latests treat will be minted. Moreover, `SpookySwap:resolveTrick` even being tied to a `tokenId` it still queries a treat by `_name` also getting affected.

**Proof of concept:**

```javascript

    function addTreat(string memory _name, uint256 _rate, string memory _metadataURI) public onlyOwner {
    @>  treatList[_name] = Treat(_name, _rate, _metadataURI);
        treatNames.push(_name);
        emit TreatAdded(_name, _rate, _metadataURI);
    }

    function trickOrTreat(string memory _treatName) public payable nonReentrant {
    @>  Treat memory treat = treatList[_treatName];
        require(treat.cost > 0, "Treat cost not set.");

        /*
        ...impl...
        */
    }
    function resolveTrick(uint256 tokenId) public payable nonReentrant {
        require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

        string memory treatName = tokenIdToTreatName[tokenId];
    @>  Treat memory treat = treatList[treatName];

        /*
        ...impl...
        */
    }

```

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

## [H-3] treats with 1 wei cost, spooked at `random = 1 => requiredCost:half-price` are rounded to zero. leading to free purchases.

**Description:** By predicting `random = 1` `SpookySwap:trickOrTreat` malicious users can buy `Treats` for free, due to divisions are exact in solidity `1/2` will be rounded as `0`, doing so `requiredCost`to be 0, enabling free purchases, notice that `Treats` can repriced and traded at higher prices.

```diff
-   uint256 requiredCost = (treat.cost * costMultiplierNumerator) / costMultiplierDenominator;
```

**Impact:** This vulnerability only affects `1 wei` per purchase, though can be considered as hight due to Protocol's fund discrepancies.

**Proof of Concept:**

```javascript
    function testTreatsAt1WeiForFree() public {
        protocol.addTreat("candy", 1 wei, "uri1");

        uint256 tokenId = protocol.nextTokenId();
        //predict random = 1
        uint256 random;
        while (true) {
            uint256 timestramp = block.timestamp;
            random = uint256(keccak256(abi.encodePacked(timestramp, address(user), tokenId, block.prevrandao))) % 1000 + 1;
            if (random == 1) {
                break;
            }
            vm.warp(timestramp + 1);
        }

        uint256 balanceBefore = address(user).balance;
        vm.prank(user);
        //purchase a 1 wei Treat cost for free
        protocol.trickOrTreat{ value: 1 ether }("candy");
        //balance before and after equuality
        assert(address(user).balance == balanceBefore);
    }
```

**Recommneded Mitigation:**

- Usage of fixed-point arithmetic
- Beware of precision loss

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

## [M-2] Ambiguity in Shared Metadata Usage, NFT treat are expected to be unique in design `ERC721`

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

## [M-3] Repayments in `SpookySwap:trickOrTreat` and `SpookySwap:resolveTrick` implementations, might generate DOS, Higher costs on `transfers` and user experience degradation.

**Description:** `SpookySwap` implement repayments, which repays exceeded amounts. Therefore, doing it so to `msg.sender` contracts and even to those with heavy computations might always revert `DOS` and may require higher gas computation for just `SpookySwap:trickOrTreat`.

**Impact:** alothough repays are done via `msg.call{value}` repaying in the same transaction give users the flexibility to run in their fallback any code, that in case of `heavy computations` it can revert and even generate higher cost per transaction.

**Proof of concept:**

```javascript

    contract BadBuyer {
        uint256 val;

        receive() external payable {
            //100
            while (gasleft() > 0) {
                val = type(uint256).max;
            }
        }
    }

    function testInefficientRepayment() public {
        protocol.addTreat("candy", 0.1 ether, "uri1");

        BadBuyer buyer = new BadBuyer();
        vm.deal(address(buyer), 1 ether);
        vm.prank(address(buyer));
        vm.expectRevert();
        protocol.trickOrTreat{ value: 0.2 ether }("candy");
    }
```

**Recommended Mitigation:**

- mantain a record of `pending-repay`
- consider an implementation for allowing user to `withdraw` repays.

## [M-4] Potential denial of Service, on `address.transfer (2300 gasLimit)` by `SpookySwap:withdrawFees`.

**Description:** Usage of `address.transfer` built-in method might revert if `Owner` is a contract containing heavy operations on `receive` or `fallback` since `transfer` only supports a max gas usage of `2300`. producing DOS which lock the funds of `SpookySwap` forever.

**Impact:** Protocol's Funds stay locked unless recipient handles `receive` ether under less than `2300 gas`.

**Proof of concept:**

```javascript

    contract Owner {
        uint256 val;

        receive() external payable {
            uint256 gas = gasleft();
            uint256 consumed;
            //100
            while (consumed <= 2300) {
                val = type(uint256).max;
                consumed += gas - gasleft();
                gas = gasleft();
            }
        }
    }

    function testDOSonWithdrawFees() public {
        Owner owner = new Owner();

        SpookySwap.Treat memory treat = SpookySwap.Treat("candy", 0.1 ether, "ipfs://candy-cid");
        SpookySwap.Treat[] memory treats = new SpookySwap.Treat[](1);
        treats[0] = treat;

        vm.prank(address(owner));
        SpookySwap _protocol = new SpookySwap(treats);

        vm.prank(user);
        _protocol.trickOrTreat{ value: 0.2 ether }("candy");

        vm.prank(address(owner));
        vm.expectRevert();
        _protocol.withdrawFees();
    }
```

**Recommended Mitigation:**

- use low level `addres.call` instead
- in case of DOS transfer ownership

## [M-5] Potential Denial of Service when `random = 2` `costMultiplierNumerator=2 and costMultiplierDenominator`, allows malicious users to make `treats:Pending` of any price.

**Description:** Due to deterministic randomdoness `SpookySwap:random`, malicious users, can set aside continously any amount of `treats` by sending `0 ether` on `SpookySwap:trickOrTreat` if `random = 2`. they might not have the intention of `SpookySwap:resolveTrick` but are overloading the protocol, abusing the `pending` mechanism.

**Impact:** Although it does not affect `Owner` fee collect, the lack of `minimun` value allows them to overload the protocol.

**Proof of Concept:**

When a `Treat` is set as pending it emits the `Swapped` Event.

```javascript
    function testDOSonPendingMechanism() public {
        protocol.addTreat("candy", 1 ether, "uri1");
        uint256 tokenId = protocol.nextTokenId();
        uint256 random;
        //look for random value equals to 2
        while (true) {
            uint256 timestramp = block.timestamp;
            random = uint256(keccak256(abi.encodePacked(timestramp, address(user), tokenId, block.prevrandao))) % 1000 + 1;
            if (random == 2) {
                break;
            }
            vm.warp(timestramp + 1);
        }

        vm.prank(user);
        vm.expectEmit();
        emit Swapped(address(user), "candy", tokenId);
        //call with zero value
        protocol.trickOrTreat{ value: 0 }("candy");
    }
```

**Recommneded Mitigation:**

1. Minimum payment required
2. Rate Limiting: a mechanism to limit the amount of pending items
