// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { EncodedModuleTypes } from "../../lib/ModuleTypeLib.sol";

/**
 * @title ERC-7579 Module Interface
 * @dev Basic interface for all types of modules.
 */
interface IModule {
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);

    /**
     * @dev This function is called by the smart account during installation of the module
     * @param data arbitrary data that may be required on the module during `onInstall`
     * initialization
     *
     * MUST revert on error (i.e. if module is already enabled)
     */
    function onInstall(bytes calldata data) external;

    /**
     * @dev This function is called by the smart account during uninstallation of the module
     * @param data arbitrary data that may be required on the module during `onUninstall`
     * de-initialization
     *
     * MUST revert on error
     */
    function onUninstall(bytes calldata data) external;

    /**
     * @dev Returns boolean value if module is a certain type
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     *
     * MUST return true if the module is of the given type and false otherwise
     */
    function isModuleType(uint256 moduleTypeId) external view returns (bool);

    /**
     * @dev Returns bit-encoded integer of the different typeIds of the module
     *
     * MUST return all the bit-encoded typeIds of the module
     */
    function getModuleTypes() external view returns (EncodedModuleTypes);
}
