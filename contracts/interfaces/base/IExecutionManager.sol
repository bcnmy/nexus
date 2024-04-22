// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ExecutionMode } from "../../lib/ModeLib.sol";

/**
 * @title IExecutionManager
 * @dev Execution Interface for Biconomy Smart Accounts
 * @dev Interface for executing transactions on behalf of the smart account,
 */
interface IExecutionManager {
    /**
     * @notice ERC7579 Main Execution flow.
     * Executes a transaction on behalf of the account.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     */
    function execute(ExecutionMode mode, bytes calldata executionCalldata) external payable;

    /**
     * @notice ERC7579 Execution from Executor flow.
     * Executes a transaction from an Executor Module.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     * @return returnData The return data from the executed call.
     */
    function executeFromExecutor(
        ExecutionMode mode,
        bytes calldata executionCalldata
    ) external payable returns (bytes[] memory returnData);
}
