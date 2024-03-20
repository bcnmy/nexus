// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ModeCode } from "../../lib/ModeLib.sol";

/**
 * @title Execution Interface for Biconomy Smart Accounts
 * @dev Interface for executing transactions on behalf of the smart account,
 * including ERC7579 executions and ERC-4337 user operations as per ERC-4337-v-0.7
 */
interface IAccountExecution {
    event TryExecuteUnsuccessful(uint256 batchExecutionindex, bytes result);

    error ExecutionFailed();

    /**
     * @notice ERC7579 Main Execution flow.
     * Executes a transaction on behalf of the account.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     */
    function execute(ModeCode mode, bytes calldata executionCalldata) external payable;

    /**
     * @notice ERC7579 Execution from Executor flow.
     * Executes a transaction from an Executor Module.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     * @return returnData The return data from the executed call.
     */
    function executeFromExecutor(
        ModeCode mode,
        bytes calldata executionCalldata
    ) external payable returns (bytes[] memory returnData);

    /**
     * @notice Executes a user operation as per ERC-4337.
     * @dev This function is intended to be called by the ERC-4337 EntryPoint contract.
     * @param userOp The packed user operation data.
     * @param userOpHash The hash of the packed user operation.
     */
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable;
}
