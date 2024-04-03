// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventsAndErrors {
    // Define all events
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);
    event UserOperationRevertReason(
        bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason
    );
    event AccountCreated(address indexed account, address indexed validationModule, bytes moduleInstallData);
    event FallbackHandlerTriggered();

    event PreCheckCalled();
    event PostCheckCalled();


    // Define all errors
    error FailedOp(uint256 opIndex, string reason);
    error AccountInitializationFailed();
    error AccountAccessUnauthorized();
    error ExecutionFailed();
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);
    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    error CannotRemoveLastValidator();
    error InvalidModule(address module);
    error InvalidModuleTypeId(uint256 moduleTypeId);
    error ModuleAlreadyInstalled(uint256 moduleTypeId, address module);
    error UnauthorizedOperation(address operator);
    error ModuleNotInstalled(uint256 moduleTypeId, address module);
    error IncompatibleValidatorModule(address module);
    error IncompatibleExecutorModule(address module);
    error ModuleAddressCanNotBeZero();
    error HookPostCheckFailed();
    error HookAlreadyInstalled(address currentHook);
    error FallbackHandlerAlreadyInstalled();


    event TryExecuteUnsuccessful(uint256 batchExecutionindex, bytes result);

}
