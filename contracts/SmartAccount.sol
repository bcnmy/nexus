// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { AccountConfig } from "./base/AccountConfig.sol";
import { AccountExecution } from "./base/AccountExecution.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { IAccount, PackedUserOperation } from "./interfaces/IAccount.sol";
import { IValidator } from "./interfaces/IERC7579Modules.sol";

contract SmartAccount is AccountConfig, AccountExecution, ModuleManager, IAccount {
    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc IAccount
    /// @dev expects IValidator module address to be encoded in the nonce
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData)
    {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }

        // check if validator is enabled. If terminate the validation phase.
        //if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        validationData = IValidator(validator).validateUserOp(userOp, userOpHash);

        //remove
        missingAccountFunds;
    }
}
