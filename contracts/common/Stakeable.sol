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

import { Ownable } from "solady/auth/Ownable.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

import { IStakeable } from "../interfaces/common/IStakeable.sol";

/// @title Stakeable Entity
/// @notice Provides functionality to stake, unlock, and withdraw Ether on an EntryPoint.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract Stakeable is Ownable, IStakeable {
    /// @notice Error thrown when an invalid EntryPoint address is provided.
    error InvalidEntryPointAddress();

    address public immutable ENTRY_POINT;

    constructor(address newOwner, address entryPoint) {
        _setOwner(newOwner);
        require(entryPoint != address(0), InvalidEntryPointAddress());
        ENTRY_POINT = entryPoint;
    }

    /// @notice Stakes a certain amount of Ether on an EntryPoint.
    /// @dev The contract should have enough Ether to cover the stake.
    /// @param unstakeDelaySec The delay in seconds before the stake can be unlocked.
    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        IEntryPoint(ENTRY_POINT).addStake{ value: msg.value }(unstakeDelaySec);
    }

    /// @notice Unlocks the stake on an EntryPoint.
    /// @dev This starts the unstaking delay after which funds can be withdrawn.
    function unlockStake() external onlyOwner {
        IEntryPoint(ENTRY_POINT).unlockStake();
    }

    /// @notice Withdraws the stake from an EntryPoint to a specified address.
    /// @dev This can only be done after the unstaking delay has passed since the unlock.
    /// @param withdrawAddress The address to receive the withdrawn stake.
    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        IEntryPoint(ENTRY_POINT).withdrawStake(withdrawAddress);
    }
}
