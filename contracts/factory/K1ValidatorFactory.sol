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
import { BootstrapUtil } from "../utils/BootstrapUtil.sol";
import { Bootstrap, BootstrapConfig } from "../utils/Bootstrap.sol";
import { Stakeable } from "../common/Stakeable.sol";

/// @title Nexus - K1ValidatorFactory for Nexus account
contract K1ValidatorFactory is BootstrapUtil, Stakeable {
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Stores the K1 Validator module address
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable K1_VALIDATOR;

    /// @notice Stores the K1 Validator module address
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    Bootstrap public immutable BOOTSTRAPPER;

    /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
    event AccountCreated(address indexed account, address indexed owner, uint256 indexed index);

    /// @notice Constructor to set the immutable variables.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    /// @param k1Validator The address of the K1 Validator module to be used for all deployments.
    /// @param bootstrapper The address of the Boostrapper module to be used for all deployments.
    constructor(address factoryOwner, address implementation, address k1Validator, Bootstrap bootstrapper) Stakeable(factoryOwner) {
        ACCOUNT_IMPLEMENTATION = implementation;
        K1_VALIDATOR = k1Validator;
        BOOTSTRAPPER = bootstrapper;
    }

    /// @notice Creates a new Nexus with a specific validator and initialization data.
    /// @param eoaOwner The address of the EOA owner of the Nexus.
    /// @param index The index of the Nexus.
    /// @return The address of the newly created Nexus.
    /// @dev Deploys a new Nexus using a deterministic address based on the input parameters.
    function createAccount(address eoaOwner, uint256 index) external payable returns (address payable) {
        (index);
        bytes32 actualSalt;
        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }
        // Review: if salt should include K1 Validator address as well
        // actualSalt = keccak256(abi.encodePacked(actualSalt, K1_VALIDATOR));

        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, actualSalt);
        BootstrapConfig memory validator = makeBootstrapConfigSingle(K1_VALIDATOR, abi.encodePacked(eoaOwner));
        bytes memory initData = BOOTSTRAPPER.getInitNexusWithSingleValidatorCalldata(validator);

        if (!alreadyDeployed) {
            INexus(account).initializeAccount(initData);
            emit AccountCreated(account, eoaOwner, index);
        }
        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param eoaOwner The address of the EOA owner of the Nexus.
    /// @param index The index of the Nexus.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    /// @dev This function allows for address calculation without deploying the Nexus.
    function computeAccountAddress(address eoaOwner, uint256 index) external view returns (address payable expectedAddress) {
        (eoaOwner, index);
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
