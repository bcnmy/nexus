// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook, MODULE_TYPE_HOOK } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";

contract BadMockHook {

    event PreCheckCalled();
    event PostCheckCalled();

    function onInstall(bytes calldata data) external { 
        emit PreCheckCalled();
    }

    function onUninstall(bytes calldata data) external { 
        emit PostCheckCalled();
     }

    function preCheck(address msgSender, bytes calldata msgData) external returns (bytes memory hookData) {
        emit PreCheckCalled();
     }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) { }

    // Review
    function test(uint256 a) public pure {
        a;
    }
}
