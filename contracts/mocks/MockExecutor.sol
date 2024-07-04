// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import { INexus } from "contracts/interfaces/INexus.sol";
import { MODULE_TYPE_EXECUTOR } from "contracts/types/Constants.sol";
import { ModeLib, ExecutionMode, ExecType, CallType, CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXECTYPE_TRY } from "contracts/lib/ModeLib.sol";
import { ExecLib } from "contracts/lib/ExecLib.sol";

import { IExecutor } from "../../contracts/interfaces/modules/IExecutor.sol";
import "../../contracts/types/DataTypes.sol";

event ExecutorOnInstallCalled(bytes32 dataFirstWord);

contract MockExecutor is IExecutor {
    function onInstall(bytes calldata data) external override {
        if (data.length >= 0x20) {
            emit ExecutorOnInstallCalled(bytes32(data[0:32]));
        }
    }

    function onUninstall(bytes calldata data) external override {}

    function executeViaAccount(INexus account, address target, uint256 value, bytes calldata callData) external returns (bytes[] memory returnData) {
        return account.executeFromExecutor(ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(target, value, callData));
    }

    function executeBatchViaAccount(INexus account, Execution[] calldata execs) external returns (bytes[] memory returnData) {
        return account.executeFromExecutor(ModeLib.encodeSimpleBatch(), ExecLib.encodeBatch(execs));
    }

    function tryExecuteViaAccount(
        INexus account,
        address target,
        uint256 value,
        bytes calldata callData
    ) external returns (bytes[] memory returnData) {
        return account.executeFromExecutor(ModeLib.encodeTrySingle(), ExecLib.encodeSingle(target, value, callData));
    }

    function tryExecuteBatchViaAccount(INexus account, Execution[] calldata execs) external returns (bytes[] memory returnData) {
        return account.executeFromExecutor(ModeLib.encodeTryBatch(), ExecLib.encodeBatch(execs));
    }

    function customExecuteViaAccount(
        ExecutionMode mode,
        INexus account,
        address target,
        uint256 value,
        bytes calldata callData
    ) external returns (bytes[] memory returnData) {
        (CallType callType, ) = ModeLib.decodeBasic(mode);
        bytes memory executionCallData;
        if (callType == CALLTYPE_SINGLE) {
            executionCallData = ExecLib.encodeSingle(target, value, callData);
        } else if (callType == CALLTYPE_BATCH) {
            Execution[] memory execution = new Execution[](1);
            execution[0] = Execution(target, 0, callData);
            executionCallData = ExecLib.encodeBatch(execution);
        }
        return account.executeFromExecutor(mode, ExecLib.encodeSingle(target, value, callData));
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_EXECUTOR;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) {}

    function isInitialized(address) external pure override returns (bool) {
        return false;
    }
}
