// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ERC-7579 Module Interface
 * @dev Basic interface for all types of modules.
 */
interface IModule {
    /**
     * @notice Called by the smart account during installation of the module.
     * @param data Initialization data for the module.
     */
    function onInstall(bytes calldata data) external;

    /**
     * @notice Called by the smart account during uninstallation of the module.
     * @param data De-initialization data for the module.
     */
    function onUninstall(bytes calldata data) external;

    /**
     * @notice Checks if the module is of a certain type.
     * @param typeID The module type ID.
     * @return True if the module is of the given type, false otherwise.
     */
    function isModuleType(uint256 typeID) external view returns (bool);

    /**
     * @notice Returns bit-encoded integer of the module types.
     * @return The bit-encoded type IDs of the module.
     */
    function getModuleTypes() external view returns (uint256);
}
