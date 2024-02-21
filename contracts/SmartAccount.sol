// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { AccountConfig } from "./base/AccountConfig.sol";
import { AccountExecution } from "./base/AccountExecution.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { IAccount, PackedUserOperation } from "./interfaces/IAccount.sol";

contract SmartAccount is AccountConfig, AccountExecution, ModuleManager, IAccount {
    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc IAccount
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData)
    {
        userOp;
        userOpHash;
        missingAccountFunds;
    }
}
