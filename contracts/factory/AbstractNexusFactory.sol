// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Stakeable } from "../common/Stakeable.sol";
import { IAbstractNexusFactory } from "../interfaces/factory/IAbstractNexusFactory.sol";

/// @title AbstractNexusFactory
/// @notice Provides common functionality for Nexus factories, enabling the creation and management of Modular Smart Accounts.
abstract contract AbstractNexusFactory is Stakeable, IAbstractNexusFactory {
    /// @notice Address of the implementation contract used to create new Nexus instances.
    /// @dev This address is immutable and set upon deployment, ensuring the implementation cannot be changed.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Constructor to set the smart account implementation address and the factory owner.
    /// @param implementation_ The address of the Nexus implementation to be used for all deployments.
    /// @param owner_ The address of the owner of the factory.
    constructor(address implementation_, address owner_) Stakeable(owner_) {
        if (implementation_ == address(0)) {
            revert ImplementationAddressCanNotBeZero();
        }
        ACCOUNT_IMPLEMENTATION = implementation_;
    }

    /// @notice Creates a new Nexus with the provided initialization data.
    /// @param initData Initialization data to be called on the new Smart Account.
    /// @param salt Unique salt for the Smart Account creation.
    /// @return The address of the newly created Nexus.
    function createAccount(bytes calldata initData, bytes32 salt) external payable virtual override returns (address payable);

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param initData Initialization data to be called on the new Smart Account.
    /// @param salt Unique salt for the Smart Account creation.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    function computeAccountAddress(bytes calldata initData, bytes32 salt) external view virtual override returns (address payable expectedAddress);
}
