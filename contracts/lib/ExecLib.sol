// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Execution } from "../types/DataTypes.sol";
import { EfficientHashLib } from "solady/utils/EfficientHashLib.sol";

/// @title ExecutionLib
/// @author zeroknots.eth | rhinestone.wtf
/// Helper Library for decoding Execution calldata
/// malloc for memory allocation is bad for gas. use this assembly instead
library ExecLib {

    //keccak256("Execution(address target,uint256 value,bytes callData)");
    bytes32 constant EXECUTION_TYPEHASH = 0x37fb04e5593580b36bfacc47d8b1a4b9a2acb88a513bf153760f925a6723d4b5;
    //keccak256("ExecutionBatch(Execution[] executions)");
    bytes32 constant EXECUTION_BATCH_TYPEHASH = 0x4e8377fd5d52d3a9722198c2631a72d411a112149d2d0974cb3f81a6d2bc013f;

    using ExecLib for Execution;
    using EfficientHashLib for *;

    function get2771CallData(bytes calldata cd) internal view returns (bytes memory callData) {
        /// @solidity memory-safe-assembly
        (cd);
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

    /** 
     *   @notice Divide execution calldata into execution data and op data
     *   @param executionCalldata The calldata to divide
     *   @return executionData The execution data => array of Execution structs
     *   @return opData The op data
     */
    function cutOpData(bytes calldata executionCalldata) internal pure returns (bytes calldata executionData, bytes calldata opData) {
        assembly {
            let u := calldataload(add(executionCalldata.offset, 0x20))
            // executionData: if we cut it likes this, it will still contain \
            // the offset of opData at 0x20, but it does no harm
            executionData.offset := executionCalldata.offset
            executionData.length := u
            // opData 
            let s := add(executionCalldata.offset, u)
            opData.offset := add(s, 0x20)
            opData.length := calldataload(s)
        }
    }

    /**
     * @notice Decode a batch of `Execution` executionBatch from a `bytes` calldata.
     * @dev code is copied from solady's LibERC7579.sol
     * https://github.com/Vectorized/solady/blob/740812cedc9a1fc11e17cb3d4569744367dedf19/src/accounts/LibERC7579.sol#L146
     *      Credits to Vectorized and the Solady Team
     */
    function decodeBatch(bytes calldata executionCalldata) internal pure returns (Execution[] calldata executionBatch) {
        /// @solidity memory-safe-assembly
        assembly {
            let u := calldataload(executionCalldata.offset)
            let s := add(executionCalldata.offset, u)
            let e := sub(add(executionCalldata.offset, executionCalldata.length), 0x20)
            executionBatch.offset := add(s, 0x20)
            executionBatch.length := calldataload(s)
            if or(shr(64, u), gt(add(s, shl(5, executionBatch.length)), e)) {
                mstore(0x00, 0xba597e7e) // `DecodingError()`.
                revert(0x1c, 0x04)
            }
            if executionBatch.length {
                // Perform bounds checks on the decoded `executionBatch`.
                // Loop runs out-of-gas if `executionBatch.length` is big enough to cause overflows.
                for { let i := executionBatch.length } 1 { } {
                    i := sub(i, 1)
                    let p := calldataload(add(executionBatch.offset, shl(5, i)))
                    let c := add(executionBatch.offset, p)
                    let q := calldataload(add(c, 0x40))
                    let o := add(c, q)
                    // forgefmt: disable-next-item
                    if or(shr(64, or(calldataload(o), or(p, q))),
                        or(gt(add(c, 0x40), e), gt(add(o, calldataload(o)), e))) {
                        mstore(0x00, 0xba597e7e) // `DecodingError()`.
                        revert(0x1c, 0x04)
                    }
                    if iszero(i) { break }
                }
            }
        }
    }

    function encodeBatch(Execution[] memory executions) internal pure returns (bytes memory callData) {
        callData = abi.encode(executions);
    }

    function encodeBatchWithOpData(Execution[] memory executions, bytes calldata opData) internal pure returns (bytes memory callData) {
        callData = abi.encode(executions, opData);
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

    function hashExecutionBatch(Execution[] memory executions) internal pure returns (bytes32) {
        uint256 length = executions.length;
        
        bytes32[] memory a = EfficientHashLib.malloc(length);
        for (uint256 i; i < length; i++) {
            a.set(i, executions[i].hashExecution());
        }
        
        return keccak256(
            abi.encode(
                EXECUTION_BATCH_TYPEHASH,
                a.hash()
            )
        );
    }

    function hashExecution(Execution memory execution) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EXECUTION_TYPEHASH,
                execution.target,
                execution.value,
                keccak256(execution.callData)
            )
        );
    }
}
