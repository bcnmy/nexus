// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IAccountExecution } from "../interfaces/base/IAccountExecution.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract AccountExecution is IAccountExecution {
    /// @inheritdoc IAccountExecution
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable {
        mode;

        //@TODO make this via lib
        address target = address(bytes20(executionCalldata[0:20]));
        uint256 value = uint256(bytes32(executionCalldata[20:52]));
        bytes calldata callData = executionCalldata[52:];
        _execute(target, value, callData);
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

    function _execute(
        /// @TODO : move to helper contract
        address target,
        uint256 value,
        bytes calldata callData
    )
        internal
        virtual
        returns (bytes memory result)
    {
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
}
