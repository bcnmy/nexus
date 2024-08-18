// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CallType, ExecType } from "../../../contracts/lib/ModeLib.sol";

contract EventsAndErrors {
    // ==========================
    // Events
    // ==========================
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);
    event GenericFallbackCalled(address sender, uint256 value, bytes data);
    event Deposited(address indexed account, uint256 totalDeposit);
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);
    event PreCheckCalled();
    event PostCheckCalled();
    event TryExecuteUnsuccessful(bytes callData, bytes result);
    event TryDelegateCallUnsuccessful(uint256 batchExecutionindex, bytes result);

    // ==========================
    // General Errors
    // ==========================
    error MissingFallbackHandler(bytes4 sig);
    error FallbackCallTypeInvalid();
    error InvalidImplementationAddress();
    error AccountInitializationFailed();
    error AccountAccessUnauthorized();
    error EntryPointCanNotBeZero();
    error ExecutionFailed();
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);
    error UnauthorizedOperation(address operator);
    error UnsupportedModuleType(uint256 moduleTypeId);
    error UnsupportedCallType(CallType callType);
    error UnsupportedExecType(ExecType execType);
    error ImplementationAddressCanNotBeZero();
    error ModuleNotWhitelisted(address module);
    error ZeroAddressNotAllowed();
    error FactoryNotWhitelisted();
    error InvalidFactoryAddress();
    error InvalidEntryPointAddress();
    error InnerCallFailed();
    error CallToDeployWithFactoryFailed();
    error NexusInitializationFailed();

    // ==========================
    // Operation Errors
    // ==========================
    error FailedOp(uint256 opIndex, string reason);
    error FailedOpWithRevert(uint256 opIndex, string reason, bytes inner);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC1271InvalidSigner(address signer);
    error InvalidSignature();

    // ==========================
    // Linked List Errors
    // ==========================
    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();

    // ==========================
    // Module Errors
    // ==========================
    error CannotRemoveLastValidator();
    error InvalidModule(address module);
    error InvalidModuleTypeId(uint256 moduleTypeId);
    error ModuleAlreadyInstalled(uint256 moduleTypeId, address module);
    error ModuleNotInstalled(uint256 moduleTypeId, address module);
    error ModuleAddressCanNotBeZero();
    error EnableModeSigError();

    // ==========================
    // Hook Errors
    // ==========================
    error HookPostCheckFailed();
    error HookAlreadyInstalled(address currentHook);

    // ==========================
    // Fallback Errors
    // ==========================
    error FallbackAlreadyInstalledForSelector(bytes4 selector);

    // ==========================
    // Ownable Errors
    // ==========================
    error Unauthorized();
}
