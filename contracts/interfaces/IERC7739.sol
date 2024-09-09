// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC7739 {
    function supportsNestedTypedDataSign() external view returns (bytes32);
}
