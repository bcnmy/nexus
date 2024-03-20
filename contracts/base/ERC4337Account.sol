// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4337Account, PackedUserOperation } from "../interfaces/IERC4337Account.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

abstract contract ERC4337Account is IERC4337Account {
    error AccountAccessUnauthorized();
    /////////////////////////////////////////////////////
    // Access Control
    ////////////////////////////////////////////////////

    modifier onlyEntryPointOrSelf() virtual {
        if (!(msg.sender == entryPoint() || msg.sender == address(this))) {
            revert AccountAccessUnauthorized();
        }
        _;
    }

    modifier onlyEntryPoint() virtual {
        if (msg.sender != entryPoint()) {
            revert AccountAccessUnauthorized();
        }
        _;
    }

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

    /// @inheritdoc IERC4337Account
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual returns (uint256);

    function addDeposit() public payable virtual {
        IEntryPoint(entryPoint()).depositTo{ value: msg.value }(address(this));
    }

    // Review
    // We would need util method to getNonce based on validator as validator gets encoded in the nonce
    function nonce(uint192 key) public view virtual returns (uint256) {
        return IEntryPoint(entryPoint()).getNonce(address(this), key);
    }

    function getDeposit() public view virtual returns (uint256) {
        return IEntryPoint(entryPoint()).balanceOf(address(this));
    }

    function entryPoint() public view virtual returns (address) {
        return 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    }
}
