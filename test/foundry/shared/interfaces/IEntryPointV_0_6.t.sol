// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { UserOperation } from "./UserOperation.t.sol";

/// @title IEntryPointV_0_6
/// @notice Interface for the EntryPoint contract version 0.6
interface IEntryPointV_0_6 {
    function handleOps(UserOperation[] calldata ops, address sender) external payable;
    function depositTo(address account) external payable;
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);
    function getNonce(address sender, uint192 key) external view returns (uint256 nonce);
}
