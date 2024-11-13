// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CharityRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GivingThanks is ERC721URIStorage {
    CharityRegistry public registry;
    uint256 public tokenCounter;
    //@i owner should be immutable
    address public owner;

    constructor(address _registry) ERC721("DonationReceipt", "DRC") {
        //@audit _registry should be set instead of msg.sender
        registry = CharityRegistry(_registry);
        owner = msg.sender;
        tokenCounter = 0;
    }

    //@audit reentrancy, breaks token counter sequence also _setTokenURI
    function donate(address charity) public payable {
        require(registry.isVerified(charity), "Charity not verified");
        //@e to malicious charities will afect them not the protocol
        (bool sent,) = charity.call{ value: msg.value }("");
        require(sent, "Failed to send Ether");
        //@audit unsafe token mint, ERC721Receiver
        _mint(msg.sender, tokenCounter);

        // Create metadata for the tokenURI
        string memory uri = _createTokenURI(msg.sender, block.timestamp, msg.value);
        _setTokenURI(tokenCounter, uri);

        tokenCounter += 1;
    }

    function _createTokenURI(address donor, uint256 date, uint256 amount) internal pure returns (string memory) {
        // Create JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"donor":"',
                Strings.toHexString(uint160(donor), 20),
                '","date":"',
                Strings.toString(date),
                '","amount":"',
                Strings.toString(amount),
                '"}'
            )
        );

        // Encode in base64 using OpenZeppelin's Base64 library
        string memory base64Json = Base64.encode(bytes(json));

        // Return the data URL
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    //@audit anyone can change registry: updates to Malicious registries migh bypass verification and generate DOS,
    function updateRegistry(address _registry) public {
        registry = CharityRegistry(_registry);
    }
}
