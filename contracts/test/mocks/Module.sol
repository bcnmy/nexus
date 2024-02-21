// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IModule } from "../../interfaces/IModule.sol";

contract Module is IModule {
    uint256 public constant TYPE_ID = 1;

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
    function getModuleTypes() external view returns (uint256) {
        return TYPE_ID;
    }
}
