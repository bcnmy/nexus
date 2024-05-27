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
interface INexusAccountFactory {
    /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);

    /// @dev Thrown when the implementation address is zero address.
    error ImplementationAddressCanNotBeZero();

    /// @notice Creates a new Smart Account with a specified validation module and initialization data.
    /// @dev Deploys a new Smart Account deterministically using EIP-1167 minimal proxy pattern and initializes it with the provided module and data.
    /// @param initData initialization data to be called on the new Smart Account.
    /// @param salt unique salt for the Smart Account creation. enables multiple SA deployment for the same initData (modules, ownership info etc).
    /// @return account The address of the newly created payable Smart Account.
    function createAccount(bytes calldata initData, bytes32 salt) external payable returns (address payable account);
}
