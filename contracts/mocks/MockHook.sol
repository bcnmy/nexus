// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import "contracts/types/Constants.sol";

contract MockHook is IModule {
    event PreCheckCalled();
    event PostCheckCalled();
    event HookOnInstallCalled(bytes32 dataFirstWord);

    function onInstall(bytes calldata data) external override {
        if (data.length >= 0x20) {
            emit HookOnInstallCalled(bytes32(data[0:32]));
        }
    }

    function onUninstall(bytes calldata) external override {
        emit PostCheckCalled();
    }

    function preCheck(address, uint256, bytes calldata) external returns (bytes memory) {
        emit PreCheckCalled();
        return "";
    }

    function postCheck(bytes calldata hookData) external {
        hookData;
        emit PostCheckCalled();
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    function isInitialized(address) external pure returns (bool) {
        return false;
    }
}
