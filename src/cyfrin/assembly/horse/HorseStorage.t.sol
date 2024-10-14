// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HorseNumber is Test {
    address horseStoreAddr;

    function setUp() public {
        address at;
        bytes memory bytecode =
            hex"607f600d600039607f6000f3fe60003411603857600c6056565b8063cdfead2e1460285763e026c01714602457600080fd5b6046565b6036603260006062565b603d565b005b600080fd5b6043607a565b55565b604c607a565b5460005260206000f35b600160e01b6000350490565b6020026004016020810136106075573590565b600080fd5b60009056";
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(at != address(0));
        horseStoreAddr = at;
    }

    function testStartingHorseNumberZero() public {
        uint256 horseNumber;
        bytes memory data = abi.encodeWithSignature("readNumberOfHorses()");
        (bool success, bytes memory response) = horseStoreAddr.call(data);
        require(success);
        (horseNumber) = abi.decode(response, (uint256));
        assert(horseNumber == 0);
    }

    function testChangesHorseNumber() public {
        bytes memory data = abi.encodeWithSignature("updateHorseNumber(uint256)", 25);
        (bool success,) = horseStoreAddr.call(data);
        require(success);
        uint256 horseNumber = uint256(vm.load(horseStoreAddr, 0));
        assert(horseNumber == 25);
    }
}
