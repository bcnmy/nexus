// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title UserOperation
/// @notice Struct definition for user operations in EntryPoint v0.6
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}
