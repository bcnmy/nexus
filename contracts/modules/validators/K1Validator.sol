// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "../..//types/Constants.sol";
import { MODULE_TYPE_VALIDATOR, VALIDATION_SUCCESS, VALIDATION_FAILED } from "../..//types/Constants.sol";
import { MessageHashUtils } from "@openzeppelin/utils/cryptography/MessageHashUtils.sol";
import { ERC7739Validator } from "../../base/ERC7739Validator.sol";

/// @title Nexus - K1Validator (ECDSA)
/// @notice Validator module for smart accounts, verifying user operation signatures
///         based on the K1 curve (secp256k1), a widely used ECDSA algorithm.
/// @dev Implements secure ownership validation by checking signatures against registered
///      owners. This module supports ERC-7579 and ERC-4337 standards, ensuring only the
///      legitimate owner of a smart account can authorize transactions.
///      Implements ERC-7739
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract K1Validator is ERC7739Validator {
    using SignatureCheckerLib for address;

    /// @notice Mapping of smart account addresses to their respective owner addresses
    mapping(address => address) public smartAccountOwners;

    /// @notice Error to indicate that no owner was provided during installation
    error NoOwnerProvided();

    /// @notice Error to indicate that the new owner cannot be the zero address
    error ZeroAddressNotAllowed();

    /// @notice Error to indicate the module is already initialized
    error ModuleAlreadyInitialized();

    /// @notice Error to indicate that the new owner cannot be a contract address
    error NewOwnerIsContract();

    /// @notice Error to indicate that the data length is invalid
    error InvalidDataLength();

    /// @notice Called upon module installation to set the owner of the smart account
    /// @param data Encoded address of the owner
    function onInstall(bytes calldata data) external {
        require(data.length != 0, NoOwnerProvided());
        require(!_isInitialized(msg.sender), ModuleAlreadyInitialized());
        address newOwner = address(bytes20(data));
        require(!_isContract(newOwner), NewOwnerIsContract());
        smartAccountOwners[msg.sender] = newOwner;
    }

    /// @notice Called upon module uninstallation to remove the owner of the smart account
    function onUninstall(bytes calldata) external {
        delete smartAccountOwners[msg.sender];
    }

    /// @notice Transfers ownership of the validator to a new owner
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) external {
        require(newOwner != address(0), ZeroAddressNotAllowed());
        require(!_isContract(newOwner), NewOwnerIsContract());

        smartAccountOwners[msg.sender] = newOwner;
    }

    /// @notice Checks if the smart account is initialized with an owner
    /// @param smartAccount The address of the smart account
    /// @return True if the smart account has an owner, false otherwise
    function isInitialized(address smartAccount) external view returns (bool) {
        return _isInitialized(smartAccount);
    }

    /// @notice Validates a user operation by checking the signature against the owner's address
    /// @param userOp The user operation to validate
    /// @param userOpHash The hash of the user operation
    /// @return The validation result (0 for success, 1 for failure)
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256) {
        address owner = smartAccountOwners[userOp.sender];
        return _validateSignatureForOwner(owner, userOpHash, userOp.signature) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    /// @notice Validates a signature with the sender's address
    /// @param hash The hash of the data to validate
    /// @param data The signature data
    /// @return The magic value if the signature is valid, otherwise an invalid value
    function isValidSignatureWithSender(address, bytes32 hash, bytes calldata data) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        (bytes32 computeHash, bytes calldata truncatedSignature) = _erc1271HashForIsValidSignatureViaNestedEIP712(hash, data);
        return _validateSignatureForOwner(owner, computeHash, truncatedSignature) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    /// @notice Validates a signature with the sender's address
    /// @param hash The hash of the data to validate
    /// @param signature The signature data
    /// @return The magic value if the signature is valid, otherwise an invalid value
    /// @dev This method is unsafe and should be used with caution
    ///      Introduced for the cases when nested eip712 via erc-7739 is excessive
    ///      One example of this is Module Enable Mode in Nexus account
    function isValidSignatureWithSenderUnsafe(address, bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        return _validateSignatureForOwner(owner, hash, signature) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    /// @notice ISessionValidator interface for smart session
    /// @param hash The hash of the data to validate
    /// @param sig The signature data
    /// @param data The data to validate against (owner address in this case)
    function validateSignatureWithData(bytes32 hash, bytes calldata sig, bytes calldata data) external view returns (bool validSig) {
        require(data.length == 20, InvalidDataLength());
        address owner = address(bytes20(data[0:20]));
        return _validateSignatureForOwner(owner, hash, sig);
    }

    /// @notice Returns the name of the module
    /// @return The name of the module
    function name() external pure returns (string memory) {
        return "K1Validator";
    }

    /// @notice Returns the version of the module
    /// @return The version of the module
    function version() external pure returns (string memory) {
        return "1.0.0-beta";
    }

    /// @notice Checks if the module is of the specified type
    /// @param typeID The type ID to check
    /// @return True if the module is of the specified type, false otherwise
    function isModuleType(uint256 typeID) external pure returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    /// @notice Internal method that does the job of validating the signature via ECDSA (secp256k1)
    /// @param owner The address of the owner
    /// @param hash The hash of the data to validate
    /// @param signature The signature data
    function _validateSignatureForOwner(address owner, bytes32 hash, bytes calldata signature) internal view returns (bool) {
        // Check if the 's' value is valid
        bytes32 s;
        assembly {
            // same as `s := mload(add(signature, 0x40))` but for calldata
            s := calldataload(add(signature.offset, 0x20))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }

        if (SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, signature)) {
            return true;
        }
        if (SignatureCheckerLib.isValidSignatureNowCalldata(owner, MessageHashUtils.toEthSignedMessageHash(hash), signature)) {
            return true;
        }
        return false;
    }

    /// @notice Checks if the smart account is initialized with an owner
    /// @param smartAccount The address of the smart account
    /// @return True if the smart account has an owner, false otherwise
    function _isInitialized(address smartAccount) private view returns (bool) {
        return smartAccountOwners[smartAccount] != address(0);
    }

    /// @notice Checks if the address is a contract
    /// @param account The address to check
    /// @return True if the address is a contract, false otherwise
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
