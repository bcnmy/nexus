// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Entrypoint v0.6 UserOperation struct
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

interface IBiconomySmartAccountV2 {
    function updateImplementation(address _implementation) external;
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
    function entryPoint() external view returns (address);
}

interface IEntryPointV_0_6 {
    function handleOps(UserOperation[] calldata ops, address sender) external payable;
    function depositTo(address account) external payable;
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);
    function getNonce(address sender, uint192 key) external view returns (uint256 nonce);
}
