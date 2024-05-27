// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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
import { BootstrapConfig } from "../utils/Bootstrap.sol";
import { BytesLib } from "../lib/BytesLib.sol";

/// @title Nexus - ModuleWhitelistFactory for Nexus account
contract ModuleWhitelistFactory is Stakeable {
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    /// @notice Stores the module addresses that are whitelisted.
    mapping(address => bool) public moduleWhitelist;

    /// @notice Emitted when a new Smart Account is created, capturing initData and salt used to deploy the account.
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);

    /// @notice Thorwn when the module is not whitelisted
    error ModuleNotWhitelisted(address module);

    /// @notice Constructor to set the smart account implementation address.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    constructor(address factoryOwner, address implementation) Stakeable(factoryOwner) {
        ACCOUNT_IMPLEMENTATION = implementation;
    }

    /// @notice Adds an address to the module whitelist.
    /// @param module The address to be whitelisted.
    function addModuleToWhitelist(address module) external onlyOwner {
        moduleWhitelist[module] = true;
    }

    /// @notice Removes an address from the module whitelist.
    /// @param module The address to be removed from the whitelist.
    function removeModuleFromWhitelist(address module) external onlyOwner {
        moduleWhitelist[module] = false;
    }

    function createAccount(bytes calldata initData, bytes32 salt) external payable returns (address payable) {
        // Decode the initData to extract the call target and call data
        (, bytes memory callData) = abi.decode(initData, (address, bytes));

        // Extract the inner data by removing the first 4 bytes (the function selector)
        bytes memory innerData = BytesLib.slice(callData, 4, callData.length - 4);

        // Decode the call data to extract the parameters passed to initNexus
        // Review if we should verify calldata[0:4] against the function selector of initNexus
        (
            BootstrapConfig[] memory validators,
            BootstrapConfig[] memory executors,
            BootstrapConfig memory hook,
            BootstrapConfig[] memory fallbacks
        ) = abi.decode(innerData, (BootstrapConfig[], BootstrapConfig[], BootstrapConfig, BootstrapConfig[]));

        for (uint256 i = 0; i < validators.length; i++) {
            require(isWhitelisted(validators[i].module), ModuleNotWhitelisted(validators[i].module));
        }

        for (uint256 i = 0; i < executors.length; i++) {
            require(isWhitelisted(executors[i].module), ModuleNotWhitelisted(executors[i].module));
        }

        require(isWhitelisted(hook.module), ModuleNotWhitelisted(hook.module));

        for (uint256 i = 0; i < fallbacks.length; i++) {
            require(isWhitelisted(fallbacks[i].module), ModuleNotWhitelisted(fallbacks[i].module));
        }

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

    /// @notice Checks if an address is whitelisted.
    /// @param module The address to check.
    function isWhitelisted(address module) public view returns (bool) {
        return moduleWhitelist[module];
    }
}
