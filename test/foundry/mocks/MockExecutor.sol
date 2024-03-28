// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { IExecutor, Execution } from "contracts/interfaces/modules/IExecutor.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import { IModularSmartAccount } from "contracts/interfaces/IModularSmartAccount.sol";
import { ModeLib } from "contracts/lib/ModeLib.sol";
import { ExecLib } from "contracts/lib/ExecLib.sol";

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function executeViaAccount(
        IModularSmartAccount account,
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes[] memory returnData)
    {
        return account.executeFromExecutor(ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(target, value, callData));
    }

    function execBatch(
        IModularSmartAccount account,
        Execution[] calldata execs
    )
        external
        returns (bytes[] memory returnData)
    {
        return account.executeFromExecutor(ModeLib.encodeSimpleBatch(), ExecLib.encodeBatch(execs));
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == 2;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) { }

    function test_() public pure {
        // This function is used to ignore file in coverage report
    }
}
