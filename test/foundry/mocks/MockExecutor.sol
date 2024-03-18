// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { IExecutor } from "contracts/interfaces/modules/IExecutor.sol";
import { IValidator, VALIDATION_SUCCESS, VALIDATION_FAILED } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { IERC4337Account } from "contracts/interfaces/IERC4337Account.sol";
import "../utils/Imports.sol";

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function executeViaAccount(
        SmartAccount account,
        address target,
        uint256 value,
        bytes calldata callData
    )
        external
        returns (bytes[] memory returnData)
    {
        return account.executeFromExecutor(ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(target, value, callData));
    }

    function execBatch(SmartAccount account, Execution[] calldata execs) external returns (bytes[] memory returnData) {
        return account.executeFromExecutor(ModeLib.encodeSimpleBatch(), ExecLib.encodeBatch(execs));
    }

    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        return moduleTypeId == 2;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) { }

    function isInitialized(address smartAccount) external view returns (bool) {
        return false;
    }

    function test_() public pure {
        // This function is used to ignore file in coverage report
    }
}
