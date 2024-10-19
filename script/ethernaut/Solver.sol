//SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Script.sol";

contract ExploitPuzzleWallet is Script {
    function run() public {
        bytes memory solverBytecode = hex"600a600d600039600a6000f3fe602a60005260206000f3";
        uint256 pk = vm.envUint("PK");
        vm.startBroadcast(pk);
        uint256 solverAt;
        assembly {
            solverAt := create(0, add(solverBytecode, 0x20), mload(solverBytecode))
        }

        console.log("Solver Address:", solverAt);

        vm.stopBroadcast();
    }
}
