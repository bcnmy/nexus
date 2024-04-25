// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC7579ModuleBase } from "contracts/interfaces/modules/IERC7579ModuleBase.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import "contracts/types/Constants.sol";

contract MockHook is IERC7579ModuleBase {
    event PreCheckCalled();
    event PostCheckCalled();

    function onInstall(bytes calldata) external override {
        emit PreCheckCalled();
    }

    function onUninstall(bytes calldata) external override {
        emit PostCheckCalled();
    }

    function preCheck(address, uint256, bytes calldata) external returns (bytes memory) {
        emit PreCheckCalled();
        return "";
    }

    function postCheck(bytes calldata, bool, bytes calldata) external {
        emit PostCheckCalled();
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    function isInitialized(address) external pure returns (bool) {
        return false;
    }

    // Review
    function test() public pure {
        // @todo To be removed
    }
}
