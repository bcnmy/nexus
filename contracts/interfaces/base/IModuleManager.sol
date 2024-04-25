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
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337,
// using Entrypoint version 0.7.0, developed by Biconomy. Learn more at https://biconomy.io/

import { IModuleManagerEventsAndErrors } from "./IModuleManagerEventsAndErrors.sol";

/// @title Nexus - IModuleManager
/// @notice Interface for managing modules within Smart Accounts, providing methods for installation and removal of modules.
/// @dev Extends the IModuleManagerEventsAndErrors interface to include event and error definitions.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IModuleManager is IModuleManagerEventsAndErrors {
    /// @notice Installs a Module of a specific type onto the smart account.
    /// @param moduleTypeId The identifier for the module type.
    /// @param module The address of the module to be installed.
    /// @param initData Initialization data for configuring the module upon installation.
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable;

    /// @notice Uninstalls a Module of a specific type from the smart account.
    /// @param moduleTypeId The identifier for the module type being uninstalled.
    /// @param module The address of the module to uninstall.
    /// @param deInitData De-initialization data for configuring the module upon uninstallation.
    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable;

    /// @notice Checks if a specific module is installed on the smart account.
    /// @param moduleTypeId The module type identifier to check.
    /// @param module The address of the module.
    /// @param additionalContext Additional information that may be required to verify the module's installation.
    /// @return installed True if the module is installed, false otherwise.
    function isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) external view returns (bool installed);
}
