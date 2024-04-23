// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { IBaseAccount } from "../interfaces/base/IBaseAccount.sol";

// has ERC-4337-v-0.7 implementations
// houses ERC7579 config implementations
// houses access control

/**
 * @title BaseAccount
 * @dev Base contract housing methods specific to ERC4337 and some of ERC7579 configuration
 * @author zeroknots.eth | rhinestone.wtf, chirag@biconomy.io
 * shoutout to solady (vectorized, ross) for this code
 */
contract BaseAccount is IBaseAccount {
    /// @notice Identifier for this implementation on the network
    string internal constant _ACCOUNT_IMPLEMENTATION_ID = "biconomy.modular-smart-account.1.0.0-alpha";

    /// @notice The canonical address for the ERC4337 EntryPoint contract, version 0.7.
    /// This address is consistent across all supported networks.
    address private constant _ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    /// @dev Ensures the caller is either the EntryPoint or this contract itself.
    /// Reverts with AccountAccessUnauthorized if the check fails.
    modifier onlyEntryPointOrSelf() {
        if (msg.sender != _ENTRYPOINT && msg.sender != address(this)) {
            revert AccountAccessUnauthorized();
        }
        _;
    }

    /// @dev Ensures the caller is the EntryPoint.
    /// Reverts with AccountAccessUnauthorized if the check fails.
    modifier onlyEntryPoint() {
        if (msg.sender != _ENTRYPOINT) {
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

    /// @notice Retrieves the address of the EntryPoint contract, currently using version 0.7.
    /// @dev This function returns the address of the canonical ERC4337 EntryPoint contract.
    /// It can be overridden to return a different EntryPoint address if needed.
    /// @return The address of the EntryPoint contract.
    function entryPoint() external pure returns (address) {
        return _ENTRYPOINT;
    }

    /// @notice Gets the nonce for a particular key.
    /// @param key The nonce key.
    /// @return The nonce associated with the key.
    function nonce(uint192 key) external view virtual returns (uint256) {
        return IEntryPoint(_ENTRYPOINT).getNonce(address(this), key);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     DEPOSIT OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Returns the current deposit balance of this account on the EntryPoint.
    /// @return result The current balance held at the EntryPoint.
    function getDeposit() external view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, address()) // Store the `account` argument.
            mstore(0x00, 0x70a08231) // `balanceOf(address)`.
            result := mul(
                // Returns 0 if the EntryPoint does not exist.
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), _ENTRYPOINT, 0x1c, 0x24, 0x20, 0x20)
                )
            )
        }
    }

    /// @notice Adds deposit to the EntryPoint to fund transactions.
    function addDeposit() external payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // The EntryPoint has balance accounting logic in the `receive()` function.
            if iszero(
                mul(extcodesize(_ENTRYPOINT), call(gas(), _ENTRYPOINT, callvalue(), codesize(), 0x00, codesize(), 0x00))
            ) {
                revert(codesize(), 0x00) // For gas estimation.
            }
        }
    }

    /// @notice Withdraws ETH from the EntryPoint to a specified address.
    /// @param to The address to receive the withdrawn funds.
    /// @param amount The amount to withdraw.
    function withdrawDepositTo(address to, uint256 amount) external payable virtual onlyEntryPointOrSelf {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x205c2878000000000000000000000000) // `withdrawTo(address,uint256)`.
            if iszero(mul(extcodesize(_ENTRYPOINT), call(gas(), _ENTRYPOINT, 0, 0x10, 0x44, codesize(), 0x00))) {
                returndatacopy(mload(0x40), 0x00, returndatasize())
                revert(mload(0x40), returndatasize())
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }
}
