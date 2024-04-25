// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337,
// using Entrypoint version 0.7.0, developed by Biconomy. Learn more at https://biconomy.io/

import { UUPSUpgradeable } from "solady/src/utils/UUPSUpgradeable.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

import { ExecLib } from "./lib/ExecLib.sol";
import { Execution } from "./types/DataTypes.sol";
import { INexus } from "./interfaces/INexus.sol";
import { BaseAccount } from "./base/BaseAccount.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { ExecutionManager } from "./base/ExecutionManager.sol";
import { IValidator } from "./interfaces/modules/IValidator.sol";
import { MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, MODULE_TYPE_FALLBACK, MODULE_TYPE_HOOK, VALIDATION_FAILED } from "./types/Constants.sol";
import { ModeLib, ExecutionMode, ExecType, CallType, CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXECTYPE_TRY } from "./lib/ModeLib.sol";

/// @title Nexus - Smart Account
/// @notice This contract integrates various functionalities to handle modular smart accounts compliant with ERC-7579 and ERC-4337 standards.
/// @dev Comprehensive suite of methods for managing smart accounts, integrating module management, execution management, and upgradability via UUPS.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract Nexus is INexus, BaseAccount, ExecutionManager, ModuleManager, UUPSUpgradeable {
    using ModeLib for ExecutionMode;
    using ExecLib for bytes;

    /// @notice Initializes the smart account by setting up the module manager and state.
    constructor() {
        _initModuleManager();
    }

    /// Validates a user operation against a specified validator, extracted from the operation's nonce.
    /// The entryPoint calls this only if validation succeeds. Fails by returning `VALIDATION_FAILED` for invalid signatures.
    /// Other validation failures (e.g., nonce mismatch) should revert.
    /// @param userOp The operation to validate, encapsulating all transaction details.
    /// @param userOpHash Hash of the operation data, used for signature validation.
    /// @param missingAccountFunds Funds missing from the account's deposit necessary for transaction execution.
    /// This can be zero if covered by a paymaster or sufficient deposit exists.
    /// @return validationData Encoded validation result or failure, propagated from the validator module.
    /// - Encoded format in validationData:
    ///     - First 20 bytes: Validator address, 0x0 for valid or specific failure modes.
    ///     - `SIG_VALIDATION_FAILED` (1) denotes signature validation failure allowing simulation calls without a valid signature.
    /// @dev Expects the validator's address to be encoded in the upper 96 bits of the userOp's nonce.
    /// This method forwards the validation task to the extracted validator module address.
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual payPrefund(missingAccountFunds) onlyEntryPoint returns (uint256) {
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

    /// @notice Executes transactions in single or batch modes as specified by the execution mode.
    /// @param mode The execution mode detailing how transactions should be handled (single, batch, default, try/catch).
    /// @param executionCalldata The encoded transaction data to execute.
    /// @dev This function handles transaction execution flexibility and is protected by the `onlyEntryPointOrSelf` modifier.
    function execute(ExecutionMode mode, bytes calldata executionCalldata) external payable onlyEntryPointOrSelf {
        (address hook, bytes memory hookData) = _preCheck();
        (CallType callType, ExecType execType, , ) = mode.decode();
        if (callType == CALLTYPE_SINGLE) {
            _handleSingleExecution(executionCalldata, execType);
        } else if (callType == CALLTYPE_BATCH) {
            _handleBatchExecution(executionCalldata, execType);
        } else {
            revert UnsupportedCallType(callType);
        }
        _postCheck(hook, hookData, true, new bytes(0));
    }

    /// @notice Executes transactions from an executor module, supporting both single and batch transactions.
    /// @param mode The execution mode (single or batch, default or try).
    /// @param executionCalldata The transaction data to execute.
    /// @return returnData The results of the transaction executions, which may include errors in try mode.
    /// @dev This function is callable only by an executor module and may implement hooks.
    function executeFromExecutor(
        ExecutionMode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        onlyExecutorModule
        returns (
            bytes[] memory returnData // TODO returnData is not used
        )
    {
        (address hook, bytes memory hookData) = _preCheck();
        (CallType callType, ExecType execType, , ) = mode.decode();

        // check if calltype is batch or single
        if (callType == CALLTYPE_SINGLE) {
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
        } else if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = executionCalldata.decodeBatch();
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) returnData = _executeBatch(executions);
            else if (execType == EXECTYPE_TRY) returnData = _tryExecuteBatch(executions);
            else revert UnsupportedExecType(execType);
        } else {
            revert UnsupportedCallType(callType);
        }
        _postCheck(hook, hookData, true, new bytes(0));
    }
    /// @notice Executes a user operation via delegatecall to use the contract's context.
    /// @param userOp The user operation to execute.
    /// @dev This function should only be called through the EntryPoint to ensure security and proper execution context.
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 /*userOpHash*/) external payable virtual onlyEntryPoint {
        bytes calldata callData = userOp.callData[4:];
        (bool success, ) = address(this).delegatecall(callData);
        if (!success) revert ExecutionFailed();
    }

    /// @notice Installs a new module to the smart account.
    /// @param moduleTypeId The type identifier of the module being installed, which determines its role:
    /// - 1 for Validator
    /// - 2 for Executor
    /// - 3 for Fallback
    /// - 4 for Hook
    /// @param module The address of the module to install.
    /// @param initData Initialization data for the module.
    /// @dev This function can only be called by the EntryPoint or the account itself for security reasons.
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable onlyEntryPointOrSelf {
        (address hook, bytes memory hookData) = _preCheck();
        if (module == address(0)) revert ModuleAddressCanNotBeZero();
        if (_isModuleInstalled(moduleTypeId, module, initData)) {
            revert ModuleAlreadyInstalled(moduleTypeId, module);
        }
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _installValidator(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _installExecutor(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_FALLBACK) {
            _installFallbackHandler(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_HOOK) {
            _installHook(module, initData);
        } else {
            revert InvalidModuleTypeId(moduleTypeId);
        }
        emit ModuleInstalled(moduleTypeId, module);
        _postCheck(hook, hookData, true, new bytes(0));
    }

    /// @notice Uninstalls a module from the smart account.
    /// @param moduleTypeId The type ID of the module to be uninstalled, matching the installation type:
    /// - 1 for Validator
    /// - 2 for Executor
    /// - 3 for Fallback
    /// - 4 for Hook
    /// @param module The address of the module to uninstall.
    /// @param deInitData De-initialization data for the module.
    /// @dev Ensures that the operation is authorized and valid before proceeding with the uninstallation.
    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable onlyEntryPointOrSelf {
        if (!_isModuleInstalled(moduleTypeId, module, deInitData)) {
            revert ModuleNotInstalled(moduleTypeId, module);
        }
        // Note: Should be able to validate passed moduleTypeId agaisnt the provided module address and interface?
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) _uninstallValidator(module, deInitData);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) _uninstallExecutor(module, deInitData);
        else if (moduleTypeId == MODULE_TYPE_FALLBACK) _uninstallFallbackHandler(module, deInitData);
        else if (moduleTypeId == MODULE_TYPE_HOOK) _uninstallHook(module, deInitData);
        else revert UnsupportedModuleType(moduleTypeId);
        emit ModuleUninstalled(moduleTypeId, module);
    }

    /// @notice Initializes the smart account with a validator.
    /// @param firstValidator The first validator to install upon initialization.
    /// @param initData Initialization data for setting up the validator.
    /// @dev This function sets the foundation for the smart account's operational logic and security.
    function initialize(address firstValidator, bytes calldata initData) external payable virtual {
        // checks if already initialized and reverts before setting the state to initialized
        _initModuleManager();
        _installValidator(firstValidator, initData);
    }

    /// @notice Validates a signature according to ERC-1271 standards.
    /// @param hash The hash of the data being validated.
    /// @param data Signature data that needs to be validated.
    /// @return The status code of the signature validation (`0x1626ba7e` if valid).
    /// bytes4(keccak256("isValidSignature(bytes32,bytes)") = 0x1626ba7e
    /// @dev Delegates the validation to a validator module specified within the signature data.
    function isValidSignature(bytes32 hash, bytes calldata data) external view virtual override returns (bytes4) {
        address validator = address(bytes20(data[0:20]));
        if (!_isValidatorInstalled(validator)) revert InvalidModule(validator);
        return IValidator(validator).isValidSignatureWithSender(msg.sender, hash, data[20:]);
    }

    /// @notice Retrieves the address of the current implementation from the EIP-1967 slot.
    /// @return implementation The address of the current contract implementation.
    function getImplementation() external view returns (address implementation) {
        assembly {
            implementation := sload(_ERC1967_IMPLEMENTATION_SLOT)
        }
    }

    /// @notice Checks if a specific module type is supported by this smart account.
    /// @param moduleTypeId The identifier of the module type to check.
    /// @return True if the module type is supported, false otherwise.
    function supportsModule(uint256 moduleTypeId) external view virtual returns (bool) {
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) return true;
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) return true;
        else if (moduleTypeId == MODULE_TYPE_FALLBACK) return true;
        else if (moduleTypeId == MODULE_TYPE_HOOK) return true;
        else return false;
    }

    /// @notice Determines if a specific execution mode is supported.
    /// @param mode The execution mode to evaluate.
    /// @return isSupported True if the execution mode is supported, false otherwise.
    function supportsExecutionMode(ExecutionMode mode) external view virtual returns (bool isSupported) {
        (CallType callType, ExecType execType, , ) = mode.decode();

        // Define supported call types.
        bool isSupportedCallType = callType == CALLTYPE_BATCH || callType == CALLTYPE_SINGLE;
        // Define supported execution types.
        bool isSupportedExecType = execType == EXECTYPE_DEFAULT || execType == EXECTYPE_TRY;

        // Return true if both the call type and execution type are supported.
        return isSupportedCallType && isSupportedExecType;
    }

    /// @notice Determines whether a module is installed on the smart account.
    /// @param moduleTypeId The ID corresponding to the type of module (Validator, Executor, Fallback, Hook).
    /// @param module The address of the module to check.
    /// @param additionalContext Optional context that may be needed for certain checks.
    /// @return True if the module is installed, false otherwise.
    function isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) external view returns (bool) {
        return _isModuleInstalled(moduleTypeId, module, additionalContext);
    }

    /// Returns the account's implementation ID.
    /// @return The unique identifier for this account implementation.
    function accountId() external pure virtual returns (string memory) {
        return _ACCOUNT_IMPLEMENTATION_ID;
    }

    /// Upgrades the contract to a new implementation and calls a function on the new contract.
    /// @param newImplementation The address of the new contract implementation.
    /// @param data The calldata to be sent to the new implementation.
    function upgradeToAndCall(address newImplementation, bytes calldata data) public payable virtual override {
        UUPSUpgradeable.upgradeToAndCall(newImplementation, data);
    }

    /// @dev Ensures that only authorized callers can upgrade the smart contract implementation.
    /// This is part of the UUPS (Universal Upgradeable Proxy Standard) pattern.
    /// @param newImplementation The address of the new implementation to upgrade to.
    function _authorizeUpgrade(address newImplementation) internal virtual override(UUPSUpgradeable) onlyEntryPointOrSelf {
        newImplementation;
    }

    /// @dev Executes a single transaction based on the specified execution type.
    /// @param executionCalldata The calldata containing the transaction details (target address, value, and data).
    /// @param execType The execution type, which can be DEFAULT (revert on failure) or TRY (return on failure).
    function _handleSingleExecution(bytes calldata executionCalldata, ExecType execType) private {
        (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
        if (execType == EXECTYPE_DEFAULT) _execute(target, value, callData);
        else if (execType == EXECTYPE_TRY) _tryExecute(target, value, callData);
        else revert UnsupportedExecType(execType);
    }

    /// @dev Executes a batch of transactions based on the specified execution type.
    /// @param executionCalldata The calldata for a batch of transactions.
    /// @param execType The execution type, which can be DEFAULT (revert on failure) or TRY (return on failure).
    function _handleBatchExecution(bytes calldata executionCalldata, ExecType execType) private {
        Execution[] calldata executions = executionCalldata.decodeBatch();
        if (execType == EXECTYPE_DEFAULT) _executeBatch(executions);
        else if (execType == EXECTYPE_TRY) _tryExecuteBatch(executions);
        else revert UnsupportedExecType(execType);
    }

    /// @notice Checks if a module is installed on the smart account.
    /// @param moduleTypeId The module type ID.
    /// @param module The module address.
    /// @param additionalContext Additional context for checking installation.
    /// @return True if the module is installed, false otherwise.
    function _isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) private view returns (bool) {
        additionalContext;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) return _isValidatorInstalled(module);
        else if (moduleTypeId == MODULE_TYPE_EXECUTOR) return _isExecutorInstalled(module);
        else if (moduleTypeId == MODULE_TYPE_FALLBACK) return _isFallbackHandlerInstalled(abi.decode(additionalContext, (bytes4)), module);
        else if (moduleTypeId == MODULE_TYPE_HOOK) return _isHookInstalled(module);
        else return false;
    }
}
