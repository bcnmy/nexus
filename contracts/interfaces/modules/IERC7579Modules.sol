// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IValidator } from "./IValidator.sol";
import { IExecutor } from "./IExecutor.sol";
import { IFallback } from "./IFallback.sol";
import { IHook } from "./IHook.sol";

uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;

uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR = 2;
uint256 constant MODULE_TYPE_FALLBACK = 3;
uint256 constant MODULE_TYPE_HOOK = 4;

// TODO // Review
interface IERC7579Modules is IValidator, IExecutor, IFallback, IHook {
    // solhint-disable-previous-line no-empty-blocks
}
