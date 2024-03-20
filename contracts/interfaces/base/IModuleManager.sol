// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ERC-7579 Module Manager Interface
 * @dev Interface for configuring modules in a smart account.
 */
interface IModuleManager {
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);

    error CannotRemoveLastValidator();
    error InvalidModule(address module);
    error InvalidModuleTypeId(uint256 moduleTypeId);
    error ModuleAlreadyInstalled(uint256 moduleTypeId, address module);
    error UnauthorizedOperation(address operator);
    error ModuleNotInstalled(uint256 moduleTypeId, address module);
    error IncompatibleValidatorModule(address module);
    error IncompatibleExecutorModule(address module);
    error ModuleAddressCanNotBeZero();
    error HookPostCheckFailed();
    error HookAlreadyInstalled(address currentHook);
    error FallbackHandlerAlreadyInstalled();

    /**
     * @notice Installs a Module of a certain type on the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param initData Initialization data for the module.
     */
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable;

    /**
     * @notice Uninstalls a Module of a certain type from the smart account.
     * @param moduleTypeId The module type ID.
     * @param module The module address.
     * @param deInitData De-initialization data for the module.
     */
    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable;

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
    ) external view returns (bool);
}
