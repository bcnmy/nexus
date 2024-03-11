// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4337Account } from "./IERC4337Account.sol";
import { IAccountConfig } from "./base/IAccountConfig.sol";
import { IAccountExecution } from "./base/IAccountExecution.sol";
import { IModuleManager } from "./base/IModuleManager.sol";

import { CallType, ExecType } from "../lib/ModeLib.sol";

interface IModularSmartAccount is IERC4337Account, IAccountConfig, IAccountExecution, IModuleManager {
    // Error thrown when an unsupported ModuleType is requested
    error UnsupportedModuleType(uint256 moduleTypeId);
    // Error thrown when an execution with an unsupported CallType was made
    error UnsupportedCallType(CallType callType);
    // Error thrown when an execution with an unsupported ExecType was made
    error UnsupportedExecType(ExecType execType);
    // Error thrown when account initialization fails
    error AccountInitializationFailed();

    // Review natspec
    /**
     * @dev Initializes the account. Function might be called directly, or by a Factory
     * @param initData. encoded data that can be used during the initialization phase
     */
    function initialize(address firstValidator, bytes calldata initData) external payable;
}
