// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModule } from "./IModule.sol";

struct Execution {
    address target;
    uint256 value;
    bytes callData;
}

interface IExecutor is IModule {
    // solhint-disable-previous-line no-empty-blocks
}
