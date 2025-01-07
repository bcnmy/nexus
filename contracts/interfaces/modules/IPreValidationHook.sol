// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { IModule } from "./IModule.sol";

/// @title Nexus - IPreValidationHookERC1271 Interface
/// @notice Defines the interface for ERC-1271 pre-validation hooks
interface IPreValidationHookERC1271 is IModule {
    /// @notice Performs pre-validation checks for isValidSignature
    /// @dev This method is called before the validation of a signature on a validator within isValidSignature
    /// @param account The account calling the hook
    /// @param sender The original sender of the request
    /// @param hash The hash of signed data
    /// @param data The signature data to validate
    /// @return hookHash The hash after applying the pre-validation hook
    /// @return hookSignature The signature after applying the pre-validation hook
    function preValidationHookERC1271(
        address account,
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        returns (bytes32 hookHash, bytes memory hookSignature);
}

/// @title Nexus - IPreValidationHookERC4337 Interface
/// @notice Defines the interface for ERC-4337 pre-validation hooks
interface IPreValidationHookERC4337 is IModule {
    /// @notice Performs pre-validation checks for user operations
    /// @dev This method is called before the validation of a user operation
    /// @param account The account calling the hook
    /// @param userOp The user operation to be validated
    /// @param missingAccountFunds The amount of funds missing in the account
    /// @param userOpHash The hash of the user operation data
    /// @return hookHash The hash after applying the pre-validation hook
    /// @return hookSignature The signature after applying the pre-validation hook
    function preValidationHookERC4337(
        address account,
        PackedUserOperation calldata userOp,
        uint256 missingAccountFunds,
        bytes32 userOpHash
    )
        external
        view
        returns (bytes32 hookHash, bytes memory hookSignature);
}
