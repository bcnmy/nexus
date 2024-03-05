// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import { SentinelListLib, SENTINEL } from "sentinellist/SentinelList.sol";

interface IStorage {
    /// @custom:storage-location erc7201:biconomy.storage.SmartAccount
    struct AccountStorage {
        mapping(address => address) modules; // Review: Make use of SentinelListLib.SentinelList here
    }
}
