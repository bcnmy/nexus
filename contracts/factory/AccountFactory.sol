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
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

import { LibClone } from "solady/src/utils/LibClone.sol";
import { Stakeable } from "../common/Stakeable.sol";
import { INexus } from "../interfaces/INexus.sol";
import { IAccountFactory } from "../interfaces/factory/IAccountFactory.sol";

/// @title Nexus - AccountFactory
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a factory pattern.
/// @dev Utilizes the `StakeManager` for staking requirements and `LibClone` for creating deterministic proxy accounts.
///       This contract serves as a factory to generate new Nexus instances with specific modules and initialization data.
///       It combines functionality from Biconomy's implementation and external libraries to manage account deployments and initializations.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract AccountFactory is IAccountFactory, Stakeable {
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Constructor to set the smart account implementation address.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    constructor(address implementation, address owner) Stakeable(owner) {
        ACCOUNT_IMPLEMENTATION = implementation;
    }

    /// @notice Creates a new Nexus with a specific validator and initialization data.
    /// @param validationModule The address of the validation module to configure the new Nexus.
    /// @param moduleInstallData Initialization data for configuring the validation module.
    /// @param index An identifier used to generate a unique deployment address.
    /// @return The address of the newly created Nexus.
    /// @dev Deploys a new Nexus using a deterministic address based on the input parameters.
    function createAccount(address validationModule, bytes calldata moduleInstallData, uint256 index) external payable returns (address payable) {
        (index);
        bytes32 salt;

        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            salt := keccak256(ptr, calldataLength)
        }

        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, salt);

        if (!alreadyDeployed) {
            INexus(account).initialize(validationModule, moduleInstallData);
            emit AccountCreated(account, validationModule, moduleInstallData);
        }
        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param validationModule The address of the module to be used in the Nexus.
    /// @param moduleInstallData The initialization data for the module.
    /// @param index The index or type of the module, used for generating the deployment address.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    /// @dev This function allows for address calculation without deploying the Nexus.
    function computeAccountAddress(
        address validationModule,
        bytes calldata moduleInstallData,
        uint256 index
    ) external view returns (address payable expectedAddress) {
        (validationModule, moduleInstallData, index);
        bytes32 salt;

        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            salt := keccak256(ptr, calldataLength)
        }

        expectedAddress = payable(LibClone.predictDeterministicAddressERC1967(ACCOUNT_IMPLEMENTATION, salt, address(this)));
    }
}
