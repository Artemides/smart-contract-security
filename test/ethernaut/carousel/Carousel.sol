// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "forge-std/Test.sol";

contract CarouselTest is Test {
    uint16 public constant MAX_CAPACITY = type(uint16).max;
    uint256 constant ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;
    uint256 constant NEXT_ID_MASK = uint256(type(uint16).max) << 160;
    uint256 constant OWNER_MASK = uint256(type(uint160).max);
    MagicAnimalCarousel carousel;

    function setUp() public {
        if (block.chainid == 11155111) {
            carousel = MagicAnimalCarousel(0x5A64A4aC5E1c2050be8ACdB6D91d19389Ca5362E);
        } else {
            carousel = new MagicAnimalCarousel();
            // carousel.changeAnimal("cow", 0);
            // carousel.changeAnimal("lion", 1);
            // carousel.changeAnimal("elephant", 2);
            // carousel.changeAnimal(hex"000000000000000000010002", 3);
        }
    }

    function testCarouselBitwise() public pure {
        uint256 op =
            0xffffffffffffffffffff0000ffffffffffffffffffffffffffffffffffffffff | 0xffffffffffffffffffff000038C5479620f6C2f29677F04d89E356cF6E75CFde;
        console.log("op", op);
    }

    function testSepoliaAnimals() public view {
        uint256 id = carousel.currentCrateId();
        printAnimal(id);
    }

    function testCarouselAnimals() public {
        carousel.setAnimalAndSpin("dog");
        uint256 id = carousel.currentCrateId();
        console.log("id", id);
        printAnimal(id);
        carousel.changeAnimal(hex"000000000000000000000001", 1);
        printAnimal(id);
        carousel.setAnimalAndSpin("dog");
        id = carousel.currentCrateId();
        console.log("id", id);
        printAnimal(2);

        printAnimal(id);
    }

    function testAnimalStaysAfterSpin() public {
        carousel.changeAnimal("bear", 1);
        uint256 id = carousel.currentCrateId();
        uint256 currentAnimal = carousel.carousel(id);
        uint256 nextId = (currentAnimal & NEXT_ID_MASK) >> 160;
        uint256 nextAnimal = carousel.carousel(nextId);
        uint256 nextAnimalName = nextAnimal & ANIMAL_MASK;
        console.log("nextAnimalName", nextAnimalName);
        carousel.setAnimalAndSpin("dog");
        console.log("next Name", carousel.carousel(nextId) & ANIMAL_MASK);
        uint256 joinedAnimalEncoded = (carousel.encodeAnimalName("dog") >> 16) << 160 + 16;
        uint256 animal = (carousel.carousel(nextId) & ANIMAL_MASK) ^ joinedAnimalEncoded;
        assertEq(animal, nextAnimalName, "Animal Removed");

        //Spins
        //currentId
        //getCrate -> compare
    }

    function testAnimalDoNotStayAfterSpin() public {
        carousel.changeAnimal(string(abi.encodePacked(hex"00000000000000000000ffff")), 0);
        carousel.changeAnimal(string(abi.encodePacked(hex"aaaa0000000000000000ffff")), 0xffff);
        carousel.setAnimalAndSpin("dog"); //set max as 0 ^ dog
        carousel.changeAnimal(string(abi.encodePacked(hex"11110000000000000000fffe")), 0xffff);
        uint256 id = carousel.currentCrateId();
        console.log("id", id);
        uint256 currentAnimal = carousel.carousel(id);
        uint256 nextId = (currentAnimal & NEXT_ID_MASK) >> 160;
        uint256 nextAnimal = carousel.carousel(nextId);
        uint256 nextAnimalName = nextAnimal & ANIMAL_MASK;
        console.log("nextAnimalName", nextAnimalName);
        carousel.setAnimalAndSpin("dog");
        console.log("next Name", carousel.carousel(nextId) & ANIMAL_MASK);
        uint256 joinedAnimalEncoded = (carousel.encodeAnimalName("dog") >> 16) << 160 + 16;
        uint256 animal = (carousel.carousel(nextId) & ANIMAL_MASK) ^ joinedAnimalEncoded;
        assertEq(animal, nextAnimalName, "Animal Removed");

        //Spins
        //currentId
        //getCrate -> compare
    }

    function testCarouselAnimals3() public {
        carousel.changeAnimal(string(abi.encodePacked(hex"00000000000000000000ffff")), 0);
        carousel.setAnimalAndSpin("dog");
        carousel.changeAnimal(string(abi.encodePacked(hex"00000000000000000000ffff")), 0xffff);

        uint256 id = carousel.currentCrateId();
        uint256 currentAnimal = carousel.carousel(id);
        uint256 nextId = currentAnimal & NEXT_ID_MASK;
        uint256 nextAnimal = carousel.carousel(nextId);
        uint256 nextAnimalName = nextAnimal & ANIMAL_MASK;

        carousel.setAnimalAndSpin("dog");
        //verify
        uint256 joinedAnimalEncoded = carousel.encodeAnimalName("dog");
        uint256 animal = nextAnimalName ^ joinedAnimalEncoded;
        assertEq(animal, nextAnimal, "Animal Removed");

        console.log("id", id);
        printAnimal(id);
        //Spins
        //currentId
        //getCrate -> compare

        //beat ->
        //Spin -> animal^animal' => check res^animal' = animal
        //q b -> b^animal ^ animal = b
    }

    function printAnimal(uint256 id) internal view {
        uint256 zebraName = (carousel.carousel(id) & ANIMAL_MASK) >> 160 + 16;
        uint256 zebraId = (carousel.carousel(id) & NEXT_ID_MASK) >> 160;
        uint256 zebraOwner = (carousel.carousel(id) & OWNER_MASK);
        console.log("Animal", zebraName, zebraId, zebraOwner);
    }
}

contract MagicAnimalCarousel {
    uint16 public constant MAX_CAPACITY = type(uint16).max;
    uint256 constant ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;
    uint256 constant NEXT_ID_MASK = uint256(type(uint16).max) << 160;
    uint256 constant OWNER_MASK = uint256(type(uint160).max);
    //0:1 -> 1:2 -> 2:3 -> 3:4 -> e:2:me
    uint256 public currentCrateId;
    mapping(uint256 crateId => uint256 animalInside) public carousel;

    error InvalidCarouselId();
    error AnimalNameTooLong();

    constructor() {
        carousel[0] ^= 1 << 160;
    }

    function setAnimalAndSpin(string calldata animal) external {
        uint256 encodedAnimal = encodeAnimalName(animal) >> 16;
        // 0 -> lion-id' , 1 -> zebra-id' 2 -> horse-id'
        // 0 -> lion-id , 1 -> zebra-id 2 -> horse-id
        //1
        //2
        uint256 nextCrateId = (carousel[currentCrateId] & NEXT_ID_MASK) >> 160;

        require(encodedAnimal <= uint256(type(uint80).max), "AnimalNameTooLong");
        //[1] = zebra^animal-2-owner
        //[2] = [2]^animal - 3 - owner
        carousel[nextCrateId] =
            (carousel[nextCrateId] & ~NEXT_ID_MASK) ^ (encodedAnimal << 160 + 16) | ((nextCrateId + 1) % MAX_CAPACITY) << 160 | uint160(msg.sender);

        currentCrateId = nextCrateId;
    }

    function changeAnimal(string calldata animal, uint256 crateId) external {
        address owner = address(uint160(carousel[crateId] & OWNER_MASK));
        if (owner != address(0)) {
            require(msg.sender == owner);
        }
        uint256 encodedAnimal = encodeAnimalName(animal);
        if (encodedAnimal != 0) {
            // Replace animal
            carousel[crateId] = (encodedAnimal << 160) | (carousel[crateId] & NEXT_ID_MASK) | uint160(msg.sender);
        } else {
            // If no animal specified keep same animal but clear owner slot
            carousel[crateId] = (carousel[crateId] & (ANIMAL_MASK | NEXT_ID_MASK));
        }
    }

    function encodeAnimalName(string calldata animalName) public pure returns (uint256) {
        require(bytes(animalName).length <= 12, "AnimalNameTooLong");
        return uint256(bytes32(abi.encodePacked(animalName)) >> 160);
    }
}
