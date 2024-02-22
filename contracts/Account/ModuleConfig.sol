// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IModuleConfig } from "../interfaces/IModuleConfig.sol";
import { Storage } from "./Storage.sol";

contract ModuleConfig is Storage, IModuleConfig {
    /**
     * @notice Installs a Module of a certain type on the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param initData Initialization data for the module.
     */
    function installModule(uint256 moduleType, address module, bytes calldata initData) external payable {
        AccountStorage storage $ = _getAccountStorage();
        $.modules[module] = module;
        moduleType;
        initData;
    }

    /**
     * @notice Uninstalls a Module of a certain type from the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param deInitData De-initialization data for the module.
     */
    function uninstallModule(uint256 moduleType, address module, bytes calldata deInitData) external payable {
        AccountStorage storage $ = _getAccountStorage();
        moduleType;
        deInitData;
        delete $.modules[module];
    }

    /**
     * @notice Checks if a module is installed on the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param additionalContext Additional context for checking installation.
     * @return True if the module is installed, false otherwise.
     */
    function isModuleInstalled(
        uint256 moduleType,
        address module,
        bytes calldata additionalContext
    )
        external
        view
        returns (bool)
    {
        AccountStorage storage $ = _getAccountStorage();
        additionalContext;
        moduleType;
        return $.modules[module] != address(0);
    }
}
