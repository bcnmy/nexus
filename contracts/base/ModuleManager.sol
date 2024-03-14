// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
import { Receiver } from "solady/src/accounts/Receiver.sol";
import { SentinelListLib } from "sentinellist/src/SentinelList.sol";
import { Storage } from "./Storage.sol";
import { IModule } from "../interfaces/modules/IModule.sol";
import { IValidator } from "../interfaces/modules/IValidator.sol";
import { IExecutor } from "../interfaces/modules/IExecutor.sol";
import { MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR } from "../interfaces/modules/IERC7579Modules.sol";
import { EncodedModuleTypes } from "../lib/ModuleTypeLib.sol";

// Note: importing Receiver.sol from solady (but can make custom one for granular control for fallback management)
// Review: This contract could also act as fallback manager rather than having a separate contract
// Review: Kept a different linked list for validators, executors
abstract contract ModuleManager is Storage, Receiver, IModuleManager {
    using SentinelListLib for SentinelListLib.SentinelList;

    modifier onlyExecutorModule() virtual {
        SentinelListLib.SentinelList storage executors = _getAccountStorage().executors;
        if (!executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) virtual {
        SentinelListLib.SentinelList storage validators = _getAccountStorage().validators;
        if (!validators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    /**
     * @notice Installs a Module of a certain type on the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param initData Initialization data for the module.
     */
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable virtual;

    /**
     * @notice Uninstalls a Module of a certain type from the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param deInitData De-initialization data for the module.
     */
    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable virtual;

    /**
     * @notice Checks if a module is installed on the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param additionalContext Additional context for checking installation.
     * @return True if the module is installed, false otherwise.
     */
    function isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata additionalContext
    ) external view virtual returns (bool);

    function _initModuleManager() internal virtual {
        // account module storage
        AccountStorage storage ams = _getAccountStorage();
        ams.executors.init();
        ams.validators.init();
    }

    // /////////////////////////////////////////////////////
    // //  Manage Validators
    // ////////////////////////////////////////////////////

    // // TODO
    // // Review this agaisnt required hook/permissions at the time of installations

    function _installValidator(address validator, bytes calldata data) internal virtual {
        // Note: Idea is should be able to check supported interface and module type - eligible validator 
        // if(!IModule(validator).isModuleType(MODULE_TYPE_VALIDATOR)) revert IncompatibleModule(validator);

        SentinelListLib.SentinelList storage validators = _getAccountStorage().validators;
        validators.push(validator);
        IValidator(validator).onInstall(data);
    }

    function _uninstallValidator(address validator, bytes calldata data) internal virtual {
        // TODO: check if its the last validator. this might brick the account
        SentinelListLib.SentinelList storage validators = _getAccountStorage().validators;
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        validators.pop(prev, validator);
        IValidator(validator).onUninstall(disableModuleData);
    }

    //  // TODO
    // // Review this agaisnt required hook/permissions at the time of installations

    function _installExecutor(address executor, bytes calldata data) internal virtual {
        // Note: Idea is should be able to check supported interface and module type - eligible validator 
        // if(!IModule(executor).isModuleType(MODULE_TYPE_EXECUTOR)) revert IncompatibleModule(executor);

        SentinelListLib.SentinelList storage executors = _getAccountStorage().executors;
        executors.push(executor);
        IExecutor(executor).onInstall(data);
    }

    function _uninstallExecutor(address executor, bytes calldata data) internal virtual {
        SentinelListLib.SentinelList storage executors = _getAccountStorage().executors;
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        executors.pop(prev, executor);
        IExecutor(executor).onUninstall(disableModuleData);
    }

    function _isValidatorInstalled(address validator) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage validators = _getAccountStorage().validators;
        return validators.contains(validator);
    }

    function _isExecutorInstalled(address executor) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage executors = _getAccountStorage().executors;
        return executors.contains(executor);
    }

    function _isAlreadyInitialized() internal view virtual returns (bool) {
        // account module storage
        AccountStorage storage ams = _getAccountStorage();
        return ams.validators.alreadyInitialized();
    }
}
