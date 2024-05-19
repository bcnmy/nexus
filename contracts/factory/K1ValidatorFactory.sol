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
import { INexus } from "../interfaces/INexus.sol";
import { IAccountFactory } from "../interfaces/factory/IAccountFactory.sol";
import { BootstrapUtil } from "../utils/BootstrapUtil.sol";
import { Bootstrap, BootstrapConfig } from "../utils/Bootstrap.sol";

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
contract K1ValidatorFactory is IAccountFactory, BootstrapUtil {
    /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);
    
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Stores the K1 Validator module address
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable K1_VALIDATOR;

    /// @notice Constructor to set the smart account implementation address.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    constructor(address implementation, address k1Validator) {
        ACCOUNT_IMPLEMENTATION = implementation;
        K1_VALIDATOR = k1Validator;
    }

    /// @notice Creates a new Nexus with a specific validator and initialization data.
    /// @param moduleInitData initialization data for K1 Validator.
    /// @param salt unique salt for the Smart Account creation. enables multiple SA deployment for the same initData (modules, ownership info etc).
    /// @return The address of the newly created Nexus.
    /// @dev Deploys a new Nexus using a deterministic address based on the input parameters.
    function createAccount(bytes calldata moduleInitData, bytes32 salt) external payable returns (address payable) {
        (salt);
        bytes32 actualSalt;
        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }

        // Review: if salt should include K1 Validator address as well

        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, actualSalt);

        // we could also just pass address eoaOwner above, if IAccountFactory consistency is not important
        BootstrapConfig memory validator = _makeBootstrapConfig(K1_VALIDATOR, moduleInitData);

        bytes memory _initData = bootstrapSingleton._getInitNexusWithSingleValidatorCalldata(validator);

        if (!alreadyDeployed) {
            INexus(account).initializeAccount(_initData);
            emit AccountCreated(account, _initData, actualSalt);
        }
        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param moduleInitData initialization data for K1 Validator.
    /// @param salt unique salt for the Smart Account creation. enables multiple SA deployment for the same initData (modules, ownership info etc).
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    /// @dev This function allows for address calculation without deploying the Nexus.
    function computeAccountAddress(
        bytes calldata moduleInitData, bytes32 salt
    ) external view returns (address payable expectedAddress) {
        (moduleInitData, salt);
        bytes32 actualSalt;

        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }

        // Review: if salt should include K1 Validator address as well

        expectedAddress = payable(LibClone.predictDeterministicAddressERC1967(ACCOUNT_IMPLEMENTATION, actualSalt, address(this)));
    }
}
