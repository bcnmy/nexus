// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

/// @title Execution Manager Events and Errors Interface
/// @notice Interface for defining events and errors related to transaction execution processes within smart accounts.
/// @dev This interface defines events and errors used by execution manager to handle and report the operational status of smart account transactions.
/// It is a part of the Nexus suite of contracts aimed at implementing flexible and secure smart account operations.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady

import { ExecType } from "../../lib/ModeLib.sol";

interface IExecutionHelperEventsAndErrors {
    /// @notice Event emitted when a transaction fails to execute successfully.
    event TryExecuteUnsuccessful(uint256 batchExecutionindex, bytes result);

    /// @notice Event emitted when a transaction fails to execute successfully.
    event TryDelegateCallUnsuccessful(uint256 batchExecutionindex, bytes result);

    /// @notice Error thrown when an execution with an unsupported ExecType was made.
    /// @param execType The unsupported execution type.
    error UnsupportedExecType(ExecType execType);
}
