// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.24;

interface IStorage {
    /// @custom:storage-location erc7201:openzeppelin.storage.ERC20
    struct AccountStorage {
        mapping(address => address) modules;
    }
}
