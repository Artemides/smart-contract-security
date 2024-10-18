// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC721, IERC721Receiver } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract ERC721Test is Test {
    YulERC721 erc721;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidReceiver(address receiver);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidSender(address sender);
    error ERC721InvalidOperator(address operator);

    function run() public {
        setUp();
        testCorrectSetUp();
    }

    function setUp() public {
        bytes memory bytecode =
            hex"6080604052600d6000806026565b60166001806026565b6109916100ba6000396109916000f35b60209081610a4b91028101908260405192833981510190828282398281519384920192018239601f8211606c575b602082106061575b505050565b51179055388080605c565b826000526001602060002080855583815501828201602081066000811160b0575b509082905b828210609f575050506054565b600160209183518155019101906092565b6020030138608d56fe608060405261000c6107fe565b806306fdde031461014157806395d89b411461013c57806301ffc9a71461013657806370a0823114610131578063e985e9c51461012c57806340c10f191461011e5780636352211e14610119578063081812fc14610114578063095ea7b314610106578063a22cb465146100f857806342842e0e146100ea578063b88d4fde146100dc578063a1448194146100ce5780638832e6e3146100c0576342966c68146100b557600080fd5b6100bd6102f0565b5b005b506100c96102d0565b6100be565b506100d76102b0565b6100be565b506100e5610286565b6100be565b506100f361025c565b6100be565b5061010161023c565b6100be565b5061010f61021b565b6100be565b6101fa565b6101e3565b50610127610195565b6100be565b6101b4565b61017e565b506100be565b610166565b61015a61015461014f6106aa565b6108a6565b51610976565b60206060526040016060f35b6101766101716106af565b6108a6565b805160200190f35b61019061018b600061080a565b610333565b61093e565b6101b26101a2600061080a565b6101ac6001610829565b90610304565b565b6101d16101c1600061080a565b6101cb600161080a565b906104fc565b6101dc57600061093e565b600161093e565b6101f56101f06000610829565b610354565b61093e565b6102166102076000610829565b61021081610354565b5061051c565b61093e565b61023a600161022a600061080a565b61023382610829565b3391610435565b565b61025a610249600061080a565b6102536001610842565b9033610532565b565b610284600061026a8161080a565b610274600161080a565b61027e600261080a565b9161056b565b565b6102ae6001610295600061080a565b61029e8261080a565b6102a8600261080a565b9161056b565b565b6102ce60006102be8161080a565b6102c8600161080a565b906105b6565b565b6102ee60016102df600061080a565b6102e882610829565b906105b6565b565b6103026102fd6000610829565b6105cf565b565b90811561032c57600061031a9161031f93610383565b61095e565b61032557565b60006107b7565b60006107a6565b801561034f5761034b906103456106b4565b906107f0565b5490565b61075f565b9061035e8261036d565b9182156103685750565b610770565b61037f906103796106b4565b906107f0565b5490565b906103db919392936103948261036d565b948261039f8261095e565b610424575b50506103af8561095e565b6103fa575b6103bd8161095e565b6103dd575b806103d46103ce6106b4565b846107f0565b55846106c8565b565b6103ee6103e86106b9565b826107f0565b600181540190556103c2565b6104076000808481610435565b6104186104126106b9565b866107f0565b600181540390556103b4565b61042e91876104b4565b38826103a4565b929190916104428261095e565b8117610460575b505061045d906104576106be565b906107f0565b55565b61046983610354565b9161047481846104fc565b1981841419166104838261095e565b166104af575090828461045d949361049e575b509250610449565b6104a7926106f6565b388184610496565b610795565b6104bf8383836104d3565b156104c957505050565b6107815750610770565b90916104de8361095e565b926104f56104ef82808614956104fc565b9261051c565b1417171690565b906105126105189261050c6106c3565b906107f0565b906107f0565b5490565b61052e906105286106be565b906107f0565b5490565b929190928315610565579261056392938261055d6105576105516106c3565b846107f0565b846107f0565b55610724565b565b836107c8565b9061058293929161057d838383610584565b6105e8565b565b919080156105b15761059890823391610383565b916105a38184610947565b6105ac57505050565b6107d9565b6107a6565b906105cd92916105c68282610304565b60006105e8565b565b6105db60008281610383565b156105e35750565b610770565b919290926000843b116105fc575b50505050565b6040519263150b7a028452336020850152604084015260608301526080808301528060008092905061068f575b15610687575b60006020918260040260040101601c840182865af19060405215610677573d6000803e61066660005163150b7a0260e01b90610947565b610672578080806105f6565b6107a6565b3d15610682573d6020fd5b6107a6565b50602061062f565b905060a082016040526106a2600361085b565b919050610629565b600090565b600190565b600290565b600390565b600490565b600590565b906106f492917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef610752565b565b9061072292917f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925610752565b565b9061075092917f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31610752565b565b90919260005260206000a3565b6389c62b646000526020526024601cfd5b637e2732896000526020526024601cfd5b63177e802f6000526020526040526044601cfd5b63a9fbf51f6000526020526024601cfd5b6364a0ae926000526020526024601cfd5b6373c6ac6e6000526020526024601cfd5b635b08ba186000526020526024601cfd5b635b08ba186000526020526040526060526064601cfd5b600052602052604060002090565b600160e01b6000350490565b61081390610829565b9060018060a01b0319821661082457565b600080fd5b60200260040160208101361061083d573590565b600080fd5b61084b90610829565b906001821161085657565b600080fd5b90602060405192026004019060208201803560200192602084010136106108a15782908437602082068284019060008111610897575b50604052565b6020030138610891565b600080fd5b90815491600052602060002080549060405193821561091e575b50600082116108ce575b5050565b81845260006020808404930611610914575b6001849101905b828210610902575050602002602083010160405238806108ca565b602060019101918054835201906108e7565b90600101906108e0565b60ff81169060081c60081b908552602085015260408401604052386108c0565b60005260206000f35b919060019214610954575b565b9050600090610952565b9060006001921461096c575b565b905060009061096a565b6020810660008111610987575b5090565b60200301386109835600000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000e617373656d626c7920746f6b656e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000341534d0000000000000000000000000000000000000000000000000000000000";
        address at;
        assembly {
            at := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        erc721 = YulERC721(at);
    }

    function testCorrectSetUp() public view {
        assertEq("assembly token", erc721.name());
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

    function testSafeMint() public {
        Receiver receiver = new Receiver();
        uint256 tokenId = 1;
        erc721.safeMint(address(receiver), tokenId);
        assertEq(address(receiver), erc721.ownerOf(1), "Receiver not Owner");
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

    function testApprovesForAll() public {
        vm.expectRevert(abi.encodeWithSelector(ERC721InvalidOperator.selector, address(0)));
        erc721.setApprovalForAll(address(0), true);
        vm.prank(user);
        erc721.setApprovalForAll(user2, true);
        bool approved = erc721.isApprovedForAll(user, user2);
        assertEq(approved, true);
    }

    function testTransferTokens() public { }

    function testSafeTransferFrom() public {
        erc721.mint(user, 1);
        Receiver receiver = new Receiver();
        ReceiverV2 notReceiver = new ReceiverV2();

        bytes memory data = abi.encode(this.testApprovesToken.selector);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ERC721InvalidReceiver.selector, address(notReceiver)));
        erc721.safeTransferFrom(user, address(notReceiver), 1, data);

        vm.prank(user);
        erc721.safeTransferFrom(user, address(receiver), 1, data);
    }

    function testSafeTransferFromWithoutData() public {
        erc721.mint(user, 1);
        Receiver receiver = new Receiver();
        vm.prank(user);
        erc721.safeTransferFrom(user, address(receiver), 1);
    }

    function testBurnTokens() public {
        erc721.mint(user, 1);

        erc721.burn(1);
        vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, 1));
        erc721.ownerOf(1);
    }
}

contract YulERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) { }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract Receiver is IERC721Receiver {
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    )
        external
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}

contract ReceiverV2 {
    function doNothing() public { }
}
