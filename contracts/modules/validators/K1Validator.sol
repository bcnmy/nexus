// SPDX-License-Identifier: MIT
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
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

import { IValidator } from "../../interfaces/modules/IValidator.sol";
import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "../../../contracts/types/Constants.sol";
import { MODULE_TYPE_VALIDATOR, VALIDATION_SUCCESS, VALIDATION_FAILED } from "../../../contracts/types/Constants.sol";

/// @title Nexus - K1Validator
/// @notice This contract is a simple validator for testing purposes, verifying user operation signatures against registered owners.
/// @dev It validates signatures using the SignatureCheckerLib, and should not be used in production environments.
/// This contract exemplifies a module that checks if the user operation signature is valid according to ERC-1271 standards.
/// For production-ready modules, please refer to the Biconomy Modules repository.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
/// @title Nexus - K1Validator
/// @notice Validates user operation signatures for smart accounts.
/// @dev This is a simple validator using SignatureCheckerLib for testing purposes. Not for production use.
contract K1Validator is IValidator {
    using SignatureCheckerLib for address;

    /// @notice Mapping of smart account addresses to their respective owner addresses
    mapping(address => address) public smartAccountOwners;

    /// @notice Error to indicate that no owner was provided during installation
    error NoOwnerProvided();

    /// @notice Called upon module installation to set the owner of the smart account
    /// @param data Encoded address of the owner
    function onInstall(bytes calldata data) external {
        if (data.length == 0) revert NoOwnerProvided();
        address owner = address(bytes20(data));
        smartAccountOwners[msg.sender] = owner;
    }

    /// @notice Called upon module uninstallation to remove the owner of the smart account
    function onUninstall(bytes calldata) external {
        delete smartAccountOwners[msg.sender];
    }

    /// @notice Checks if the smart account is initialized with an owner
    /// @param smartAccount The address of the smart account
    /// @return True if the smart account has an owner, false otherwise
    function isInitialized(address smartAccount) external view returns (bool) {
        return smartAccountOwners[smartAccount] != address(0);
    }

    /// @notice Validates a user operation by checking the signature against the owner's address
    /// @param userOp The user operation to validate
    /// @param userOpHash The hash of the user operation
    /// @return The validation result (0 for success, 1 for failure)
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256) {
        address owner = smartAccountOwners[userOp.sender];
        if (
            owner.isValidSignatureNow(ECDSA.toEthSignedMessageHash(userOpHash), userOp.signature) ||
            owner.isValidSignatureNow(userOpHash, userOp.signature)
        ) {
            return VALIDATION_SUCCESS;
        }
        return VALIDATION_FAILED;
    }

    /// @notice Validates a signature with the sender's address
    /// @param hash The hash of the data to validate
    /// @param data The signature data
    /// @return The magic value if the signature is valid, otherwise an invalid value
    function isValidSignatureWithSender(address, bytes32 hash, bytes calldata data) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        // Validate the signature using SignatureCheckerLib
        return SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, data) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    /// @notice Returns the name of the module
    /// @return The name of the module
    function name() external pure returns (string memory) {
        return "K1Validator";
    }

    /// @notice Returns the version of the module
    /// @return The version of the module
    function version() external pure returns (string memory) {
        return "0.0.1";
    }

    /// @notice Checks if the module is of the specified type
    /// @param typeID The type ID to check
    /// @return True if the module is of the specified type, false otherwise
    function isModuleType(uint256 typeID) external pure returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }
}
