// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { IAccountExecution } from "../interfaces/base/IAccountExecution.sol";

contract AccountExecution is IAccountExecution {
    /// @inheritdoc IAccountExecution
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable {
        mode;
        executionCalldata;
    }

    /// @inheritdoc IAccountExecution
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

    /// @inheritdoc IAccountExecution
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable {
        userOp;
        userOpHash;
    }
}
