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

/// @title Interface for Abstract Nexus Factory
/// @notice Interface that provides the essential structure for Nexus factories.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface INexusFactory {
    /// @notice Emitted when a new Smart Account is created.
    /// @param account The address of the newly created account.
    /// @param initData Initialization data used for the new Smart Account.
    /// @param salt Unique salt used during the creation of the Smart Account.
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);

    /// @notice Error indicating that the account is already deployed
    /// @param account The address of the account that is already deployed
    error AccountAlreadyDeployed(address account);

    /// @notice Error thrown when the owner address is zero.
    error ZeroAddressNotAllowed();

    /// @notice Error thrown when the implementation address is zero.
    error ImplementationAddressCanNotBeZero();

    /// @notice Error thrown when the implementation code is empty.
    error ImplementationCodeCanNotBeEmpty();

    /// @notice Creates a new Nexus with initialization data.
    /// @param initData Initialization data to be called on the new Smart Account.
    /// @param salt Unique salt for the Smart Account creation.
    /// @return The address of the newly created Nexus.
    function createAccount(bytes calldata initData, bytes32 salt) external payable returns (address payable);

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param initData Initialization data to be called on the new Smart Account.
    /// @param salt Unique salt for the Smart Account creation.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    function computeAccountAddress(bytes calldata initData, bytes32 salt) external view returns (address payable expectedAddress);
}
