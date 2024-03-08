// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
import { Storage } from "./Storage.sol";
import { IModule } from "../interfaces/modules/IModule.sol";

// Todo: Implement methods for installing specific module types
contract ModuleManager is Storage, IModuleManager {
    /**
     * @notice Installs a Module of a certain type on the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param initData Initialization data for the module.
     */
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable virtual {
        AccountStorage storage $ = _getAccountStorage();
        $.modules[module] = module;

        IModule(module).onInstall(initData);
        moduleTypeId;
        initData;
    }

    /**
     * @notice Uninstalls a Module of a certain type from the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param deInitData De-initialization data for the module.
     */
    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    )
        external
        payable
        virtual
    {
        AccountStorage storage $ = _getAccountStorage();
        moduleTypeId;
        deInitData;
        delete $.modules[module];
    }

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
    )
        external
        view
        returns (bool)
    {
        AccountStorage storage $ = _getAccountStorage();
        additionalContext;
        moduleTypeId;
        return $.modules[module] != address(0);
    }
}
