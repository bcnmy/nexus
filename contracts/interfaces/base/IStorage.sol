// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { SentinelListLib } from "sentinellist/src/SentinelList.sol";

interface IStorage {
    /// @custom:storage-location erc7201:biconomy.storage.SmartAccount
    struct AccountStorage {
        mapping(address => address) modules; // Review: Make use of SentinelListLib.SentinelList here
        // // linked list of validators. List is initialized by initializeAccount()
        // SentinelListLib.SentinelList validators;
        // // linked list of executors. List is initialized by initializeAccount()
        // SentinelListLib.SentinelList executors;
    }
}
