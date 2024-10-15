// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract ERC721Test is Test {
    IERC721 erc721;
    address user = makeAddr("user");

    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256);

    function run() public {
        setUp();
        testReturnsBalanceOf();
    }

    function setUp() public {
        bytes memory bytecode =
            hex"60b9600d60003960b96000f3fe6005609c565b806301ffc9a714602f576370a0823114601d57600080fd5b602b60276000604b565b6031565b607f565b005b8015604757604390603f6088565b608d565b5490565b60a8565b6052906067565b9060018060a01b03198216606257565b600080fd5b602002600401602081013610607a573590565b600080fd5b60005260206000f35b600290565b90600052602052604060002090565b600160e01b6000350490565b6389c62b646000526020526024601cfd";
        address at;
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        erc721 = IERC721(at);
    }

    function testReturnsBalanceOf() public {
        uint256 userBalance = erc721.balanceOf(user);
        assertEq(userBalance, 0);
        vm.expectRevert(abi.encodeWithSelector(ERC721InvalidOwner.selector, address(0)));
        erc721.balanceOf(address(0));
    }
}
