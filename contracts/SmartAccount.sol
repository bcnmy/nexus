// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AccountConfig } from "./base/AccountConfig.sol";
import { AccountExecution } from "./base/AccountExecution.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { Base4337Account } from "./base/Base4337Account.sol";
import { IValidator } from "./interfaces/modules/IValidator.sol";
import {MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR} from "./interfaces/modules/IERC7579Modules.sol";
import "./lib/ModeLib.sol";

contract SmartAccount is AccountConfig, AccountExecution, ModuleManager, Base4337Account {
    using ModeLib for ModeCode;

    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc Base4337Account
    /// @dev expects IValidator module address to be encoded in the nonce
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        override
        payPrefund(missingAccountFunds)
        returns (uint256)
    {
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

    function executeUserOp(PackedUserOperation calldata userOp, bytes32 /*userOpHash*/)
        external
        payable
        override
        onlyEntryPointOrSelf
    {
        bytes calldata callData = userOp.callData[4:];
        (bool success,) = address(this).delegatecall(callData);
        if (!success) revert ExecutionFailed();
    }

    /*function installModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata initData
    )
        external
        payable
        override
        onlyEntryPointOrSelf
    {
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) _installValidator(module, initData);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) _installExecutor(module, initData);
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) _installFallbackHandler(module, initData);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) _installHook(module, initData);
        else revert UnsupportedModuleType(moduleTypeId);
        emit ModuleInstalled(moduleTypeId, module);
    }

    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    )
        external
        payable
        override
        onlyEntryPointOrSelf
    {
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) _uninstallValidator(module, deInitData);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) _uninstallExecutor(module, deInitData);
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) _uninstallFallbackHandler(module, deInitData);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) _uninstallHook(module, deInitData);
        // else revert UnsupportedModuleType(moduleTypeId);
        emit ModuleUninstalled(moduleTypeId, module);
    }*/

     function supportsModule(uint256 modulTypeId) external view virtual override returns (bool) {
        if (modulTypeId == MODULE_TYPE_VALIDATOR) return true;
        else if (modulTypeId == MODULE_TYPE_EXECUTOR) return true;
        // else if (modulTypeId == MODULE_TYPE_FALLBACK) return true;
        // else if (modulTypeId == MODULE_TYPE_HOOK) return true;
        else return false;
    }
    
    function supportsExecutionMode(ModeCode mode)
        external
        view
        virtual
        override
        returns (bool isSupported)
    {
        (CallType callType, ExecType execType,,) = mode.decode();
        if (callType == CALLTYPE_BATCH) isSupported = true;
        else if (callType == CALLTYPE_SINGLE) isSupported = true;
        // else if (callType == CALLTYPE_DELEGATECALL) isSupported = true;
        // if callType is not single, batch /*or delegatecall*/ return false
        else return false;

        if (execType == EXECTYPE_DEFAULT) isSupported = true;
        // else if (execType == EXECTYPE_TRY) isSupported = true;
        // if execType is not default /*or try,*/ return false
        else return false;
    }

    /*function isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata additionalContext
    )
        external
        view
        override
        returns (bool)
    {
        additionalContext;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) return _isValidatorInstalled(module);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) return _isExecutorInstalled(module);
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) return _isFallbackHandlerInstalled(module);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) return _isHookInstalled(module);
        else return false;
    }*/
}
