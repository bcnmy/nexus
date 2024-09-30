// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IModule } from "../interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "../lib/ModuleTypeLib.sol";
import "../types/Constants.sol";

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

    function preCheck(address sender, uint256 value, bytes calldata data) external returns (bytes memory) {
        emit PreCheckCalled();

        // Add a condition to revert if the sender is the zero address or if the value is 1 ether for testing purposes
        if (value == 1 ether) {
            revert("PreCheckFailed");
        }

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
