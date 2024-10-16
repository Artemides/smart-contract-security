// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract ERC721Test is Test {
    YulERC721 erc721;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidReceiver(address receiver);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidSender(address sender);

    function run() public {
        setUp();
        testReturnsBalanceOf();
    }

    function setUp() public {
        bytes memory bytecode =
            hex"6104d06100106000396104d06000f3fe61000761046b565b806301ffc9a71461008557806370a0823114610080578063e985e9c51461007b57806340c10f191461006d5780636352211e14610068578063081812fc146100635763095ea7b31461005857600080fd5b610060610128565b5b005b610107565b6100f0565b506100766100a2565b610061565b6100c1565b61008b565b50610061565b61009d6100986000610477565b610178565b6104af565b6100bf6100af6000610477565b6100b96001610496565b90610149565b565b6100de6100ce6000610477565b6100d86001610477565b90610341565b6100e95760006104af565b60016104af565b6101026100fd6000610496565b610199565b6104af565b6101236101146000610496565b61011d81610199565b50610361565b6104af565b61014760016101376000610477565b61014082610496565b339161027a565b565b90811561017157600061015f91610164936101c8565b6104b8565b61016a57565b600061044c565b600061043b565b8015610194576101909061018a610377565b9061045d565b5490565b6103f4565b906101a3826101b2565b9182156101ad5750565b610405565b6101c4906101be610377565b9061045d565b5490565b90610220919392936101d9826101b2565b94826101e4826104b8565b610269575b50506101f4856104b8565b61023f575b610202816104b8565b610222575b80610219610213610377565b8461045d565b558461038b565b565b61023361022d61037c565b8261045d565b60018154019055610207565b61024c600080848161027a565b61025d61025761037c565b8661045d565b600181540390556101f9565b61027391876102f9565b38826101e9565b92919091610287826104b8565b81176102a5575b50506102a29061029c610381565b9061045d565b55565b6102ae83610199565b916102b98184610341565b1981841419166102c8826104b8565b166102f457509082846102a294936102e3575b50925061028e565b6102ec926103b9565b3881846102db565b61042a565b610304838383610318565b1561030e57505050565b6104165750610405565b9091610323836104b8565b9261033a6103348280861495610341565b92610361565b1417171690565b9061035761035d92610351610386565b9061045d565b9061045d565b5490565b6103739061036d610381565b9061045d565b5490565b600290565b600390565b600490565b600590565b906103b792917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef6103e7565b565b906103e592917f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9256103e7565b565b90919260005260206000a3565b6389c62b646000526020526024601cfd5b637e2732896000526020526024601cfd5b63177e802f6000526020526040526044601cfd5b63a9fbf51f6000526020526024601cfd5b6364a0ae926000526020526024601cfd5b6373c6ac6e6000526020526024601cfd5b600052602052604060002090565b600160e01b6000350490565b61048090610496565b9060018060a01b0319821661049157565b600080fd5b6020026004016020810136106104aa573590565b600080fd5b60005260206000f35b906000600192146104c6575b565b90506000906104c456";
        address at;
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        erc721 = YulERC721(at);
    }

    function testReturnsBalanceOf() public {
        uint256 userBalance = erc721.balanceOf(user);
        assertEq(userBalance, 0);
        vm.expectRevert(abi.encodeWithSelector(ERC721InvalidOwner.selector, address(0)));
        erc721.balanceOf(address(0));
    }

    function testMintsANft() public {
        erc721.mint(user, 1);
        address tokenOwner = erc721.ownerOf(1);
        assertEq(tokenOwner, user, "Not Owner");
    }

    function testApproveOnlyExistingAndOwnedTokens() public {
        erc721.mint(user2, 1);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ERC721InvalidApprover.selector, user));
        erc721.approve(user2, 1);
    }

    function testApprovesToken() public {
        erc721.mint(user, 1);
        vm.prank(user);
        erc721.approve(user2, 1);
        assertEq(erc721.getApproved(1), user2);
    }
}

contract YulERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) { }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
