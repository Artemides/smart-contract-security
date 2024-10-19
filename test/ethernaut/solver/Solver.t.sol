// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HorseNumber is Test {
    address solverAddr;

    function setUp() public {
        address at;
        bytes memory bytecode = hex"600a600d600039600a6000f3fe602a60005260206000f3";
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(at != address(0));

        solverAddr = at;
    }

    function testReturns42() public {
        bytes memory dataCall = abi.encodeWithSignature("whatIsTheMeaningOfLife()");

        (bool success, bytes memory data) = solverAddr.call(dataCall);
        require(success, "did not call");
        uint256 magic = abi.decode(data, (uint256));
        console.log("Magic", magic);
        assert(magic == 42);
    }
}
