// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccountExecution } from "../interfaces/base/IAccountExecution.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ModeCode } from "../lib/ModeLib.sol";

// Review interface may not be needed at all if child account uses full holistic interface
// Note: execution helper internal methods can be added here
abstract contract AccountExecution is IAccountExecution {
    error ExecutionFailed();
    /// @inheritdoc IAccountExecution
    function execute(ModeCode mode, bytes calldata executionCalldata) external payable virtual {
        mode;
        (address target, uint256 value, bytes memory callData) =
            abi.decode(executionCalldata, (address, uint256, bytes));
        target.call{ value: value }(callData);
    }

    /// @inheritdoc IAccountExecution
    function executeFromExecutor(
        ModeCode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        virtual
        returns (bytes[] memory returnData)
    {
        mode;
        (address target, uint256 value, bytes memory callData) =
            abi.decode(executionCalldata, (address, uint256, bytes));
        target.call{ value: value }(callData);
    }

    // Review: could make internal virtual function and call from executeUserOp
    /// @inheritdoc IAccountExecution
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable virtual; 
    // {
    //     userOp;
    //     userOpHash;
    // }
}
