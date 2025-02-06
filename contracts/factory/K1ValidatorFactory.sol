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
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

import { BootstrapLib } from "../lib/BootstrapLib.sol";
import { NexusBootstrap, BootstrapConfig } from "../utils/NexusBootstrap.sol";
import { Stakeable } from "../common/Stakeable.sol";
import { IERC7484 } from "../interfaces/IERC7484.sol";
import { ProxyLib } from "../lib/ProxyLib.sol";

/// @title K1ValidatorFactory for Nexus Account
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a K1 validator.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract K1ValidatorFactory is Stakeable {
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Stores the K1 Validator module address.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable K1_VALIDATOR;

    /// @notice Stores the Bootstrapper module address.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    NexusBootstrap public immutable BOOTSTRAPPER;

    IERC7484 public immutable REGISTRY;

    /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
    event AccountCreated(address indexed account, address indexed owner, uint256 indexed index);

    /// @notice Error thrown when a zero address is provided for the implementation, K1 validator, or bootstrapper.
    error ZeroAddressNotAllowed();

    /// @notice Error thrown when the createAccount function is called by a non-EntryPoint.
    error EntryPointOnly();

    /// @notice Constructor to set the immutable variables.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    /// @param factoryOwner The address of the factory owner.
    /// @param k1Validator The address of the K1 Validator module to be used for all deployments.
    /// @param bootstrapper The address of the Bootstrapper module to be used for all deployments.
    constructor(
        address implementation,
        address factoryOwner,
        address entryPoint,
        address k1Validator,
        NexusBootstrap bootstrapper,
        IERC7484 registry
    )
        Stakeable(factoryOwner, entryPoint)
    {
        require(
            !(implementation == address(0) || k1Validator == address(0) || address(bootstrapper) == address(0) || factoryOwner == address(0)),
            ZeroAddressNotAllowed()
        );
        ACCOUNT_IMPLEMENTATION = implementation;
        K1_VALIDATOR = k1Validator;
        BOOTSTRAPPER = bootstrapper;
        REGISTRY = registry;
    }

    /// @notice Creates a new Nexus with K1 validator and initialization data.
    /// @param eoaOwner The address of the EOA owner of the Nexus.
    /// @param index The index of the Nexus.
    /// @param attesters The list of attesters for the Nexus.
    /// @param threshold The threshold for the Nexus.
    /// @return The address of the newly created Nexus.
    function createAccount(address eoaOwner, uint256 index, address[] calldata attesters, uint8 threshold) external payable returns (address payable) {
        // Compute the salt for deterministic deployment
        bytes32 salt = keccak256(abi.encodePacked(eoaOwner, index, attesters, threshold));

        // Create the validator configuration using the NexusBootstrap library
        BootstrapConfig memory validator = BootstrapLib.createSingleConfig(K1_VALIDATOR, abi.encodePacked(eoaOwner));
        bytes memory initData = BOOTSTRAPPER.getInitNexusWithSingleValidatorCalldata(validator, REGISTRY, attesters, threshold);

        // Deploy the Nexus account using the ProxyLib
        (bool alreadyDeployed, address payable account) = ProxyLib.deployProxy(ACCOUNT_IMPLEMENTATION, salt, initData);
        if (!alreadyDeployed) {
            emit AccountCreated(account, eoaOwner, index);
        }
        return account;
    }

    /// @notice Creates a new Nexus with K1 validator and initialization data by the EntryPoint.
    /// @dev same as createAccount but should be called by the EntryPoint
    /// Wallets should use this method to prevent front-running userOp.initcode execution which can lead the whole userOp to fail
    /// See AA-466 for more details https://github.com/eth-infinitism/account-abstraction/pull/514         
    function createAccountByEP(address eoaOwner, uint256 index, address[] calldata attesters, uint8 threshold) external payable returns (address payable) {
        require(msg.sender == IEntryPoint(ENTRY_POINT).senderCreator(), EntryPointOnly());
        return createAccount(eoaOwner, index, attesters, threshold);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param eoaOwner The address of the EOA owner of the Nexus.
    /// @param index The index of the Nexus.
    /// @param attesters The list of attesters for the Nexus.
    /// @param threshold The threshold for the Nexus.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    function computeAccountAddress(
        address eoaOwner,
        uint256 index,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        view
        returns (address payable expectedAddress)
    {
        // Compute the salt for deterministic deployment
        bytes32 salt = keccak256(abi.encodePacked(eoaOwner, index, attesters, threshold));

        // Create the validator configuration using the NexusBootstrap library
        BootstrapConfig memory validator = BootstrapLib.createSingleConfig(K1_VALIDATOR, abi.encodePacked(eoaOwner));

        // Get the initialization data for the Nexus account
        bytes memory initData = BOOTSTRAPPER.getInitNexusWithSingleValidatorCalldata(validator, REGISTRY, attesters, threshold);

        // Compute the predicted address using the ProxyLib
        return ProxyLib.predictProxyAddress(ACCOUNT_IMPLEMENTATION, salt, initData);
    }
}
