// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title BytesLib
/// @notice A library for handling bytes data operations
library BytesLib {
    /// @notice Slices a bytes array from a given start index with a specified length
    /// @param data The bytes array to slice
    /// @param start The starting index to slice from
    /// @param length The length of the slice
    /// @return The sliced bytes array
    function slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        require(data.length >= start + length, "BytesLib: Slice out of range");

        // Initialize a new bytes array with the specified length
        bytes memory result = new bytes(length);

        // Copy the data from the original array to the result array
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }

        return result;
    }
}
