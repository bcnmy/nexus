// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccountExecution } from "../interfaces/base/IAccountExecution.sol";
import { Execution } from "../interfaces/modules/IExecutor.sol";
import "../lib/ModeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/**
 * @title AccountExecution
 * @dev This contract executes calls in the context of this contract.
 * @author zeroknots.eth | rhinestone.wtf
 * shoutout to solady (vectorized, ross) for this code
 * https://github.com/Vectorized/solady/blob/main/src/accounts/ERC4337.sol
 */
abstract contract AccountExecution is IAccountExecution {
    using ModeLib for ModeCode;

    /// @inheritdoc IAccountExecution
    function execute(ModeCode mode, bytes calldata executionCalldata) external payable virtual;

    /// @inheritdoc IAccountExecution
    function executeFromExecutor(
        ModeCode mode,
        bytes calldata executionCalldata
    ) external payable virtual returns (bytes[] memory returnData);

    /// @inheritdoc IAccountExecution
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable virtual;

    // /////////////////////////////////////////////////////
    // //  Execution Helpers
    // ////////////////////////////////////////////////////

    function _executeBatch(Execution[] calldata executions) internal returns (bytes[] memory result) {
        uint256 length = executions.length;
        result = new bytes[](length);

        for (uint256 i; i < length; i++) {
            Execution calldata exec = executions[i];
            result[i] = _execute(exec.target, exec.value, exec.callData);
        }
    }

    function _tryExecute(Execution[] calldata executions) internal returns (bytes[] memory result) {
        uint256 length = executions.length;
        result = new bytes[](length);

        for (uint256 i; i < length; i++) {
            Execution calldata exec = executions[i];
            bool success;
            (success, result[i]) = _tryExecute(exec.target, exec.value, exec.callData);
            if (!success) emit TryExecuteUnsuccessful(i, result[i]);
        }
    }

    function _execute(
        address target,
        uint256 value,
        bytes calldata callData
    ) internal virtual returns (bytes memory result) {
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

    function _tryExecute(
        address target,
        uint256 value,
        bytes calldata callData
    ) internal virtual returns (bool success, bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            success := iszero(call(gas(), target, value, result, callData.length, codesize(), 0x00))
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Execute a delegatecall with `delegate` on this account.
    function _executeDelegatecall(address delegate, bytes calldata callData) internal returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            // Forwards the `data` to `delegate` via delegatecall.
            if iszero(delegatecall(gas(), delegate, result, callData.length, codesize(), 0x00)) {
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

    /// @dev Execute a delegatecall with `delegate` on this account and catch reverts.
    function _tryExecuteDelegatecall(
        address delegate,
        bytes calldata callData
    ) internal returns (bool success, bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            // Forwards the `data` to `delegate` via delegatecall.
            success := iszero(delegatecall(gas(), delegate, result, callData.length, codesize(), 0x00))
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }
}
