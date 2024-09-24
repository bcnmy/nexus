// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Execution } from "../types/DataTypes.sol";

/// @title ExecutionLib
/// @author zeroknots.eth | rhinestone.wtf
/// Helper Library for decoding Execution calldata
/// malloc for memory allocation is bad for gas. use this assembly instead
library ExecLib {
    function decodeBatch(bytes calldata callData) internal pure returns (Execution[] calldata executionBatch) {
        /*
         * Batch Call Calldata Layout
         * Offset (in bytes)    | Length (in bytes) | Contents
         * 0x0                  | 0x4               | bytes4 function selector
         * 0x4                  | -                 |
        abi.encode(IERC7579Execution.Execution[])
         */
        assembly ("memory-safe") {
            let dataPointer := add(callData.offset, calldataload(callData.offset))

            // Extract the ERC7579 Executions
            executionBatch.offset := add(dataPointer, 32)
            executionBatch.length := calldataload(dataPointer)
        }
    }

    function encodeBatch(Execution[] memory executions) internal pure returns (bytes memory callData) {
        callData = abi.encode(executions);
    }

    function decodeSingle(bytes calldata executionCalldata) internal pure returns (address target, uint256 value, bytes calldata callData) {
        target = address(bytes20(executionCalldata[0:20]));
        value = uint256(bytes32(executionCalldata[20:52]));
        callData = executionCalldata[52:];
    }

    function decodeDelegateCall(bytes calldata executionCalldata) internal pure returns (address delegate, bytes calldata callData) {
        // destructure executionCallData according to single exec
        delegate = address(uint160(bytes20(executionCalldata[0:20])));
        callData = executionCalldata[20:];
    }

    function encodeSingle(address target, uint256 value, bytes memory callData) internal pure returns (bytes memory userOpCalldata) {
        userOpCalldata = abi.encodePacked(target, value, callData);
    }

    function get2771CallData() internal returns (bytes memory callData) {
        /// @solidity memory-safe-assembly
        assembly {
            // as per solidity docs
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            callData := allocate(add(calldatasize(), 0x20)) //allocate extra 0x20 to store length 
            mstore(callData, add(calldatasize(), 0x14)) //store length, extra 0x14 is for msg.sender address
            calldatacopy(add(callData, 0x20), 0, calldatasize())

            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            let senderPtr := allocate(0x14)
            mstore(senderPtr, shl(96, caller()))
        }
    }
}
