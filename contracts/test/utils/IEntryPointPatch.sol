// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

interface IEntryPointPatch is IEntryPoint {
    function handleOpsEmitGas(PackedUserOperation[] calldata ops, address payable beneficiary) external;

    function handleOpsLogGas(PackedUserOperation[] calldata ops, address payable beneficiary) external;
}
