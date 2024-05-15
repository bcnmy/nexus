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

import { IAccountFactory } from "../interfaces/factory/IAccountFactory.sol";
import { Stakeable } from "../common/Stakeable.sol";

// can stake
// can whitelist factories
// deployAccount with chosen factory and required data for that facotry
contract BiconomyMetaFactory is Stakeable {

    error FactoryNotWhotelisted();

    mapping(address => bool) public factoryWhitelist;

    constructor(address owner) Stakeable(owner) {
    }

    // could be IAccountFactory
    // whitelist / blacklist a factory
    function whitelistFactory(address factory, bool whitelisted) external payable onlyOwner {
        factoryWhitelist[factory] = whitelisted;
    }

    // Note: deploy using only one of the whitelisted factories
    // these factories could possibly enshrine specific module/s
    function deployWithFactory(IAccountFactory factory, bytes calldata initData, bytes32 salt)
        external
        payable
        returns (address)
    {
        if (!factoryWhitelist[address(factory)]) {
            revert FactoryNotWhotelisted();
        }
        // emit AccountDeployedWithFactory(factory, initData, salt);
        return factory.createAccount(initData, salt);
    }
}