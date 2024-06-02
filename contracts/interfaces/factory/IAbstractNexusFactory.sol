// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Interface for Abstract Nexus Factory
/// @notice Interface that provides the essential structure for Nexus factories.
interface IAbstractNexusFactory {
    /// @notice Emitted when a new Smart Account is created.
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);

    /// @notice Error thrown when the implementation address is zero.
    error ImplementationAddressCanNotBeZero();

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
