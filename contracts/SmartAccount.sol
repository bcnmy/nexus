// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AccountConfig } from "./base/AccountConfig.sol";
import { AccountExecution } from "./base/AccountExecution.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { ERC4337Account } from "./base/ERC4337Account.sol";
import { Execution } from "./interfaces/modules/IExecutor.sol";
import { IValidator, MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, VALIDATION_FAILED } from "./interfaces/modules/IERC7579Modules.sol";
import { IModularSmartAccount, IAccountExecution, IModuleManager, IAccountConfig, IERC4337Account } from "./interfaces/IModularSmartAccount.sol";
import { ModeLib, ModeCode, ExecType, CallType, CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXECTYPE_TRY } from "./lib/ModeLib.sol";
import { ExecLib } from "./lib/ExecLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

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
        // check if validator is enabled. If terminate the validation phase.
        if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        uint256 validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
        return validationData;
    }

    /**
     * Executes a transaction or a batch of transactions with specified execution mode.
     * This function handles both single and batch transactions, supporting default execution and try/catch logic.
     */
    function execute(
        ModeCode mode,
        bytes calldata executionCalldata
    ) external payable override(AccountExecution, IAccountExecution) onlyEntryPointOrSelf {
        (CallType callType, ExecType execType, , ) = mode.decode();

        if (callType == CALLTYPE_BATCH) {
            _handleBatchExecution(executionCalldata, execType);
        } else if (callType == CALLTYPE_SINGLE) {
            _handleSingleExecution(executionCalldata, execType);
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /**
     * @inheritdoc IAccountExecution
     * @dev this function is only callable by an installed executor module
     * @dev this function demonstrates how to implement
     * CallType SINGLE and BATCH and ExecType DEFAULT and TRY
     * @dev this function could implement hook support (modifier)
     */
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
            if (execType == EXECTYPE_DEFAULT) returnData = _executeBatch(executions);
            else if (execType == EXECTYPE_TRY) returnData = _tryExecute(executions);
            else revert UnsupportedExecType(execType);
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
            returnData = new bytes[](1);
            bool success;
            // check if execType is revert(default) or try
            if (execType == EXECTYPE_DEFAULT) {
                returnData[0] = _execute(target, value, callData);
            }
            // TODO: implement event emission for tryExecute singleCall
            else if (execType == EXECTYPE_TRY) {
                (success, returnData[0]) = _tryExecute(target, value, callData);
                if (!success) emit TryExecuteUnsuccessful(0, returnData[0]);
            } else {
                revert UnsupportedExecType(execType);
            }
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /**
     * @inheritdoc IAccountExecution
     */
    function executeUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/
    ) external payable virtual override(AccountExecution, IAccountExecution) onlyEntryPointOrSelf {
        bytes calldata callData = userOp.callData[4:];
        (bool success, ) = address(this).delegatecall(callData);
        if (!success) revert ExecutionFailed();
    }

    /**
     * @inheritdoc IModuleManager
     */
    function installModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata initData
    ) external payable override(IModuleManager, ModuleManager) onlyEntryPointOrSelf {
        if (module == address(0)) revert ModuleAddressCanNotBeZero();
        if (_isModuleInstalled(moduleTypeId, module, initData)) {
            revert ModuleAlreadyInstalled(moduleTypeId, module);
        }
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _installValidator(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _installExecutor(module, initData);
        }
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) _installFallbackHandler(module, initData);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) _installHook(module, initData);
        else {
            revert InvalidModuleTypeId(moduleTypeId);
        }
        emit ModuleInstalled(moduleTypeId, module);
    }

    /**
     * @inheritdoc IModuleManager
     */
    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    ) external payable override(IModuleManager, ModuleManager) onlyEntryPointOrSelf {
        if (!_isModuleInstalled(moduleTypeId, module, deInitData)) {
            revert ModuleNotInstalled(moduleTypeId, module);
        }
        // Note: Should be able to validate passed moduleTypeId agaisnt the provided module address and interface?
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _uninstallValidator(module, deInitData);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _uninstallExecutor(module, deInitData);
        }
        // else if (moduleTypeId == MODULE_TYPE_FALLBACK) _uninstallFallbackHandler(module, deInitData);
        // else if (moduleTypeId == MODULE_TYPE_HOOK) _uninstallHook(module, deInitData);
        else {
            revert UnsupportedModuleType(moduleTypeId);
        }
        emit ModuleUninstalled(moduleTypeId, module);
    }

    /**
     * @inheritdoc IAccountConfig
     */
    function supportsModule(
        uint256 modulTypeId
    ) external view virtual override(AccountConfig, IAccountConfig) returns (bool) {
        if (modulTypeId == MODULE_TYPE_VALIDATOR) return true;
        else if (modulTypeId == MODULE_TYPE_EXECUTOR) return true;
        // else if (modulTypeId == MODULE_TYPE_FALLBACK) return true;
        // else if (modulTypeId == MODULE_TYPE_HOOK) return true;
        else return false;
    }

    /**
     * @inheritdoc IAccountConfig
     */
    function supportsExecutionMode(
        ModeCode mode
    ) external view virtual override(AccountConfig, IAccountConfig) returns (bool isSupported) {
        (CallType callType, ExecType execType, , ) = mode.decode();
        if (callType == CALLTYPE_BATCH) {
            isSupported = true;
        } else if (callType == CALLTYPE_SINGLE) {
            isSupported = true;
        }
        // if callType is not single or batch return false
        // CALLTYPE_DELEGATECALL not supported
        else {
            return false;
        }

        if (execType == EXECTYPE_DEFAULT) {
            isSupported = true;
        } else if (execType == EXECTYPE_TRY) {
            isSupported = true;
        }
        // if execType is not default or try, return false
        else {
            return false;
        }
    }

    /**
     * @inheritdoc IModuleManager
     */
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

    /**
     * @notice Checks if a module is installed on the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param additionalContext Additional context for checking installation.
     * @return True if the module is installed, false otherwise.
     */
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

    function _handleBatchExecution(bytes calldata executionCalldata, ExecType execType) private {
        Execution[] calldata executions = executionCalldata.decodeBatch();
        if (execType == EXECTYPE_DEFAULT) _executeBatch(executions);
        else if (execType == EXECTYPE_TRY) _tryExecute(executions);
        else revert UnsupportedExecType(execType);
    }

    function _handleSingleExecution(bytes calldata executionCalldata, ExecType execType) private {
        (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
        if (execType == EXECTYPE_DEFAULT) _execute(target, value, callData);
        else if (execType == EXECTYPE_TRY) _tryExecute(target, value, callData);
        else revert UnsupportedExecType(execType);
    }

    // TODO
    // isValidSignature
    // by base contract ERC1271 or a method like below..

    // /**
    //  * @dev ERC-1271 isValidSignature
    //  *         This function is intended to be used to validate a smart account signature
    //  * and may forward the call to a validator module
    //  *
    //  * @param hash The hash of the data that is signed
    //  * @param data The data that is signed
    //  */
    // function isValidSignature(
    //     bytes32 hash,
    //     bytes calldata data
    // )
    //     external
    //     view
    //     virtual
    //     override
    //     returns (bytes4)
    // {
    //     address validator = address(bytes20(data[0:20]));
    //     if (!_isValidatorInstalled(validator)) revert InvalidModule(validator);
    //     return IValidator(validator).isValidSignatureWithSender(msg.sender, hash, data[20:]);
    // }
}
