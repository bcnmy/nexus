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

import { SentinelListLib } from "sentinellist/SentinelList.sol";
import { Storage } from "./Storage.sol";
import { IHook } from "../interfaces/modules/IHook.sol";
import { IModule } from "../interfaces/modules/IModule.sol";
import { IPreValidationHookERC1271, IPreValidationHookERC4337 } from "../interfaces/modules/IPreValidationHook.sol";
import { IExecutor } from "../interfaces/modules/IExecutor.sol";
import { IFallback } from "../interfaces/modules/IFallback.sol";
import { IValidator } from "../interfaces/modules/IValidator.sol";
import { CallType, CALLTYPE_SINGLE, CALLTYPE_STATIC } from "../lib/ModeLib.sol";
import { ExecLib } from "../lib/ExecLib.sol";
import { LocalCallDataParserLib } from "../lib/local/LocalCallDataParserLib.sol";
import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
import {
    MODULE_TYPE_VALIDATOR,
    MODULE_TYPE_EXECUTOR,
    MODULE_TYPE_FALLBACK,
    MODULE_TYPE_HOOK,
    MODULE_TYPE_PREVALIDATION_HOOK_ERC1271,
    MODULE_TYPE_PREVALIDATION_HOOK_ERC4337,
    MODULE_TYPE_MULTI,
    MODULE_ENABLE_MODE_TYPE_HASH,
    EMERGENCY_UNINSTALL_TYPE_HASH,
    ERC1271_MAGICVALUE
} from "../types/Constants.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import { ExcessivelySafeCall } from "excessively-safe-call/ExcessivelySafeCall.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { RegistryAdapter } from "./RegistryAdapter.sol";
import { EmergencyUninstall } from "../types/DataTypes.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";

/// @title Nexus - ModuleManager
/// @notice Manages Validator, Executor, Hook, and Fallback modules within the Nexus suite, supporting
/// @dev Implements SentinelList for managing modules via a linked list structure, adhering to ERC-7579.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
abstract contract ModuleManager is Storage, EIP712, IModuleManager, RegistryAdapter {
    using SentinelListLib for SentinelListLib.SentinelList;
    using LocalCallDataParserLib for bytes;
    using ExecLib for address;
    using ExcessivelySafeCall for address;
    using ECDSA for bytes32;

    /// @dev The default validator address.
    /// @notice To explicitly initialize the default validator, Nexus.execute(_DEFAULT_VALIDATOR.onInstall(...)) should be called.
    address internal immutable _DEFAULT_VALIDATOR;

    /// @dev initData should block the implementation from being used as a Smart Account
    constructor(address _defaultValidator, bytes memory _initData) {
        if (!IValidator(_defaultValidator).isModuleType(MODULE_TYPE_VALIDATOR)) 
            revert MismatchModuleTypeId(); 
        IValidator(_defaultValidator).onInstall(_initData);
        _DEFAULT_VALIDATOR = _defaultValidator;
    }

    /// @notice Ensures the message sender is a registered executor module.
    modifier onlyExecutorModule() virtual {
        require(_getAccountStorage().executors.contains(msg.sender), InvalidModule(msg.sender));
        _;
    }

    /// @notice Does pre-checks and post-checks using an installed hook on the account.
    /// @dev sender, msg.data and msg.value is passed to the hook to implement custom flows.
    modifier withHook() {
        address hook = _getHook();
        if (hook == address(0)) {
            _;
        } else {
            bytes memory hookData = IHook(hook).preCheck(msg.sender, msg.value, msg.data);
            _;
            IHook(hook).postCheck(hookData);
        }
    }

    // receive function
    receive() external payable { }

    /// @dev Fallback function to manage incoming calls using designated handlers based on the call type.
    /// Hooked manually in the _fallback function
    fallback() external payable {
        _fallback(msg.data);
    }

    /// @dev Retrieves a paginated list of validator addresses from the linked list.
    /// This utility function is not defined by the ERC-7579 standard and is implemented to facilitate
    /// easier management and retrieval of large sets of validator modules.
    /// @param cursor The address to start pagination from, or zero to start from the first entry.
    /// @param size The number of validator addresses to return.
    /// @return array An array of validator addresses.
    /// @return next The address to use as a cursor for the next page of results.
    function getValidatorsPaginated(address cursor, uint256 size) external view returns (address[] memory array, address next) {
        (array, next) = _paginate(_getAccountStorage().validators, cursor, size);
    }

    /// @dev Retrieves a paginated list of executor addresses from the linked list.
    /// This utility function is not defined by the ERC-7579 standard and is implemented to facilitate
    /// easier management and retrieval of large sets of executor modules.
    /// @param cursor The address to start pagination from, or zero to start from the first entry.
    /// @param size The number of executor addresses to return.
    /// @return array An array of executor addresses.
    /// @return next The address to use as a cursor for the next page of results.
    function getExecutorsPaginated(address cursor, uint256 size) external view returns (address[] memory array, address next) {
        (array, next) = _paginate(_getAccountStorage().executors, cursor, size);
    }

    /// @notice Retrieves the currently active hook address.
    /// @return hook The address of the active hook module.
    function getActiveHook() external view returns (address hook) {
        return _getHook();
    }

    /// @notice Fetches the fallback handler for a specific selector.
    /// @param selector The function selector to query.
    /// @return calltype The type of call that the handler manages.
    /// @return handler The address of the fallback handler.
    function getFallbackHandlerBySelector(bytes4 selector) external view returns (CallType, address) {
        FallbackHandler memory handler = _getAccountStorage().fallbacks[selector];
        return (handler.calltype, handler.handler);
    }

    /// @dev Initializes the module manager by setting up default states for validators and executors.
    function _initSentinelLists() internal virtual {
        // account module storage
        AccountStorage storage ams = _getAccountStorage();
        ams.executors.init();
        ams.validators.init();
    }

    /// @dev Implements Module Enable Mode flow.
    /// @param packedData Data source to parse data required to perform Module Enable mode from.
    /// @return userOpSignature the clean signature which can be further used for userOp validation
    function _enableMode(bytes32 userOpHash, bytes calldata packedData) internal returns (bytes calldata userOpSignature) {
        address module;
        uint256 moduleType;
        bytes calldata moduleInitData;
        bytes calldata enableModeSignature;

        (module, moduleType, moduleInitData, enableModeSignature, userOpSignature) = packedData.parseEnableModeData();

        address enableModeSigValidator = _handleValidator(address(bytes20(enableModeSignature[0:20])));
        
        enableModeSignature = enableModeSignature[20:];
        
        if (!_checkEnableModeSignature({
            structHash: _getEnableModeDataHash(module, moduleType, userOpHash, moduleInitData), 
            sig: enableModeSignature,
            validator: enableModeSigValidator
        })) {
            revert EnableModeSigError();
        }
        this.installModule(moduleType, module, moduleInitData);
    }

    /// @notice Installs a new module to the smart account.
    /// @param moduleTypeId The type identifier of the module being installed, which determines its role:
    /// - 0 for MultiType
    /// - 1 for Validator
    /// - 2 for Executor
    /// - 3 for Fallback
    /// - 4 for Hook
    /// - 8 for PreValidationHookERC1271
    /// - 9 for PreValidationHookERC4337
    /// @param module The address of the module to install.
    /// @param initData Initialization data for the module.
    /// @dev This function goes through hook checks via withHook modifier.
    /// @dev No need to check that the module is already installed, as this check is done
    /// when trying to sstore the module in an appropriate SentinelList
    function _installModule(uint256 moduleTypeId, address module, bytes calldata initData) internal {
        if (!_areSentinelListsInitialized()) {
            _initSentinelLists();
        }
        if (module == address(0)) revert ModuleAddressCanNotBeZero();
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            _installValidator(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            _installExecutor(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_FALLBACK) {
            _installFallbackHandler(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_HOOK) {
            _installHook(module, initData);
        } else if (moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            _installPreValidationHook(moduleTypeId, module, initData);
        } else if (moduleTypeId == MODULE_TYPE_MULTI) {
            _multiTypeInstall(module, initData);
        } else {
            revert InvalidModuleTypeId(moduleTypeId);
        }
    }

    /// @dev Installs a new validator module after checking if it matches the required module type.
    /// @param validator The address of the validator module to be installed.
    /// @param data Initialization data to configure the validator upon installation.
    function _installValidator(
        address validator,
        bytes calldata data
    )
        internal
        virtual
        withHook
        withRegistry(validator, MODULE_TYPE_VALIDATOR) 
    {
        if (!IValidator(validator).isModuleType(MODULE_TYPE_VALIDATOR)) revert MismatchModuleTypeId();
        if (validator == _DEFAULT_VALIDATOR) {
            revert DefaultValidatorAlreadyInstalled();
        }
        _getAccountStorage().validators.push(validator);
        IValidator(validator).onInstall(data);
    }

    /// @dev Uninstalls a validator module.
    /// @param validator The address of the validator to be uninstalled.
    /// @param data De-initialization data to configure the validator upon uninstallation.
    function _uninstallValidator(address validator, bytes calldata data) internal virtual {
        SentinelListLib.SentinelList storage validators = _getAccountStorage().validators;

        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));

        // Perform the removal first
        validators.pop(prev, validator);

        validator.excessivelySafeCall(gasleft(), 0, 0, abi.encodeWithSelector(IModule.onUninstall.selector, disableModuleData));
    }

    /// @dev Installs a new executor module after checking if it matches the required module type.
    /// @param executor The address of the executor module to be installed.
    /// @param data Initialization data to configure the executor upon installation.
    function _installExecutor(
        address executor,
        bytes calldata data
    ) 
        internal
        virtual
        withHook
        withRegistry(executor, MODULE_TYPE_EXECUTOR) 
    {
        if (!IExecutor(executor).isModuleType(MODULE_TYPE_EXECUTOR)) revert MismatchModuleTypeId();
        _getAccountStorage().executors.push(executor);
        IExecutor(executor).onInstall(data);
    }

    /// @dev Uninstalls an executor module by removing it from the executors list.
    /// @param executor The address of the executor to be uninstalled.
    /// @param data De-initialization data to configure the executor upon uninstallation.
    function _uninstallExecutor(address executor, bytes calldata data) internal virtual {
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        _getAccountStorage().executors.pop(prev, executor);
        executor.excessivelySafeCall(gasleft(), 0, 0, abi.encodeWithSelector(IModule.onUninstall.selector, disableModuleData));
    }

    /// @dev Installs a hook module, ensuring no other hooks are installed before proceeding.
    /// @param hook The address of the hook to be installed.
    /// @param data Initialization data to configure the hook upon installation.
    function _installHook(
        address hook,
        bytes calldata data
    ) 
        internal
        virtual
        withHook
        withRegistry(hook, MODULE_TYPE_HOOK) 
    {
        if (!IHook(hook).isModuleType(MODULE_TYPE_HOOK)) revert MismatchModuleTypeId();
        address currentHook = _getHook();
        require(currentHook == address(0), HookAlreadyInstalled(currentHook));
        _setHook(hook);
        IHook(hook).onInstall(data);
    }

    /// @dev Uninstalls a hook module, ensuring the current hook matches the one intended for uninstallation.
    /// @param hook The address of the hook to be uninstalled.
    /// @param hookType The type of the hook to be uninstalled.
    /// @param data De-initialization data to configure the hook upon uninstallation.
    function _uninstallHook(address hook, uint256 hookType, bytes calldata data) internal virtual {
        if (hookType == MODULE_TYPE_HOOK) {
            _setHook(address(0));
        } else if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            _uninstallPreValidationHook(hook, hookType, data);
        }
        hook.excessivelySafeCall(gasleft(), 0, 0, abi.encodeWithSelector(IModule.onUninstall.selector, data));
    }

    /// @dev Sets the current hook in the storage to the specified address.
    /// @param hook The new hook address.
    function _setHook(address hook) internal virtual {
        _getAccountStorage().hook = IHook(hook);
    }

    /// @dev Installs a fallback handler for a given selector with initialization data.
    /// @param handler The address of the fallback handler to install.
    /// @param params The initialization parameters including the selector and call type.
    function _installFallbackHandler(
        address handler, 
        bytes calldata params
    )
        internal 
        virtual
        withHook
        withRegistry(handler, MODULE_TYPE_FALLBACK) 
    {
        if (!IFallback(handler).isModuleType(MODULE_TYPE_FALLBACK)) revert MismatchModuleTypeId();
        // Extract the function selector from the provided parameters.
        bytes4 selector = bytes4(params[0:4]);

        // Extract the call type from the provided parameters.
        CallType calltype = CallType.wrap(bytes1(params[4]));

        require(calltype == CALLTYPE_SINGLE || calltype == CALLTYPE_STATIC, FallbackCallTypeInvalid());

        // Extract the initialization data from the provided parameters.
        bytes memory initData = params[5:];

        // Revert if the selector is either `onInstall(bytes)` (0x6d61fe70) or `onUninstall(bytes)` (0x8a91b0e3) or explicit bytes(0).
        // These selectors are explicitly forbidden to prevent security vulnerabilities.
        // Allowing these selectors would enable unauthorized users to uninstall and reinstall critical modules.
        // If a validator module is uninstalled and reinstalled without proper authorization, it can compromise
        // the account's security and integrity. By restricting these selectors, we ensure that the fallback handler
        // cannot be manipulated to disrupt the expected behavior and security of the account.
        require(!(selector == bytes4(0x6d61fe70) || selector == bytes4(0x8a91b0e3) || selector == bytes4(0)), FallbackSelectorForbidden());

        // Revert if a fallback handler is already installed for the given selector.
        // This check ensures that we do not overwrite an existing fallback handler, which could lead to unexpected behavior.
        require(!_isFallbackHandlerInstalled(selector), FallbackAlreadyInstalledForSelector(selector));

        // Store the fallback handler and its call type in the account storage.
        // This maps the function selector to the specified fallback handler and call type.
        _getAccountStorage().fallbacks[selector] = FallbackHandler(handler, calltype);

        // Invoke the `onInstall` function of the fallback handler with the provided initialization data.
        // This step allows the fallback handler to perform any necessary setup or initialization.
        IFallback(handler).onInstall(initData);
    }

    /// @dev Uninstalls a fallback handler for a given selector.
    /// @param fallbackHandler The address of the fallback handler to uninstall.
    /// @param data The de-initialization data containing the selector.
    function _uninstallFallbackHandler(address fallbackHandler, bytes calldata data) internal virtual {
        _getAccountStorage().fallbacks[bytes4(data[0:4])] = FallbackHandler(address(0), CallType.wrap(0x00));
        fallbackHandler.excessivelySafeCall(gasleft(), 0, 0, abi.encodeWithSelector(IModule.onUninstall.selector, data[4:]));
    }

    /// @dev Installs a pre-validation hook module, ensuring no other pre-validation hooks are installed before proceeding.
    /// @param preValidationHookType The type of the pre-validation hook.
    /// @param preValidationHook The address of the pre-validation hook to be installed.
    /// @param data Initialization data to configure the hook upon installation.
    function _installPreValidationHook(
        uint256 preValidationHookType,
        address preValidationHook,
        bytes calldata data
    )
        internal
        virtual
        withHook
        withRegistry(preValidationHook, preValidationHookType)
    {
        if (!IModule(preValidationHook).isModuleType(preValidationHookType)) revert MismatchModuleTypeId();
        address currentPreValidationHook = _getPreValidationHook(preValidationHookType);
        require(currentPreValidationHook == address(0), PrevalidationHookAlreadyInstalled(currentPreValidationHook));
        _setPreValidationHook(preValidationHookType, preValidationHook);
        IModule(preValidationHook).onInstall(data);
    }

    /// @dev Uninstalls a pre-validation hook module
    /// @param preValidationHook The address of the pre-validation hook to be uninstalled.
    /// @param hookType The type of the pre-validation hook.
    /// @param data De-initialization data to configure the hook upon uninstallation.
    function _uninstallPreValidationHook(address preValidationHook, uint256 hookType, bytes calldata data) internal virtual {
        _setPreValidationHook(hookType, address(0));
    }

    /// @dev Sets the current pre-validation hook in the storage to the specified address, based on the hook type.
    /// @param hookType The type of the pre-validation hook.
    /// @param hook The new hook address.
    function _setPreValidationHook(uint256 hookType, address hook) internal virtual {
        if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271) {
            _getAccountStorage().preValidationHookERC1271 = IPreValidationHookERC1271(hook);
        } else if (hookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            _getAccountStorage().preValidationHookERC4337 = IPreValidationHookERC4337(hook);
        }
    }

    /// @notice Installs a module with multiple types in a single operation.
    /// @dev This function handles installing a multi-type module by iterating through each type and initializing it.
    /// The initData should include an ABI-encoded tuple of (uint[] types, bytes[] initDatas).
    /// @param module The address of the multi-type module.
    /// @param initData Initialization data for each type within the module.
    function _multiTypeInstall(address module, bytes calldata initData) internal virtual {
        (uint256[] calldata types, bytes[] calldata initDatas) = initData.parseMultiTypeInitData();

        uint256 length = types.length;
        if (initDatas.length != length) revert InvalidInput();

        // iterate over all module types and install the module as a type accordingly
        for (uint256 i; i < length; i++) {
            uint256 theType = types[i];

            /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
            /*                      INSTALL VALIDATORS                    */
            /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
            if (theType == MODULE_TYPE_VALIDATOR) {
                _installValidator(module, initDatas[i]);
            }
            /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
            /*                       INSTALL EXECUTORS                    */
            /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
            else if (theType == MODULE_TYPE_EXECUTOR) {
                _installExecutor(module, initDatas[i]);
            }
            /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
            /*                       INSTALL FALLBACK                     */
            /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
            else if (theType == MODULE_TYPE_FALLBACK) {
                _installFallbackHandler(module, initDatas[i]);
            }
            /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
            /*          INSTALL HOOK (global only, not sig-specific)      */
            /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
            else if (theType == MODULE_TYPE_HOOK) {
                _installHook(module, initDatas[i]);
            }
            /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
            /*          INSTALL PRE-VALIDATION HOOK                       */
            /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
            else if (theType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || theType == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
                _installPreValidationHook(theType, module, initDatas[i]);
            }
        }
    }

    /// @notice Checks if an emergency uninstall signature is valid.
    /// @param data The emergency uninstall data.
    /// @param signature The signature to validate.
    function _checkEmergencyUninstallSignature(EmergencyUninstall calldata data, bytes calldata signature) internal {
        address validator = _handleValidator(address(bytes20(signature[0:20])));
        // Hash the data
        bytes32 hash = _getEmergencyUninstallDataHash(data.hook, data.hookType, data.deInitData, data.nonce);
        // Check if nonce is valid
        require(!_getAccountStorage().nonces[data.nonce], InvalidNonce());
        // Mark nonce as used
        _getAccountStorage().nonces[data.nonce] = true;
        // Check if the signature is valid
        require((IValidator(validator).isValidSignatureWithSender(address(this), hash, signature[20:]) == ERC1271_MAGICVALUE), EmergencyUninstallSigError());
    }

    /// @dev Retrieves the pre-validation hook from the storage based on the hook type.
    /// @param preValidationHookType The type of the pre-validation hook.
    /// @return preValidationHook The address of the pre-validation hook.
    function _getPreValidationHook(uint256 preValidationHookType) internal view returns (address preValidationHook) {
        preValidationHook = preValidationHookType == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271
            ? address(_getAccountStorage().preValidationHookERC1271)
            : address(_getAccountStorage().preValidationHookERC4337);
    }

    /// @dev Calls the pre-validation hook for ERC-1271.
    /// @param hash The hash of the user operation.
    /// @param signature The signature to validate.
    /// @return postHash The updated hash after the pre-validation hook.
    /// @return postSig The updated signature after the pre-validation hook.
    function _withPreValidationHook(bytes32 hash, bytes calldata signature) internal view virtual returns (bytes32 postHash, bytes memory postSig) {
        // Get the pre-validation hook for ERC-1271
        address preValidationHook = _getPreValidationHook(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271);
        // If no pre-validation hook is installed, return the original hash and signature
        if (preValidationHook == address(0)) return (hash, signature);
        // Otherwise, call the pre-validation hook and return the updated hash and signature
        else return IPreValidationHookERC1271(preValidationHook).preValidationHookERC1271(msg.sender, hash, signature);
    }

    /// @dev Calls the pre-validation hook for ERC-4337.
    /// @param hash The hash of the user operation.
    /// @param userOp The user operation data.
    /// @param missingAccountFunds The amount of missing account funds.
    /// @return postHash The updated hash after the pre-validation hook.
    /// @return postSig The updated signature after the pre-validation hook.
    function _withPreValidationHook(
        bytes32 hash,
        PackedUserOperation memory userOp,
        uint256 missingAccountFunds
    )
        internal
        virtual
        returns (bytes32 postHash, bytes memory postSig)
    {
        // Get the pre-validation hook for ERC-4337
        address preValidationHook = _getPreValidationHook(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337);
        // If no pre-validation hook is installed, return the original hash and signature
        if (preValidationHook == address(0)) return (hash, userOp.signature);
        // Otherwise, call the pre-validation hook and return the updated hash and signature
        else return IPreValidationHookERC4337(preValidationHook).preValidationHookERC4337(userOp, missingAccountFunds, hash);
    }

    /// @notice Checks if an enable mode signature is valid.
    /// @param structHash data hash.
    /// @param sig Signature.
    /// @param validator Validator address.
    function _checkEnableModeSignature(
        bytes32 structHash,
        bytes calldata sig,
        address validator
    ) internal view returns (bool) {
        bytes32 eip712Digest = _hashTypedData(structHash);
        // Use standard IERC-1271/ERC-7739 interface.
        // Even if the validator doesn't support 7739 under the hood, it is still secure,
        // as eip712digest is already built based on 712Domain of this Smart Account
        // This interface should always be exposed by validators as per ERC-7579
        try IValidator(validator).isValidSignatureWithSender(address(this), eip712Digest, sig) returns (bytes4 res) {
                return res == ERC1271_MAGICVALUE;
        } catch {
            return false;
        }
    }

    /// @notice Builds the enable mode data hash as per eip712
    /// @param module Module being enabled
    /// @param moduleType Type of the module as per EIP-7579
    /// @param userOpHash Hash of the User Operation
    /// @param initData Module init data.
    /// @return structHash data hash
    function _getEnableModeDataHash(address module, uint256 moduleType, bytes32 userOpHash, bytes calldata initData) internal view returns (bytes32) {
        return keccak256(abi.encode(MODULE_ENABLE_MODE_TYPE_HASH, module, moduleType, userOpHash, keccak256(initData)));
    }

    /// @notice Builds the emergency uninstall data hash as per eip712
    /// @param hookType Type of the hook (4 for Hook, 8 for ERC-1271 Prevalidation Hook, 9 for ERC-4337 Prevalidation Hook)
    /// @param hook address of the hook being uninstalled
    /// @param data De-initialization data to configure the hook upon uninstallation.
    /// @param nonce Unique nonce for the operation
    /// @return structHash data hash
    function _getEmergencyUninstallDataHash(address hook, uint256 hookType, bytes calldata data, uint256 nonce) internal view returns (bytes32) {
        return _hashTypedData(keccak256(abi.encode(EMERGENCY_UNINSTALL_TYPE_HASH, hook, hookType, keccak256(data), nonce)));
    }

    /// @notice Checks if a module is installed on the smart account.
    /// @param moduleTypeId The module type ID.
    /// @param module The module address.
    /// @param additionalContext Additional context for checking installation.
    /// @return True if the module is installed, false otherwise.
    function _isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) internal view returns (bool) {
        additionalContext;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            return _isValidatorInstalled(module);
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            return _isExecutorInstalled(module);
        } else if (moduleTypeId == MODULE_TYPE_FALLBACK) {
            bytes4 selector;
            if (additionalContext.length >= 4) {
                selector = bytes4(additionalContext[0:4]);
            } else {
                selector = bytes4(0x00000000);
            }
            return _isFallbackHandlerInstalled(selector, module);
        } else if (moduleTypeId == MODULE_TYPE_HOOK) {
            return _isHookInstalled(module);
        } else if (moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337) {
            return _getPreValidationHook(moduleTypeId) == module;
        } else {
            return false;
        }
    }

    /// @dev Checks if the validator list is already initialized.
    ///      In theory it doesn't 100% mean there is a validator or executor installed.
    ///      Use below functions to check for validators and executors.
    function _areSentinelListsInitialized() internal view virtual returns (bool) {
        // account module storage
        AccountStorage storage ams = _getAccountStorage();
        return ams.validators.alreadyInitialized() && ams.executors.alreadyInitialized();
    }

    /// @dev Checks if a fallback handler is set for a given selector.
    /// @param selector The function selector to check.
    /// @return True if a fallback handler is set, otherwise false.
    function _isFallbackHandlerInstalled(bytes4 selector) internal view virtual returns (bool) {
        FallbackHandler storage handler = _getAccountStorage().fallbacks[selector];
        return handler.handler != address(0);
    }

    /// @dev Checks if the expected fallback handler is installed for a given selector.
    /// @param selector The function selector to check.
    /// @param expectedHandler The address of the handler expected to be installed.
    /// @return True if the installed handler matches the expected handler, otherwise false.
    function _isFallbackHandlerInstalled(bytes4 selector, address expectedHandler) internal view returns (bool) {
        FallbackHandler storage handler = _getAccountStorage().fallbacks[selector];
        return handler.handler == expectedHandler;
    }

    /// @dev Checks if a validator is currently installed.
    /// @param validator The address of the validator to check.
    /// @return True if the validator is installed, otherwise false.
    function _isValidatorInstalled(address validator) internal view virtual returns (bool) {
        return _getAccountStorage().validators.contains(validator);
    }

    /// @dev Checks if an executor is currently installed.
    /// @param executor The address of the executor to check.
    /// @return True if the executor is installed, otherwise false.
    function _isExecutorInstalled(address executor) internal view virtual returns (bool) {
        return _getAccountStorage().executors.contains(executor);
    }

    /// @dev Checks if a hook is currently installed.
    /// @param hook The address of the hook to check.
    /// @return True if the hook is installed, otherwise false.
    function _isHookInstalled(address hook) internal view returns (bool) {
        return _getHook() == hook;
    }

    /// @dev Retrieves the current hook from the storage.
    /// @return hook The address of the current hook.
    function _getHook() internal view returns (address hook) {
        hook = address(_getAccountStorage().hook);
    }

    /// @dev Checks if the account is an ERC7702 account
    function _amIERC7702() internal view returns (bool res) {
        assembly {
            // use extcodesize as the first cheapest check
            if eq(extcodesize(address()), 23) {
                // use extcodecopy to copy first 3 bytes of this contract and compare with 0xef0100
                extcodecopy(address(), 0, 0, 3)
                res := eq(0xef0100, shr(232, mload(0x00)))
            }
            // if it is not 23, we do not even check the first 3 bytes
        }
    }

    /// @dev Returns the validator address to use
    function _handleValidator(address validator) internal view returns (address) {
        if (validator == address(0)) {
            return _DEFAULT_VALIDATOR;
        } else {
            require(_isValidatorInstalled(validator), ValidatorNotInstalled(validator));
            return validator;
        }
    }

    function _fallback(bytes calldata callData) private {
        bool success;
        bytes memory result;
        FallbackHandler storage $fallbackHandler = _getAccountStorage().fallbacks[msg.sig];
        address handler = $fallbackHandler.handler;
        CallType calltype = $fallbackHandler.calltype;

        if (handler != address(0)) {
            // hook manually
            address hook = _getHook();
            bytes memory hookData;
            if (hook != address(0)) {
                hookData = IHook(hook).preCheck(msg.sender, msg.value, msg.data);
            }
            //if there's a fallback handler, call it
            if (calltype == CALLTYPE_STATIC) {
                (success, result) = handler.staticcall(ExecLib.get2771CallData(callData));
            } else if (calltype == CALLTYPE_SINGLE) {
                (success, result) = handler.call{ value: msg.value }(ExecLib.get2771CallData(callData));
            } else {
                revert UnsupportedCallType(calltype);
            }

            // Use revert message from fallback handler if the call was not successful
            assembly {
                if iszero(success) {
                    revert(add(result, 0x20), mload(result))
                }
            }

            // hook post check
            if (hook != address(0)) {
                IHook(hook).postCheck(hookData);
            }

            // return the result
            assembly {
                return(add(result, 0x20), mload(result))
            }
        }
        
        // If there's no handler, the call can be one of onERCXXXReceived()
        // No need to hook this as no execution is done here
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(224, calldataload(0))
            // 0x150b7a02: `onERC721Received(address,address,uint256,bytes)`.
            // 0xf23a6e61: `onERC1155Received(address,address,uint256,uint256,bytes)`.
            // 0xbc197c81: `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`.
            if or(eq(s, 0x150b7a02), or(eq(s, 0xf23a6e61), eq(s, 0xbc197c81))) {
                mstore(0x20, s) // Store `msg.sig`.
                return(0x3c, 0x20) // Return `msg.sig`.
            }
        }
        // if there was no handler and it is not the onERCXXXReceived call, revert
        revert MissingFallbackHandler(msg.sig);
    }

    /// @dev Helper function to paginate entries in a SentinelList.
    /// @param list The SentinelList to paginate.
    /// @param cursor The cursor to start paginating from.
    /// @param size The number of entries to return.
    /// @return array The array of addresses in the list.
    /// @return nextCursor The cursor for the next page of entries.
    function _paginate(
        SentinelListLib.SentinelList storage list,
        address cursor,
        uint256 size
    )
        private
        view
        returns (address[] memory array, address nextCursor)
    {
        (array, nextCursor) = list.getEntriesPaginated(cursor, size);
    }
}
