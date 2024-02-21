// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IModule } from "../../interfaces/IModule.sol";
import { EncodedModuleTypes } from "../../lib/ModuleTypeLib.sol";

contract Module is IModule {
    /// @inheritdoc IModule
    function onInstall(bytes calldata data) external {
        data;
    }

    /// @inheritdoc IModule
    function onUninstall(bytes calldata data) external {
        data;
    }

    /// @inheritdoc IModule
    function isModuleType(uint256 typeID) external view returns (bool) {
        typeID;
        return true;
    }

    /// @inheritdoc IModule
    function getModuleTypes() external view returns (EncodedModuleTypes) {
        // solhint-disable-previous-line no-empty-blocks
    }
}
