// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io/

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

contract TokenWithPermit is ERC20Permit {

    error ERC1271InvalidSigner(address signer);

    bytes32 public constant PERMIT_TYPEHASH_LOCAL =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(string memory name, string memory symbol) ERC20Permit(name) ERC20(name, symbol) {
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
    }

    function mint(address sender, uint256 amount) external {
        _mint(sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function permitWith1271(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH_LOCAL, owner, spender, value, _useNonce(owner), deadline));

        bytes32 childHash = _hashTypedDataV4(structHash);

        if(owner.code.length > 0) {
           bytes4 result = IERC1271(owner).isValidSignature(childHash, signature);
           if(result != bytes4(0x1626ba7e)) {
                revert ERC1271InvalidSigner(owner);
           }
        } else {
           address signer = ECDSA.recover(childHash, signature);
           if (signer != owner) {
               revert ERC2612InvalidSigner(signer, owner);
           }
        }
        _approve(owner, spender, value);
    }
}
