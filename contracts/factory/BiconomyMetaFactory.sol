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

import { Stakeable } from "../common/Stakeable.sol";

// can stake
// can whitelist factories
// deployAccount with chosen factory and required data for that facotry

/// @title Nexus - BiconomyMetaFactory
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a factory pattern.
/// @dev Utilizes the `Stakeable` for staking requirements
///      This contract serves as a 'Meta' factory to generate new Nexus instances using specific chosen and approved factories.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
contract BiconomyMetaFactory is Stakeable {
    /// @dev Throws when the factory is not whitelisted.
    error FactoryNotWhotelisted();

    /// @dev Stores the factory addresses that are whitelisted.
    mapping(address => bool) public factoryWhitelist;

    constructor(address owner) Stakeable(owner) {
    }

    /// @notice Adds an address to the factory whitelist.
    /// @param factory The address to be whitelisted.
    function addFactoryToWhitelist(address factory) external onlyOwner {
        factoryWhitelist[factory] = true;
    }

    /// @notice Removes an address from the factory whitelist.
    /// @param factory The address to be removed from the whitelist.
    function removeFactoryFromWhitelist(address factory) external onlyOwner {
        factoryWhitelist[factory] = false;
    }


    /// @notice Checks if an address is whitelisted.
    /// @param factory The address to check.
    function isWhitelisted(address factory) public view returns (bool) {
        return factoryWhitelist[factory];
    }

    // Note: deploy using only one of the whitelisted factories
    // these factories could possibly enshrine specific module/s
    // factory should know how to decode this factoryData

    // Review this vs deployWithFactory(address factory, bytes calldata initData, bytes32 salt)

    /// @notice Deploys a new Nexus with a specific factory and initialization data.
    /// @dev factoryData is the encoded data for the method to be called on the Factory
    /// @dev factoryData is posted on the factory using factory.call(factoryData) 
    ///      instead of calling a specific method always to allow more freedom.
    ///      factory should know how to decode this factoryData
    /// @notice These factories could possibly enshrine specific module/s to avoid arbitary execution and prevent griefing.
    /// @notice Another benefit of this pattern is that the factory can be upgraded without changing this contract.
    /// @param factory The address of the factory to be used for deployment.
    /// @param factoryData The encoded data for the method to be called on the Factory.
    function deployWithFactory(address factory, bytes calldata factoryData)
        external
        payable
        returns (address payable)
    {
        if (!factoryWhitelist[address(factory)]) {
            revert FactoryNotWhotelisted();
        }
        (bool success, bytes memory returnData) = factory.call(factoryData);

        // if needed to make success check add this here
        // Check if the call was successful
        require(success, "Call to deployWithFactory failed");

        // If needed to return created address mload returnData
        // Decode the returned address
        address payable createdAccount;
        assembly {
            createdAccount := mload(add(returnData, 0x20))
        }
        return createdAccount;
    }
}