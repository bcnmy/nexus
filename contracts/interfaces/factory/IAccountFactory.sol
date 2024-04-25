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

/// @title Nexus - IAccountFactory Interface
/// @notice Interface for creating Smart Accounts within the Nexus suite, compliant with ERC-4337 and ERC-7579.
/// @dev This interface defines the creation method for Smart Accounts, specifying the necessary parameters for account setup and configuration.
/// It includes an event that logs the creation of new accounts, detailing the associated modules and their installation data.
/// This contract supports dynamic account creation using modular designs for varied validation strategies and operational scopes.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IAccountFactory {
    /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
    event AccountCreated(address indexed account, address indexed validationModule, bytes moduleInstallData);

    /// @notice Creates a new Smart Account with a specified validation module and initialization data.
    /// @dev Deploys a new Smart Account deterministically using EIP-1167 minimal proxy pattern and initializes it with the provided module and data.
    /// @param validationModule The address of the module used for validation in the new Smart Account.
    /// @param moduleInstallData Initialization data for configuring the module on the new Smart Account.
    /// @param index An additional parameter that can be used to influence the creation process, often used as a nonce.
    /// @return account The address of the newly created payable Smart Account.
    function createAccount(
        address validationModule,
        bytes calldata moduleInstallData,
        uint256 index
    ) external payable returns (address payable account);
}
