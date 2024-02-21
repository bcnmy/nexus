// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IExecution } from "../interfaces/IExecution.sol";

contract Execution is IExecution {
    /// @inheritdoc IExecution
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable {
        mode;
        executionCalldata;
    }

    /// @inheritdoc IExecution
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

    /// @inheritdoc IExecution
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable {
        userOp;
        userOpHash;
    }
}
