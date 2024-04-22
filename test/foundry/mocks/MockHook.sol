// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IHook, MODULE_TYPE_HOOK } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { IModule } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";

contract MockHook is IHook {

    event PreCheckCalled();
    event PostCheckCalled();

    function onInstall(bytes calldata data) external override { 
        emit PreCheckCalled();
    }

    function onUninstall(bytes calldata data) external override { 
        emit PostCheckCalled();
     }

    /// @inheritdoc IHook
    function preCheck(address msgSender, uint256 msgValue, bytes calldata msgData) external returns (bytes memory hookData) {
        emit PreCheckCalled();
     }

    /// @inheritdoc IHook
    function postCheck(
        bytes calldata hookData,
        bool executionSuccess,
        bytes calldata executionReturnValue
    )
        external
    { 
        emit PostCheckCalled();
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_HOOK;
    }

    function isInitialized(address smartAccount) external pure returns (bool) {
        return false;
    }

    // Review
    function test() public pure {
        // @todo To be removed 
    }
}
