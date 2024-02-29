// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccountExecution } from "../interfaces/base/IAccountExecution.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

// TODO
// Review this could be an abtract contract
contract AccountExecution is IAccountExecution {
    /// @inheritdoc IAccountExecution
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable virtual {
        mode;
        (address target, uint256 value, bytes memory callData) =
            abi.decode(executionCalldata, (address, uint256, bytes));
        target.call{ value: value }(callData);
    }

    /// @inheritdoc IAccountExecution
    function executeFromExecutor(
        bytes32 mode,
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

    /// @inheritdoc IAccountExecution
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable virtual {
        userOp;
        userOpHash;
    }
}
