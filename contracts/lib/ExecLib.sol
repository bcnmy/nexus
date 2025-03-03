// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Execution } from "../types/DataTypes.sol";

/// @title ExecutionLib
/// @author zeroknots.eth | rhinestone.wtf
/// Helper Library for decoding Execution calldata
/// malloc for memory allocation is bad for gas. use this assembly instead
library ExecLib {
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
}
