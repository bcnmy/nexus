// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

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

contract MockERC1155 is ERC1155 {
    constructor(string memory uri) ERC1155(uri) {}

    function safeMint(address to, uint256 tokenId, uint256 amount) public {
        _mint(to, tokenId, amount, "");
    }

    function safeMintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts) public {
        _mintBatch(to, tokenIds, amounts, "");
    }
}
