// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibClone } from "solady/src/utils/LibClone.sol";
import { INexus } from "../interfaces/INexus.sol";
import { AbstractNexusFactory } from "./AbstractNexusFactory.sol";

/// @title Nexus Account Factory
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a factory pattern.
contract NexusAccountFactory is AbstractNexusFactory {
    /// @notice Constructor to set the smart account implementation address and owner.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    /// @param owner The address of the owner of the factory.
    constructor(address implementation, address owner) AbstractNexusFactory(implementation, owner) {}

    /// @notice Creates a new Nexus account with the provided initialization data.
    /// @param initData Initialization data to be called on the new Smart Account.
    /// @param salt Unique salt for the Smart Account creation.
    /// @return The address of the newly created Nexus account.
    function createAccount(bytes calldata initData, bytes32 salt) external payable override returns (address payable) {
        // Compute the actual salt for deterministic deployment
        bytes32 actualSalt;
        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }

        // Deploy the account using the deterministic address
        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, actualSalt);

        if (!alreadyDeployed) {
            INexus(account).initializeAccount(initData);
            emit AccountCreated(account, initData, salt);
        }
        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param - Initialization data to be called on the new Smart Account.
    /// @param - Unique salt for the Smart Account creation.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    function computeAccountAddress(bytes calldata, bytes32) external view override returns (address payable expectedAddress) {
        // Compute the actual salt for deterministic deployment
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
