// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IExecution } from "../interfaces/IExecution.sol";

contract Execution is IExecution {
    /**
     * @notice Executes a transaction on behalf of the account.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     */
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable {
        mode;
        executionCalldata;
    }

    /**
     * @notice Executes a transaction on behalf of the account via an Executor Module.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     * @return returnData The return data from the executed call.
     */
    function executeFromExecutor(
        bytes32 mode,
        bytes calldata executionCalldata
    )
        external
        payable
        returns (bytes[] memory returnData)
    {
        mode;
        executionCalldata;
        returnData = new bytes[](0);
        return returnData;
    }

    /**
     * @notice Executes a user operation as per ERC-4337.
     * @dev This function is intended to be called by the ERC-4337 EntryPoint contract.
     * @param userOp The packed user operation data.
     * @param userOpHash The hash of the packed user operation.
     */
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable {
        userOp;
        userOpHash;
    }
}
