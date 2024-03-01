// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IEntryPointPatch } from "./IEntryPointPatch.sol";
import "forge-std/src/console2.sol";

contract EntryPointPatch is EntryPoint, IEntryPointPatch {
    event GasSpentInternal(uint256 gasSpent);

    modifier gasEmitter() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = gasStart - gasleft();
        emit GasSpentInternal(gasSpent);
    }

    modifier gasLogger() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = gasStart - gasleft();
        console2.log("Gas spent internal: ", gasSpent);
    }

    function handleOpsEmitGas(PackedUserOperation[] calldata ops, address payable beneficiary) public gasEmitter {
        super.handleOps(ops, beneficiary);
    }

    function handleOpsLogGas(PackedUserOperation[] calldata ops, address payable beneficiary) public gasLogger {
        super.handleOps(ops, beneficiary);
    }
}
