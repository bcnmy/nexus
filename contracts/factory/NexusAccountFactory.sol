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

import { Stakeable } from "../common/Stakeable.sol";
import { INexusFactory } from "../interfaces/factory/INexusFactory.sol";
import { ProxyLib } from "../lib/ProxyLib.sol";

/// @title Nexus Account Factory
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a factory pattern.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract NexusAccountFactory is Stakeable, INexusFactory {
    /// @notice Address of the implementation contract used to create new Nexus instances.
    /// @dev This address is immutable and set upon deployment, ensuring the implementation cannot be changed.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Constructor to set the smart account implementation address and the factory owner.
    /// @param implementation_ The address of the Nexus implementation to be used for all deployments.
    /// @param owner_ The address of the owner of the factory.
    constructor(address implementation_, address owner_, address entryPoint) Stakeable(owner_, entryPoint) {
        require(implementation_ != address(0), ImplementationAddressCanNotBeZero());
        require(owner_ != address(0), ZeroAddressNotAllowed());
        ACCOUNT_IMPLEMENTATION = implementation_;
    }

    /// @notice Creates a new Nexus account with the provided initialization data.
    /// @param initData Initialization data to be called on the new Smart Account.
    /// @param salt Unique salt for the Smart Account creation.
    /// @return The address of the newly created Nexus account.
    function createAccount(bytes calldata initData, bytes32 salt) external payable override returns (address payable) {
        // Deploy the Nexus account using the ProxyLib
        (bool alreadyDeployed, address payable account) = ProxyLib.deployProxy(ACCOUNT_IMPLEMENTATION, salt, initData);
        if (!alreadyDeployed) {
            emit AccountCreated(account, initData, salt);
        }
        return account;
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param initData - Initialization data to be called on the new Smart Account.
    /// @param salt - Unique salt for the Smart Account creation.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    function computeAccountAddress(bytes calldata initData, bytes32 salt) external view override returns (address payable expectedAddress) {
        // Return the expected address of the Nexus account using the provided initialization data and salt
        return ProxyLib.predictProxyAddress(ACCOUNT_IMPLEMENTATION, salt, initData);
    }
}
