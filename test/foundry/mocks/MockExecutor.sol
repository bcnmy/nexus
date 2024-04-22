// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IModule, IExecutor, Execution } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import { IBicoMSA } from "contracts/interfaces/IBicoMSA.sol";
import { ModeLib } from "contracts/lib/ModeLib.sol";
import { ExecLib } from "contracts/lib/ExecLib.sol";

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function executeViaAccount(
        IBicoMSA account,
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes[] memory returnData)
    {
        return account.executeFromExecutor(ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(target, value, callData));
    }

    function executeBatchViaAccount(
        IBicoMSA account,
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

    function isInitialized(address smartAccount) external pure override returns (bool) {
        return false;
    }
}
