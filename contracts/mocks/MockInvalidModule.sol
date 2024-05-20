// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModule } from "../interfaces/modules/IModule.sol";
contract MockInvalidModule is IModule {
 

    function onInstall(bytes calldata data) external {
        data;
    }

    function onUninstall(bytes calldata data) external {
        data;
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == 99;
    }

    function isInitialized(address smartAccount) external view returns (bool) {
            return false;
    }


}
