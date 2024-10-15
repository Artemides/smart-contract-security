// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

contract ERC721Test is Test {
    address erc721;

    function setUp() public {
        bytes memory bytecode =
            hex"6095600d60003960956000f3fe60056089565b806301ffc9a7146029576370a0823114601d57600080fd5b602560006041565b602b565b005b60389060346075565b607a565b54600052600080f35b604890605d565b9060018060a01b03198216605857565b600080fd5b6020026004016020810136106070573590565b600080fd5b600290565b90600052602052604060002090565b600160e01b600035049056";
        address at;
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        erc721 = at;
    }
}
