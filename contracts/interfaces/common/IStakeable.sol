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

/// @title Stakeable Entity Interface
/// @notice Interface for staking, unlocking, and withdrawing Ether on an EntryPoint.
/// @dev Defines functions for managing stakes on an EntryPoint.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IStakeable {
    /// @notice Stakes a certain amount of Ether on an EntryPoint.
    /// @dev The contract should have enough Ether to cover the stake.
    /// @param unstakeDelaySec The delay in seconds before the stake can be unlocked.
    function addStake(uint32 unstakeDelaySec) external payable;

    /// @notice Unlocks the stake on an EntryPoint.
    /// @dev This starts the unstaking delay after which funds can be withdrawn.
    function unlockStake() external;

    /// @notice Withdraws the stake from an EntryPoint to a specified address.
    /// @dev This can only be done after the unstaking delay has passed since the unlock.
    /// @param withdrawAddress The address to receive the withdrawn stake.
    function withdrawStake(address payable withdrawAddress) external;
}
