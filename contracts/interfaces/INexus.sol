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

import { IERC4337Account } from "./IERC4337Account.sol";
import { IERC7579Account } from "./IERC7579Account.sol";
import { INexusEventsAndErrors } from "./INexusEventsAndErrors.sol";

/// @title Nexus - INexus Interface
/// @notice Integrates ERC-4337 and ERC-7579 standards to manage smart accounts within the Nexus suite.
/// @dev Consolidates ERC-4337 user operations and ERC-7579 configurations into a unified interface for smart account management.
/// It extends both IERC4337Account and IERC7579Account, enhancing modular capabilities and supporting advanced contract architectures.
/// Includes error definitions for robust handling of common issues such as unsupported module types and execution failures.
/// The initialize function sets up the account with validators and configurations, ensuring readiness for use.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface INexus is IERC4337Account, IERC7579Account, INexusEventsAndErrors {
    /// @notice Initializes the smart account with a validator and custom data.
    /// @dev This method sets up the account for operation, linking it with a validator and initializing it with specific data.
    /// Can be called directly or via a factory.
    /// @param firstValidator The address of the validator to install during initialization.
    /// @param initData Encoded data used for the account's configuration during initialization.
    function initialize(address firstValidator, bytes calldata initData) external payable;
}
