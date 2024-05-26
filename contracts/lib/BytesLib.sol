// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library BytesLib {
    function slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        require(data.length >= start + length, "BytesLib: Slice out of range");
        bytes memory result = new bytes(length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }

        return result;
    }
}
