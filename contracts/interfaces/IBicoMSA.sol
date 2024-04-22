// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4337Account } from "./IERC4337Account.sol";
import { IERC7579Account } from "./IERC7579Account.sol";
import { CallType, ExecType } from "../lib/ModeLib.sol";
// IERC1271... (part of IERC7579Account) // hence child may just import custom ERC1271.sol

// BiconomyMSA
interface IBicoMSA is IERC4337Account, IERC7579Account {
    // Error thrown when an unsupported ModuleType is requested
    error UnsupportedModuleType(uint256 moduleTypeId);
    // Error thrown when an execution with an unsupported CallType was made
    error UnsupportedCallType(CallType callType);
    // Error thrown when an execution with an unsupported ExecType was made
    error UnsupportedExecType(ExecType execType);
    // Error thrown when account initialization fails
    error AccountInitializationFailed();
    // Error thrown when account is already initialised
    error AccountAlreadyInitialized();
    // Error thrown on failed execution
    error ExecutionFailed();

    // Review natspec
    /**
     * @dev Initializes the account. Function might be called directly, or by a Factory
     * @param initData. encoded data that can be used during the initialization phase
     */
    function initialize(address firstValidator, bytes calldata initData) external payable;
}
