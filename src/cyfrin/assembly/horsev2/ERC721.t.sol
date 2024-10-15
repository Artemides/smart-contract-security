// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract ERC721Test is Test {
    IERC721 erc721;
    address user = makeAddr("user");

    function run() public {
        setUp();
        testReturnsBalanceOf();
    }

    function setUp() public {
        bytes memory bytecode =
            hex"609f600d600039609f6000f3fe60056093565b806301ffc9a714602f576370a0823114601d57600080fd5b602b602760006042565b6031565b6076565b005b603e90603a607f565b6084565b5490565b604990605e565b9060018060a01b03198216605957565b600080fd5b6020026004016020810136106071573590565b600080fd5b60005260206000f35b600290565b90600052602052604060002090565b600160e01b600035049056";
        address at;
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        erc721 = IERC721(at);
    }

    function testReturnsBalanceOf() public view {
        uint256 userBalance = erc721.balanceOf(user);
        assertEq(userBalance, 0);
    }
}
