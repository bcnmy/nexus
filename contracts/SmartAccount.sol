// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { AccountConfig } from "./base/AccountConfig.sol";
import { AccountExecution } from "./base/AccountExecution.sol";
import { ModuleManager } from "./base/ModuleManager.sol";
import { IAccount, PackedUserOperation } from "./interfaces/IAccount.sol";
import { IValidator } from "./interfaces/IERC7579Modules.sol";

contract SmartAccount is AccountConfig, AccountExecution, ModuleManager, IAccount {
    /// @dev Sends to the EntryPoint (i.e. `msg.sender`) the missing funds for this transaction.
    /// Subclass MAY override this modifier for better funds management.
    /// (e.g. send to the EntryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    ///
    /// `missingAccountFunds` is the minimum value this modifier should send the EntryPoint,
    /// which MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    modifier payPrefund(uint256 missingAccountFunds) virtual {
        _;
        /// @solidity memory-safe-assembly
        assembly {
            if missingAccountFunds {
                // Ignore failure (it's EntryPoint's job to verify, not the account's).
                pop(call(gas(), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
            }
        }
    }

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
        virtual
        payPrefund(missingAccountFunds)
        returns (uint256)
    {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }
        // check if validator is enabled. If terminate the validation phase.
        //if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        uint256 validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
        return validationData;
    }
}
