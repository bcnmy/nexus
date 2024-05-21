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

import { Ownable } from "solady/src/auth/Ownable.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { IStakeable } from "../interfaces/common/IStakeable.sol";

/// @title Stakeable Entity
/// @notice Provides functionality to stake, unlock, and withdraw Ether on an EntryPoint.
contract Stakeable is Ownable, IStakeable {
    constructor(address newOwner) {
        _setOwner(newOwner);
    }

    /// @notice Stakes a certain amount of Ether on an EntryPoint.
    /// @dev The contract should have enough Ether to cover the stake.
    /// @param epAddress Address of the EntryPoint where the stake is added.
    /// @param unstakeDelaySec The delay in seconds before the stake can be unlocked.
    function addStake(address epAddress, uint32 unstakeDelaySec) external payable onlyOwner {
        require(epAddress != address(0), "Invalid EP address");
        IEntryPoint(epAddress).addStake{ value: msg.value }(unstakeDelaySec);
    }

    /// @notice Unlocks the stake on an EntryPoint.
    /// @dev This starts the unstaking delay after which funds can be withdrawn.
    /// @param epAddress Address of the EntryPoint where the stake is unlocked.
    function unlockStake(address epAddress) external onlyOwner {
        require(epAddress != address(0), "Invalid EP address");
        IEntryPoint(epAddress).unlockStake();
    }

    /// @notice Withdraws the stake from an EntryPoint to a specified address.
    /// @dev This can only be done after the unstaking delay has passed since the unlock.
    /// @param epAddress Address of the EntryPoint where the stake is withdrawn from.
    /// @param withdrawAddress Address to receive the withdrawn stake.
    function withdrawStake(address epAddress, address payable withdrawAddress) external onlyOwner {
        require(epAddress != address(0), "Invalid EP address");
        IEntryPoint(epAddress).withdrawStake(withdrawAddress);
    }
}
