// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

contract LockerTest is Test {
    function testGetVRS() public pure {
        // bytes memory signature =
        //     hex"1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b9178489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2000000000000000000000000000000000000000000000000000000000000001b";
        bytes memory signature =
            hex"1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b9178489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2000000000000000000000000000000000000000000000000000000000000001b";
        uint8 v;
        uint256 r;
        uint256 s;
        assembly {
            let ptr := mload(0x40)
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        bytes32 hash1 = keccak256(abi.encode([uint256(r), uint256(s), uint256(v)]));
        bytes32 hash2 = keccak256(signature);
        console.log(v, r, s);
        // 27 1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91
        // 78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2

        //
        assert(hash1 == hash2);
    }
}
