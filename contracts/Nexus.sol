// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { UUPSUpgradeable } from "solady/utils/UUPSUpgradeable.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ExecLib } from "./lib/ExecLib.sol";
import { INexus } from "./interfaces/INexus.sol";
import { BaseAccount } from "./base/BaseAccount.sol";
import { IERC7484 } from "./interfaces/IERC7484.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { ExecutionHelper } from "./base/ExecutionHelper.sol";
import { IValidator } from "./interfaces/modules/IValidator.sol";
import {
    MODULE_TYPE_VALIDATOR,
    MODULE_TYPE_EXECUTOR,
    MODULE_TYPE_FALLBACK,
    MODULE_TYPE_HOOK,
    MODULE_TYPE_MULTI,
    MODULE_TYPE_PREVALIDATION_HOOK_ERC1271,
    MODULE_TYPE_PREVALIDATION_HOOK_ERC4337,
    SUPPORTS_ERC7739,
    VALIDATION_SUCCESS,
    VALIDATION_FAILED
} from "./types/Constants.sol";
import {
    ModeLib,
    ExecutionMode,
    ExecType,
    CallType,
    ModeSelector,
    CALLTYPE_BATCH,
    CALLTYPE_SINGLE,
    CALLTYPE_DELEGATECALL,
    EXECTYPE_DEFAULT,
    EXECTYPE_TRY,
    MODE_BATCH_OPDATA,
    MODE_DEFAULT
} from "./lib/ModeLib.sol";
import { NonceLib } from "./lib/NonceLib.sol";
import { SentinelListLib, SENTINEL, ZERO_ADDRESS } from "sentinellist/SentinelList.sol";
import { Initializable } from "./lib/Initializable.sol";
import { EmergencyUninstall } from "./types/DataTypes.sol";

/// @title Nexus - Smart Account
/// @notice This contract integrates various functionalities to handle modular smart accounts compliant with ERC-7579 and ERC-4337 standards.
/// @dev Comprehensive suite of methods for managing smart accounts, integrating module management, execution management, and upgradability via UUPS.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract Nexus is INexus, BaseAccount, ExecutionHelper, ModuleManager, UUPSUpgradeable {
    using ModeLib for ExecutionMode;
    using ExecLib for bytes;
    using NonceLib for uint256;
    using SentinelListLib for SentinelListLib.SentinelList;

    /// @dev The timelock period for emergency hook uninstallation.
    uint256 internal constant _EMERGENCY_TIMELOCK = 1 days;

    /// @dev The event emitted when an emergency hook uninstallation is initiated.
    event EmergencyHookUninstallRequest(address hook, uint256 timestamp);

    /// @dev The event emitted when an emergency hook uninstallation request is reset.
    event EmergencyHookUninstallRequestReset(address hook, uint256 timestamp);

    /// @notice Initializes the smart account with the specified entry point.
    constructor(address anEntryPoint) {
        require(address(anEntryPoint) != address(0), EntryPointCanNotBeZero());
        _ENTRYPOINT = anEntryPoint;
        _initModuleManager();
    }

    /// @notice Validates a user operation against a specified validator, extracted from the operation's nonce.
    /// @param op The user operation to validate, encapsulating all transaction details.
    /// @param userOpHash Hash of the user operation data, used for signature validation.
    /// @param missingAccountFunds Funds missing from the account's deposit necessary for transaction execution.
    /// This can be zero if covered by a paymaster or if sufficient deposit exists.
    /// @return validationData Encoded validation result or failure, propagated from the validator module.
    /// - Encoded format in validationData:
    ///     - First 20 bytes: Address of the Validator module, to which the validation task is forwarded.
    ///       The validator module returns:
    ///         - `SIG_VALIDATION_SUCCESS` (0) indicates successful validation.
    ///         - `SIG_VALIDATION_FAILED` (1) indicates signature validation failure.
    /// @dev Expects the validator's address to be encoded in the upper 96 bits of the user operation's nonce.
    /// This method forwards the validation task to the extracted validator module address.
    /// @dev The entryPoint calls this function. If validation fails, it returns `VALIDATION_FAILED` (1) otherwise `0`.
    /// @dev Features Module Enable Mode.
    /// This Module Enable Mode flow is intended for the module acting as the validator
    /// for the user operation that triggers the Module Enable Flow. Otherwise, a call to
    /// `Nexus.installModule` should be included in `userOp.callData`.
    function validateUserOp(
        PackedUserOperation calldata op,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        payPrefund(missingAccountFunds)
        onlyEntryPoint
        returns (uint256 validationData)
    {
        address validator = op.nonce.getValidator();
        if (op.nonce.isModuleEnableMode()) {
            PackedUserOperation memory userOp = op;
            userOp.signature = _enableMode(userOpHash, op.signature);
            require(_isValidatorInstalled(validator), ValidatorNotInstalled(validator));
            (userOpHash, userOp.signature) = _withPreValidationHook(userOpHash, userOp, missingAccountFunds);
            validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
        } else {
            if (_isValidatorInstalled(validator)) {
                PackedUserOperation memory userOp = op;
                // If the validator is installed, forward the validation task to the validator
                (userOpHash, userOp.signature) = _withPreValidationHook(userOpHash, op, missingAccountFunds);
                validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
            } else {
                // If the account is not initialized, check the signature against the account
                if (!_hasValidators() && !_hasExecutors()) {
                    // Check the userOp signature if the validator is not installed (used for EIP7702)
                    validationData = _checkSelfSignature(op.signature, userOpHash) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
                } else {
                    // If the account is initialized, revert as the validator is not installed
                    revert ValidatorNotInstalled(validator);
                }
            }
        }
    }

    /// @notice Executes transactions in single or batch modes as specified by the execution mode.
    /// @param mode The execution mode detailing how transactions should be handled (single, batch, default, try/catch).
    /// @param executionData The encoded transaction data to execute.
    /// @dev This function handles transaction execution flexibility and is protected by the `onlyEntryPoint` modifier.
    /// @dev This function also goes through hook checks via withHook modifier.
    function execute(ExecutionMode mode, bytes calldata executionData) external payable withHook {
        (CallType callType, ExecType execType) = _executionGuard({
            mode: mode,
            maxExecutionFrames: 1
        });
        if (callType == CALLTYPE_SINGLE) {
            _handleSingleExecution(executionData, execType);
        } else if (callType == CALLTYPE_BATCH) {
            _handleBatchExecution(executionData, execType);
        } else if (callType == CALLTYPE_DELEGATECALL) {
            _handleDelegateCallExecution(executionData, execType);
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /// @notice Executes transactions from an executor module, supporting both single and batch transactions.
    /// @param mode The execution mode (single or batch, default or try).
    /// @param executionCalldata The transaction data to execute.
    /// @return returnData The results of the transaction executions, which may include errors in try mode.
    /// @dev This function is callable only by an executor module and goes through hook checks.
    function executeFromExecutor(
        ExecutionMode mode,
        bytes calldata executionCalldata
    )
        external
        payable
        onlyExecutorModule
        withHook
        withRegistry(msg.sender, MODULE_TYPE_EXECUTOR)
        returns (bytes[] memory returnData)
    {
        (CallType callType, ExecType execType) = mode.decodeBasic();
        // check if calltype is batch or single or delegate call
        if (callType == CALLTYPE_SINGLE) {
            returnData = _handleSingleExecutionAndReturnData(executionCalldata, execType);
        } else if (callType == CALLTYPE_BATCH) {
            returnData = _handleBatchExecutionAndReturnData(executionCalldata, execType);
        } else if (callType == CALLTYPE_DELEGATECALL) {
            returnData = _handleDelegateCallExecutionAndReturnData(executionCalldata, execType);
        } else {
            revert UnsupportedCallType(callType);
        }
    }

    /// @notice Executes a user operation via a call using the contract's context.
    /// @param userOp The user operation to execute, containing transaction details.
    /// @param - Hash of the user operation.
    /// @dev Only callable by the EntryPoint. Decodes the user operation calldata, skipping the first four bytes, and executes the inner call.
    function executeUserOp(PackedUserOperation calldata userOp, bytes32) external payable virtual onlyEntryPoint withHook {
        bytes calldata callData = userOp.callData[4:];
        (bool success, bytes memory innerCallRet) = address(this).delegatecall(callData);
        if (success) {
            emit Executed(userOp, innerCallRet);
        } else {
            revert ExecutionFailed();
        }
    }

    /// @notice Installs a new module to the smart account.
    /// @param moduleTypeId The type identifier of the module being installed, which determines its role:
    /// - 1 for Validator
    /// - 2 for Executor
    /// - 3 for Fallback
    /// - 4 for Hook
    /// - 8 for 1271 Prevalidation Hook
    /// - 9 for 4337 Prevalidation Hook
    /// @param module The address of the module to install.
    /// @param initData Initialization data for the module.
    /// @dev This function can only be called by the EntryPoint or the account itself for security reasons.
    /// @dev This function goes through hook checks via withHook modifier through internal function _installModule.
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable onlyEntryPointOrSelf {
        // protection for EIP7702 accounts which were not initialized
        // and try to install a validator or executor during the first userOp not via initializeAccount()
        if ((moduleTypeId == MODULE_TYPE_VALIDATOR || moduleTypeId == MODULE_TYPE_EXECUTOR) && !_isAlreadyInitialized()) {
            _initModuleManager();
        }
        _installModule(moduleTypeId, module, initData);
        emit ModuleInstalled(moduleTypeId, module);
    }

    /// @notice Uninstalls a module from the smart account.
    /// @param moduleTypeId The type ID of the module to be uninstalled, matching the installation type:
    /// - 1 for Validator
    /// - 2 for Executor
    /// - 3 for Fallback
    /// - 4 for Hook
    /// - 8 for 1271 Prevalidation Hook
    /// - 9 for 4337 Prevalidation Hook
    /// @param module The address of the module to uninstall.
    /// @param deInitData De-initialization data for the module.
    /// @dev Ensures that the operation is authorized and valid before proceeding with the uninstallation.
    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable onlyEntryPointOrSelf withHook {
        require(_isModuleInstalled(moduleTypeId, module, deInitData), ModuleNotInstalled(moduleTypeId, module));
        emit ModuleUninstalled(moduleTypeId, module);

        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _uninstallValidator(module, deInitData);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _uninstallExecutor(module, deInitData);
        } else if (moduleTypeId == MODULE_TYPE_FALLBACK) {
            _uninstallFallbackHandler(module, deInitData);
        } else if (
            moduleTypeId == MODULE_TYPE_HOOK || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337
        ) {
            _uninstallHook(module, moduleTypeId, deInitData);
        }
    }

    function emergencyUninstallHook(EmergencyUninstall calldata data, bytes calldata signature) external payable {
        // Validate the signature
        _checkEmergencyUninstallSignature(data, signature);
        // Parse uninstall data
        (uint256 hookType, address hook, bytes calldata deInitData) = (data.hookType, data.hook, data.deInitData);

        // Validate the hook is of a supported type and is installed
        require(
            hookType == MODULE_TYPE_HOOK || hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337,
            UnsupportedModuleType(hookType)
        );
        require(_isModuleInstalled(hookType, hook, deInitData), ModuleNotInstalled(hookType, hook));

        // Get the account storage
        AccountStorage storage accountStorage = _getAccountStorage();
        uint256 hookTimelock = accountStorage.emergencyUninstallTimelock[hook];

        if (hookTimelock == 0) {
            // if the timelock hasnt been initiated, initiate it
            accountStorage.emergencyUninstallTimelock[hook] = block.timestamp;
            emit EmergencyHookUninstallRequest(hook, block.timestamp);
        } else if (block.timestamp >= hookTimelock + 3 * _EMERGENCY_TIMELOCK) {
            // if the timelock has been left for too long, reset it
            accountStorage.emergencyUninstallTimelock[hook] = block.timestamp;
            emit EmergencyHookUninstallRequestReset(hook, block.timestamp);
        } else if (block.timestamp >= hookTimelock + _EMERGENCY_TIMELOCK) {
            // if the timelock expired, clear it and uninstall the hook
            accountStorage.emergencyUninstallTimelock[hook] = 0;
            _uninstallHook(hook, hookType, deInitData);
            emit ModuleUninstalled(hookType, hook);
        } else {
            // if the timelock is initiated but not expired, revert
            revert EmergencyTimeLockNotExpired();
        }
    }

    /// @notice Initializes the smart account with the specified initialization data.
    /// @param initData The initialization data for the smart account.
    /// @dev This function can only be called by the account itself or the proxy factory.
    /// When a 7702 account is created, the first userOp should contain self-call to initialize the account.
    function initializeAccount(bytes calldata initData) external payable virtual {
        // Protect this function to only be callable when used with the proxy factory or when
        // account calls itself
        if (msg.sender != address(this)) {
            Initializable.requireInitializable();
        }

        _initModuleManager();
        (address bootstrap, bytes memory bootstrapCall) = abi.decode(initData, (address, bytes));
        (bool success,) = bootstrap.delegatecall(bootstrapCall);

        require(success, NexusInitializationFailed());
        require(_hasValidators(), NoValidatorInstalled());
    }

    function setRegistry(IERC7484 newRegistry, address[] calldata attesters, uint8 threshold) external payable onlyEntryPointOrSelf {
        _configureRegistry(newRegistry, attesters, threshold);
    }

    /// @notice Validates a signature according to ERC-1271 standards.
    /// @param hash The hash of the data being validated.
    /// @param signature Signature data that needs to be validated.
    /// @return The status code of the signature validation (`0x1626ba7e` if valid).
    /// bytes4(keccak256("isValidSignature(bytes32,bytes)") = 0x1626ba7e
    /// @dev Delegates the validation to a validator module specified within the signature data.
    function isValidSignature(bytes32 hash, bytes calldata signature) external view virtual override returns (bytes4) {
        // Handle potential ERC7739 support detection request
        if (signature.length == 0) {
            // Forces the compiler to optimize for smaller bytecode size.
            if (uint256(hash) == (~signature.length / 0xffff) * 0x7739) {
                return checkERC7739Support(hash, signature);
            }
        }
        // else proceed with normal signature verification
        // First 20 bytes of data will be validator address and rest of the bytes is complete signature.
        address validator = address(bytes20(signature[0:20]));
        require(_isValidatorInstalled(validator), ValidatorNotInstalled(validator));
        bytes memory signature_;
        (hash, signature_) = _withPreValidationHook(hash, signature[20:]);
        try IValidator(validator).isValidSignatureWithSender(msg.sender, hash, signature_) returns (bytes4 res) {
            return res;
        } catch {
            return bytes4(0xffffffff);
        }
    }

    /// @notice Retrieves the address of the current implementation from the EIP-1967 slot.
    /// @notice Checks the 1967 implementation slot, if not found then checks the slot defined by address (Biconomy V2 smart account)
    /// @return implementation The address of the current contract implementation.
    function getImplementation() external view returns (address implementation) {
        assembly {
            implementation := sload(_ERC1967_IMPLEMENTATION_SLOT)
        }
        if (implementation == address(0)) {
            assembly {
                implementation := sload(address())
            }
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
        else if (moduleTypeId == MODULE_TYPE_MULTI) return true;
        else return false;
    }

    /// @notice Determines if a specific execution mode is supported.
    /// @param mode The execution mode to evaluate.
    /// @return isSupported True if the execution mode is supported, false otherwise.
    function supportsExecutionMode(ExecutionMode mode) external view virtual returns (bool) {
        (CallType callType, ExecType execType, ModeSelector modeSelector, ) = mode.decode();

        if ((callType == CALLTYPE_SINGLE || callType == CALLTYPE_DELEGATECALL)
            && (execType == EXECTYPE_DEFAULT || execType == EXECTYPE_TRY) 
            && modeSelector == MODE_DEFAULT)
        {
            return true;
        }

        if (callType == CALLTYPE_BATCH
            && (execType == EXECTYPE_DEFAULT || execType == EXECTYPE_TRY))
        {
            if (modeSelector == MODE_BATCH_OPDATA || modeSelector == MODE_DEFAULT) {
                return true;
            } 
            // Do not support batch of batches
            return false;
        }
        return false;
    }

    /// @notice Determines whether a module is installed on the smart account.
    /// @param moduleTypeId The ID corresponding to the type of module (Validator, Executor, Fallback, Hook).
    /// @param module The address of the module to check.
    /// @param additionalContext Optional context that may be needed for certain checks.
    /// @return True if the module is installed, false otherwise.
    function isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) external view returns (bool) {
        return _isModuleInstalled(moduleTypeId, module, additionalContext);
    }

    /// @dev EIP712 hashTypedData method.
    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedData(structHash);
    }

    /// @dev EIP712 domain separator.
    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    /// Returns the account's implementation ID.
    /// @return The unique identifier for this account implementation.
    function accountId() external pure virtual returns (string memory) {
        return _ACCOUNT_IMPLEMENTATION_ID;
    }

    /// Upgrades the contract to a new implementation and calls a function on the new contract.
    /// @notice Updates two slots 1. ERC1967 slot and
    /// 2. address() slot in case if it's potentially upgraded earlier from Biconomy V2 account,
    /// as Biconomy v2 Account (proxy) reads implementation from the slot that is defined by its address
    /// @param newImplementation The address of the new contract implementation.
    /// @param data The calldata to be sent to the new implementation.
    function upgradeToAndCall(address newImplementation, bytes calldata data) public payable virtual override withHook {
        require(newImplementation != address(0), InvalidImplementationAddress());
        bool res;
        assembly {
            res := gt(extcodesize(newImplementation), 0)
        }
        require(res, InvalidImplementationAddress());
        // update the address() storage slot as well.
        assembly {
            sstore(address(), newImplementation)
        }
        UUPSUpgradeable.upgradeToAndCall(newImplementation, data);
    }

    /// @dev For automatic detection that the smart account supports the ERC7739 workflow
    /// Iterates over all the validators but only if this is a detection request
    /// ERC-7739 spec assumes that if the account doesn't support ERC-7739
    /// it will try to handle the detection request as it was normal sig verification
    /// request and will return 0xffffffff since it won't be able to verify the 0x signature
    /// against 0x7739...7739 hash.
    /// So this approach is consistent with the ERC-7739 spec.
    /// If no validator supports ERC-7739, this function returns false
    /// thus the account will proceed with normal signature verification
    /// and return 0xffffffff as a result.
    function checkERC7739Support(bytes32 hash, bytes calldata signature) public view virtual returns (bytes4) {
        bytes4 result;
        unchecked {
            SentinelListLib.SentinelList storage validators = _getAccountStorage().validators;
            address next = validators.entries[SENTINEL];
            while (next != ZERO_ADDRESS && next != SENTINEL) {
                bytes4 support = IValidator(next).isValidSignatureWithSender(msg.sender, hash, signature);
                if (bytes2(support) == bytes2(SUPPORTS_ERC7739) && support > result) {
                    result = support;
                }
                next = validators.getNext(next);
            }
        }
        return result == bytes4(0) ? bytes4(0xffffffff) : result;
    }

    /// @dev Passes if
    ///      a) the caller is the EntryPoint 
    ///      b) calltype is batch, and no ERC-7821 opdata, and the caller is this account itself, 
    ///         and that the account has not self-called more than maxExecutionFrames.
    ///      c) calltype is batch with ERC-7821 opdata, and the sig in opData is by an authorized signer
    /// The execution frames limit is introduced to prevent hiding actions in the self-call loop calldata.
    function _executionGuard(ExecutionMode mode, uint256 maxExecutionFrames) internal returns (CallType callType, ExecType execType) {
        ModeSelector modeSelector;
        (callType, execType, modeSelector,) = mode.decode();
        if (msg.sender == _ENTRYPOINT) {
            return (callType, execType);
        }
        if (callType == CALLTYPE_BATCH) {
            if (modeSelector == MODE_DEFAULT) {
                require(msg.sender == address(this), AccountAccessUnauthorized());
                assembly {
                    let executionFrames := tload(EXECUTION_FRAMES_SLOT)
                    if gt(executionFrames, maxExecutionFrames) {
                        mstore(0x00, 0x5a2da10d) // `NoSelfExecutionLoops()`.
                        revert(0x1c, 0x04)
                    }
                    tstore(EXECUTION_FRAMES_SLOT, add(executionFrames, 1))
                }
                return (callType, execType);
            } else if (modeSelector == MODE_BATCH_OPDATA) {
                // TODO: Implement sig verification for opdata
            }
            // other mode selectors are not supported
            revert AccountAccessUnauthorized();
        }
        revert AccountAccessUnauthorized();
    }

    /// @dev Ensures that only authorized callers can upgrade the smart contract implementation.
    /// This is part of the UUPS (Universal Upgradeable Proxy Standard) pattern.
    /// @param newImplementation The address of the new implementation to upgrade to.
    function _authorizeUpgrade(address newImplementation) internal virtual override(UUPSUpgradeable) onlyEntryPointOrSelf { }

    /// @dev EIP712 domain name and version.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "Nexus";
        version = "1.0.1";
    }
}
