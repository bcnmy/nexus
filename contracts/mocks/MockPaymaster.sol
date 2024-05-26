// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IPaymaster } from "account-abstraction/contracts/interfaces/IPaymaster.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { BasePaymaster } from "account-abstraction/contracts/core/BasePaymaster.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MockPaymaster is BasePaymaster {
    constructor(address _entryPoint) BasePaymaster(IEntryPoint(_entryPoint)) {}

    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal override returns (bytes memory context, uint256 validationData) {
        // Ensure this function is only called by the entry point
        require(msg.sender == address(entryPoint), "Sender not EntryPoint");

        // Context can be empty, indicating no additional data is needed
        context = new bytes(0);

        // validationData format: <20-byte> sigAuthorizer, <6-byte> validUntil, <6-byte> validAfter
        // For simplicity, we'll return a validationData with a valid signature (0), and no time restrictions.
        validationData = uint256(0);
    }

    function _postOp(IPaymaster.PostOpMode mode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas) internal override {
        // For the mock, we don't need to do anything in postOp
        // You can add logging or other state updates here if needed
    }
}
