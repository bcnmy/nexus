// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AccountConfig } from "./base/AccountConfig.sol";
import { AccountExecution } from "./base/AccountExecution.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ERC4337Account } from "./base/ERC4337Account.sol";
import { Execution } from "./interfaces/modules/IExecutor.sol";
import { IValidator, IExecutor, MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR } from "./interfaces/modules/IERC7579Modules.sol";
import { IModularSmartAccount, IAccountExecution, IModuleManager, IAccountConfig, IERC4337Account } from "./interfaces/IModularSmartAccount.sol";
import { ModeLib, ModeCode, ExecType, CallType, CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT } from "./lib/ModeLib.sol";
import { ExecLib } from "./lib/ExecLib.sol";

import { SentinelListLib } from "sentinellist/src/SentinelList.sol";
contract SmartAccount is AccountConfig, AccountExecution, ModuleManager, ERC4337Account, IModularSmartAccount {
    using ModeLib for ModeCode;
    using ExecLib for bytes;

    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc ERC4337Account
    /// @dev expects IValidator module address to be encoded in the nonce
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override(ERC4337Account, IERC4337Account) payPrefund(missingAccountFunds) returns (uint256) {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }
        // TODO
        // check if validator is enabled. If terminate the validation phase.
        //if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        uint256 validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
        return validationData;
    }

    // TODO // Add execute_try and calltype delegatecall
    function execute(
        ModeCode mode,
        bytes calldata executionCalldata
    ) external payable override(AccountExecution, IAccountExecution) onlyEntryPointOrSelf {
        (CallType callType, ExecType execType, , ) = mode.decode();

        // check if calltype is batch or single
        if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = executionCalldata.decodeBatch();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT)
                _executeBatch(executions);
                // else if (execType == EXECTYPE_TRY) _tryExecute(executions);
            else revert UnsupportedExecType(execType);
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT)
                _execute(target, value, callData);
                // TODO: implement event emission for tryExecute singleCall
                // else if (execType == EXECTYPE_TRY) _tryExecute(target, value, callData);
            else revert UnsupportedExecType(execType);
        } else {
            revert UnsupportedCallType(callType);
        }

    }

    function executeFromExecutor(
        ModeCode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        override(AccountExecution, IAccountExecution)
        onlyExecutorModule
        returns (
            bytes[] memory returnData // TODO returnData is not used
        )
    {
        (CallType callType, ExecType execType, , ) = mode.decode();

        // check if calltype is batch or single
        if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = executionCalldata.decodeBatch();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT)
                returnData = _executeBatch(executions);
                // else if (execType == EXECTYPE_TRY) returnData = _tryExecute(executions);
            else revert UnsupportedExecType(execType);
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
            returnData = new bytes[](1);
            // bool success;
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) {
                returnData[0] = _execute(target, value, callData);
            }
            // TODO: implement event emission for tryExecute singleCall
            /*else if (execType == EXECTYPE_TRY) {
                (success, returnData[0]) = _tryExecute(target, value, callData);
                if (!success) emit TryExecuteUnsuccessful(0, returnData[0]);
            }*/
            else {
                revert UnsupportedExecType(execType);
            }
        }
        /*else if (callType == CALLTYPE_DELEGATECALL) {
            // destructure executionCallData according to single exec
            address delegate = address(uint160(bytes20(executionCalldata[0:20])));
            bytes calldata callData = executionCalldata[20:];
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) _executeDelegatecall(delegate, callData);
            else if (execType == EXECTYPE_TRY) _tryExecuteDelegatecall(delegate, callData);
            else revert UnsupportedExecType(execType);
        }*/
        else {
            revert UnsupportedCallType(callType);
        }
    }

    function executeUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/
    ) external payable override(AccountExecution, IAccountExecution) onlyEntryPointOrSelf {
        bytes calldata callData = userOp.callData[4:];
        (bool success, ) = address(this).delegatecall(callData);
        if (!success) revert ExecutionFailed();
    }

    function installModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata initData
    ) external payable override(IModuleManager, ModuleManager) onlyEntryPointOrSelf {
        SentinelListLib.SentinelList storage moduleList;

        if(_isModuleInstalled(moduleTypeId, module, initData)) {
                revert ModuleAlreadyInstalled(moduleTypeId, module);
        }

        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _installValidator(module, initData);
        }
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _installExecutor(module, initData);
        }
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) _installFallbackHandler(module, initData);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) _installHook(module, initData);
        else {
            revert InvalidModuleTypeId(moduleTypeId);
        }
        
        emit ModuleInstalled(moduleTypeId, module);
    }

    // Review
    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    ) external payable override(IModuleManager, ModuleManager) onlyEntryPointOrSelf {
        SentinelListLib.SentinelList storage moduleList;

        if(!_isModuleInstalled(moduleTypeId, module, deInitData)) {
                revert ModuleNotInstalled(moduleTypeId, module);
        }
        // Note: Review should be able to validate passed moduleTypeId agaisnt the provided module address and interface?
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) _uninstallValidator(module, deInitData);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) _uninstallExecutor(module, deInitData);
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) _uninstallFallbackHandler(module, deInitData);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) _uninstallHook(module, deInitData);
        else revert UnsupportedModuleType(moduleTypeId);
        emit ModuleUninstalled(moduleTypeId, module);
    }

    function supportsModule(
        uint256 modulTypeId
    ) external view virtual override(AccountConfig, IAccountConfig) returns (bool) {
        if (modulTypeId == MODULE_TYPE_VALIDATOR) return true;
        else if (modulTypeId == MODULE_TYPE_EXECUTOR) return true;
        // else if (modulTypeId == MODULE_TYPE_FALLBACK) return true;
        // else if (modulTypeId == MODULE_TYPE_HOOK) return true;
        else return false;
    }

    function supportsExecutionMode(
        ModeCode mode
    ) external view virtual override(AccountConfig, IAccountConfig) returns (bool isSupported) {
        (CallType callType, ExecType execType, , ) = mode.decode();
        if (callType == CALLTYPE_BATCH) isSupported = true;
        else if (callType == CALLTYPE_SINGLE) {
            isSupported = true;
        }
        // else if (callType == CALLTYPE_DELEGATECALL) isSupported = true;
        // if callType is not single, batch /*or delegatecall*/ return false
        else {
            return false;
        }

        if (execType == EXECTYPE_DEFAULT) {
            isSupported = true;
        }
        // else if (execType == EXECTYPE_TRY) isSupported = true;
        // if execType is not default /*or try,*/ return false
        else {
            return false;
        }
    }

    function isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata additionalContext
    ) external view override(IModuleManager, ModuleManager) returns (bool) {
        return _isModuleInstalled(moduleTypeId, module, additionalContext);
    }

    // TODO // Review for initialize modifiers
    // Review natspec
    /**
     * @dev Initializes the account. Function might be called directly, or by a Factory
     * @param initData. encoded data that can be used during the initialization phase
     */
    function initialize(address firstValidator, bytes calldata initData) public payable virtual {
        // checks if already initialized and reverts before setting the state to initialized
        _initModuleManager();
        _installValidator(firstValidator, initData);
    }

    // TODO
    // Add means to upgrade

    function _isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata additionalContext
    ) private view returns (bool) {
        additionalContext;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) return _isValidatorInstalled(module);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) return _isExecutorInstalled(module);
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) return _isFallbackHandlerInstalled(module);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) return _isHookInstalled(module);
        else return false;
    }

}
