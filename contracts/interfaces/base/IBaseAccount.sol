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
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337,
// using Entrypoint version 0.7.0, developed by Biconomy. Learn more at https://biconomy.io/

import { IBaseAccountEventsAndErrors } from "./IBaseAccountEventsAndErrors.sol";

/// @title Nexus - IBaseAccount
/// @notice Interface for the BaseAccount functionalities compliant with ERC-7579 and ERC-4337.
/// @dev Interface for organizing the base functionalities using the Nexus suite.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IBaseAccount is IBaseAccountEventsAndErrors {
    /// @notice Adds deposit to the EntryPoint to fund transactions.
    function addDeposit() external payable;

    /// @notice Withdraws ETH from the EntryPoint to a specified address.
    /// @param to The address to receive the withdrawn funds.
    /// @param amount The amount to withdraw.
    function withdrawDepositTo(address to, uint256 amount) external payable;

    /// @notice Gets the nonce for a particular key.
    /// @param key The nonce key.
    /// @return The nonce associated with the key.
    function nonce(uint192 key) external view returns (uint256);

    /// @notice Returns the current deposit balance of this account on the EntryPoint.
    /// @return The current balance held at the EntryPoint.
    function getDeposit() external view returns (uint256);

    /// @notice Retrieves the address of the EntryPoint contract, currently using version 0.7.
    /// @return The address of the EntryPoint contract.
    function entryPoint() external view returns (address);
}
