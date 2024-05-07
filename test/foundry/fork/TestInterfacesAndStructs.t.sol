// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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

interface IProxyV2 {
    function updateImplementation(address _implementation) external;
}

interface IEntryPointV_0_6 {
    function handleOps(UserOperation[] calldata ops, address sender) external payable;
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);
}