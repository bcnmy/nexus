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
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337,
// using Entrypoint version 0.7.0, developed by Biconomy. Learn more at https://biconomy.io/

import { IAccountConfig } from "./base/IAccountConfig.sol";
import { IExecutionManager } from "./base/IExecutionManager.sol";
import { IModuleManager } from "./base/IModuleManager.sol";

/// @title Nexus - IERC7579Account
/// @notice This interface integrates the functionalities required for a modular smart account compliant with ERC-7579 and ERC-4337 standards.
/// @dev Combines configurations and operational management for smart accounts, bridging IAccountConfig, IExecutionManager, and IModuleManager.
/// Interfaces designed to support the comprehensive management of smart account operations including execution management and modular configurations.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IERC7579Account is IAccountConfig, IExecutionManager, IModuleManager {
    /// @dev Validates a smart account signature according to ERC-1271 standards.
    /// This method may delegate the call to a validator module to check the signature.
    /// @param hash The hash of the data being validated.
    /// @param data The signed data to validate.
    function isValidSignature(bytes32 hash, bytes calldata data) external view returns (bytes4);
}
