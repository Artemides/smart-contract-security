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

# [M-2]
