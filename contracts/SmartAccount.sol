// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { AccountConfig } from "./Account/AccountConfig.sol";
import { Execution } from "./Account/Execution.sol";
import { ModuleConfig } from "./Account/ModuleConfig.sol";
import { Validator } from "./Account/Validator.sol";

contract SmartAccount is AccountConfig, Execution, ModuleConfig, Validator {
    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }
}
