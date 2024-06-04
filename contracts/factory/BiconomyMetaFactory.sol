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
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

import { Stakeable } from "../common/Stakeable.sol";

/// @title BiconomyMetaFactory
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a factory pattern.
/// @dev Utilizes the `Stakeable` for staking requirements.
///      This contract serves as a 'Meta' factory to generate new Nexus instances using specific chosen and approved factories.
/// @dev Can whitelist factories, deploy accounts with chosen factory and required data for that factory.
///      The factories could possibly enshrine specific modules to avoid arbitrary execution and prevent griefing.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract BiconomyMetaFactory is Stakeable {
    /// @notice Stores the factory addresses that are whitelisted.
    mapping(address => bool) public factoryWhitelist;

    /// @notice Error thrown when the factory is not whitelisted.
    error FactoryNotWhitelisted();

    /// @notice Error thrown when the factory address is zero.
    error InvalidFactoryAddress();

    /// @notice Error thrown when the owner address is zero.
    error ZeroAddressNotAllowed();

    /// @notice Error thrown when the call to deploy with factory failed.
    error CallToDeployWithFactoryFailed();

    /// @notice Constructor to set the owner of the contract.
    /// @param owner_ The address of the owner.
    constructor(address owner_) Stakeable(owner_) {
        require(owner_ != address(0), ZeroAddressNotAllowed());
    }

    /// @notice Adds an address to the factory whitelist.
    /// @param factory The address to be whitelisted.
    function addFactoryToWhitelist(address factory) external onlyOwner {
        require(factory != address(0), InvalidFactoryAddress());
        factoryWhitelist[factory] = true;
    }

    /// @notice Removes an address from the factory whitelist.
    /// @param factory The address to be removed from the whitelist.
    function removeFactoryFromWhitelist(address factory) external onlyOwner {
        factoryWhitelist[factory] = false;
    }

    // Note: deploy using only one of the whitelisted factories
    // these factories could possibly enshrine specific module/s
    // factory should know how to decode this factoryData

    /// @notice Deploys a new Nexus with a specific factory and initialization data.
    /// @dev Uses factory.call(factoryData) to post the encoded data for the method to be called on the Factory.
    ///      These factories could enshrine specific modules to avoid arbitrary execution and prevent griefing.
    ///      Another benefit of this pattern is that the factory can be upgraded without changing this contract.
    /// @param factory The address of the factory to be used for deployment.
    /// @param factoryData The encoded data for the method to be called on the Factory.
    /// @return createdAccount The address of the newly created Nexus account.
    function deployWithFactory(address factory, bytes calldata factoryData) external payable returns (address payable createdAccount) {
        require(factoryWhitelist[address(factory)], FactoryNotWhitelisted());
        (bool success, bytes memory returnData) = factory.call(factoryData);

        // Check if the call was successful
        require(success, CallToDeployWithFactoryFailed());

        // Decode the returned address
        assembly {
            createdAccount := mload(add(returnData, 0x20))
        }
    }

    /// @notice Checks if an address is whitelisted.
    /// @param factory The address to check.
    /// @return True if the factory is whitelisted, false otherwise.
    function isFactoryWhitelisted(address factory) public view returns (bool) {
        return factoryWhitelist[factory];
    }
}
