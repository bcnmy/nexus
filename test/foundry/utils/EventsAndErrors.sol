// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventsAndErrors {
    // Define all events
    event AccountCreated(address indexed account, address indexed validationModule, bytes moduleInstallData);
    event GenericFallbackCalled(address sender, uint256 value, bytes data);
event Deposited(address indexed account, uint256 totalDeposit);


event ModuleInstalled(uint256 moduleTypeId, address module);
event ModuleUninstalled(uint256 moduleTypeId, address module);
event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

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
    error ModuleAddressCanNotBeZero();
    error HookPostCheckFailed();
    error HookAlreadyInstalled(address currentHook);
    error FallbackAlreadyInstalledForSelector(bytes4 selector);
    error InvalidSignature();

    event TryExecuteUnsuccessful(uint256 batchExecutionindex, bytes result);

    error ERC1271InvalidSigner(address signer);
}
