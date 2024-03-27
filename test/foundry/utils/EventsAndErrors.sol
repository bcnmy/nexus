// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventsAndErrors {
    // Define all events
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);
    event AccountCreated(address indexed account, address indexed validationModule, bytes moduleInstallData);



    // Define all errors
    error InvalidModule(address module);
    error FailedOp(uint256 opIndex, string reason);
    error AccountInitializationFailed();
    error AccountAccessUnauthorized();
    error ExecutionFailed();
    error ModuleAlreadyInstalled(uint256 moduleTypeId, address module);
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);
    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();
}
