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
contract BiconomyMetaFactory is Stakeable {

    error FactoryNotWhotelisted();

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

    // removeFactoryFromWhitelist

    // Note: deploy using only one of the whitelisted factories
    // these factories could possibly enshrine specific module/s
    // factory should know how to decode this factoryData

    // Review this vs deployWithFactory(address factory, bytes calldata initData, bytes32 salt)

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
        require(success, "Call to createAccount failed");

        // If needed to return created address mload returnData
        // Decode the returned address
        address payable createdAccount;
        assembly {
            createdAccount := mload(add(returnData, 0x20))
        }
        return createdAccount;
    }
}