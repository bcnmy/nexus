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

/// @title Execution
/// @notice Struct to encapsulate execution data for a transaction
struct Execution {
    /// @notice The target address for the transaction
    address target;
    /// @notice The value in wei to send with the transaction
    uint256 value;
    /// @notice The calldata for the transaction
    bytes callData;
}

/// @title Emergency Uninstall
/// @notice Struct to encapsulate emergency uninstall data for a hook
struct EmergencyUninstall {
    /// @notice The address of the hook to be uninstalled
    address hook;
    /// @notice The hook type identifier
    uint256 hookType;
    /// @notice Data used to uninstall the hook
    bytes deInitData;
    /// @notice Nonce used to prevent replay attacks
    uint256 nonce;
}
