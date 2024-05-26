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

import { LibClone } from "solady/src/utils/LibClone.sol";
import { Stakeable } from "../common/Stakeable.sol";
import { INexus } from "../interfaces/INexus.sol";
import { INexusAccountFactory } from "../interfaces/factory/INexusAccountFactory.sol";

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
contract NexusAccountFactory is INexusAccountFactory, Stakeable {
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    // Review may not need stakeable here

    /// @notice Constructor to set the smart account implementation address.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    constructor(address implementation, address owner) Stakeable(owner) {
        if (implementation == address(0)) {
            revert ImplementationAddressCanNotBeZero();
        }
        ACCOUNT_IMPLEMENTATION = implementation;
    }

    /// @notice Creates a new Nexus with a specific validator and initialization data.
    /// @param initData initialization data to be called on the new Smart Account.
    /// @param salt unique salt for the Smart Account creation. enables multiple SA deployment for the same initData (modules, ownership info etc).
    /// @return The address of the newly created Nexus.
    /// @dev Deploys a new Nexus using a deterministic address based on the input parameters.
    function createAccount(bytes calldata initData, bytes32 salt) external payable returns (address payable) {
        bytes32 actualSalt;
        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }

        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, actualSalt);

        if (!alreadyDeployed) {
            INexus(account).initializeAccount(initData);
            emit AccountCreated(account, initData, salt);
        }
        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param initData initialization data to be called on the new Smart Account.
    /// @param salt unique salt for the Smart Account creation. enables multiple SA deployment for the same initData (modules, ownership info etc).
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    /// @dev This function allows for address calculation without deploying the Nexus.
    function computeAccountAddress(bytes calldata initData, bytes32 salt) external view returns (address payable expectedAddress) {
        (initData, salt);
        bytes32 actualSalt;

        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }

        expectedAddress = payable(LibClone.predictDeterministicAddressERC1967(ACCOUNT_IMPLEMENTATION, actualSalt, address(this)));
    }
}
