// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModule } from "./IModule.sol";

interface IHook is IModule {
    function preCheck(
        address msgSender,
        uint256 msgValue,
        bytes calldata msgData
    ) external returns (bytes memory hookData);
    function postCheck(bytes calldata hookData, bool executionSuccess, bytes calldata executionReturnValue) external;
}
