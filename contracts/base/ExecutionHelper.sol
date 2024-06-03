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
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { Execution } from "../types/DataTypes.sol";
import { IExecutionHelperEventsAndErrors } from "../interfaces/base/IExecutionHelper.sol";

/// @title Nexus - ExecutionHelper
/// @notice Implements execution management within the Nexus suite, facilitating transaction execution strategies and
/// error handling.
/// @dev Provides mechanisms for direct and batched transactions with both committed and tentative execution strategies
/// as per ERC-4337 and ERC-7579 standards.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract ExecutionHelper is IExecutionHelperEventsAndErrors {
    /// @notice Executes a call to a target address with specified value and data.
    /// @param target The address to execute the call on.
    /// @param value The amount of wei to send with the call.
    /// @param callData The calldata to send.
    /// @return result The bytes returned from the execution.
    function _execute(address target, uint256 value, bytes calldata callData) internal virtual returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            if iszero(call(gas(), target, value, result, callData.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @notice Tries to execute a call and captures if it was successful or not.
    /// @dev Similar to _execute but returns a success boolean and catches reverts instead of propagating them.
    /// @param target The address to execute the call on.
    /// @param value The amount of wei to send with the call.
    /// @param callData The calldata to send.
    /// @return success True if the execution was successful, false otherwise.
    /// @return result The bytes returned from the execution.
    function _tryExecute(address target, uint256 value, bytes calldata callData) internal virtual returns (bool success, bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            success := call(gas(), target, value, result, callData.length, codesize(), 0x00)
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @notice Executes a batch of calls.
    /// @param executions An array of Execution structs each containing target, value, and calldata.
    /// @return result An array of results from each executed call.
    function _executeBatch(Execution[] calldata executions) internal returns (bytes[] memory result) {
        result = new bytes[](executions.length);

        Execution calldata exec;
        for (uint256 i; i < executions.length; i++) {
            exec = executions[i];
            result[i] = _execute(exec.target, exec.value, exec.callData);
        }
    }

    /// @notice Tries to execute a batch of calls and emits an event for each unsuccessful call.
    /// @param executions An array of Execution structs.
    /// @return result An array of results, with unsuccessful calls marked by events.
    function _tryExecuteBatch(Execution[] calldata executions) internal returns (bytes[] memory result) {
        result = new bytes[](executions.length);

        Execution calldata exec;
        for (uint256 i; i < executions.length; i++) {
            exec = executions[i];
            bool success;
            (success, result[i]) = _tryExecute(exec.target, exec.value, exec.callData);
            if (!success) emit TryExecuteUnsuccessful(i, result[i]);
        }
    }
}
