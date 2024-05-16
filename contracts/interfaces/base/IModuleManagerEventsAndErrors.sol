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
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

/// @title ERC-7579 Module Manager Events and Errors Interface
/// @notice Provides event and error definitions for actions related to module management in smart accounts.
/// @dev Used by IModuleManager to define the events and errors associated with the installation and management of modules.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IModuleManagerEventsAndErrors {
    /// @notice Emitted when a module is installed onto a smart account.
    /// @param moduleTypeId The identifier for the type of module installed.
    /// @param module The address of the installed module.
    event ModuleInstalled(uint256 moduleTypeId, address module);

    /// @notice Emitted when a module is uninstalled from a smart account.
    /// @param moduleTypeId The identifier for the type of module uninstalled.
    /// @param module The address of the uninstalled module.
    event ModuleUninstalled(uint256 moduleTypeId, address module);

    /// @dev Thrown when an attempt is made to uninstall the last validator module, which is prohibited.
    error CannotRemoveLastValidator();

    /// @dev Thrown when the specified module address is not recognized as valid.
    error InvalidModule(address module);

    /// @dev Thrown when an invalid module type identifier is provided.
    error InvalidModuleTypeId(uint256 moduleTypeId);

    /// @dev Thrown when there is an attempt to install a module that is already installed.
    error ModuleAlreadyInstalled(uint256 moduleTypeId, address module);

    /// @dev Thrown when an operation is performed by an unauthorized operator.
    error UnauthorizedOperation(address operator);

    /// @dev Thrown when there is an attempt to uninstall a module that is not installed.
    error ModuleNotInstalled(uint256 moduleTypeId, address module);

    /// @dev Thrown when a module address is set to zero.
    error ModuleAddressCanNotBeZero();

    /// @dev Thrown when a post-check fails after hook execution.
    error HookPostCheckFailed();

    /// @dev Thrown when there is an attempt to install a hook while another is already installed.
    error HookAlreadyInstalled(address currentHook);

    /// @dev Thrown when there is an attempt to install a fallback handler for a selector already having one.
    error FallbackAlreadyInstalledForSelector(bytes4 selector);

    /// @dev Thrown when there is an attempt to uninstall a fallback handler for a selector that does not have one installed.
    error FallbackNotInstalledForSelector(bytes4 selector);

    /// @dev Thrown when a fallback handler fails to uninstall properly.
    error FallbackHandlerUninstallFailed();

    /// @dev Thrown when no fallback handler is available for a given selector.
    error MissingFallbackHandler(bytes4 selector);
}
