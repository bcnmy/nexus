// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Mint a new NFT token to the specified address with the specified tokenId
    // Warning: This function is only for testing purposes and should not be used in production
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    // Safely mint a new NFT token to the specified address with the specified tokenId
    // Warning: This function is only for testing purposes and should not be used in production
    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}
