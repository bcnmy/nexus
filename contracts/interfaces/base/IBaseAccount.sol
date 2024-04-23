// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BaseAccountData
 * @dev Interface for defining common data structures and errors for the BaseAccount.
 */
interface IBaseAccount {
    
    /// @dev Emitted when an unauthorized access attempt occurs.
    error AccountAccessUnauthorized();
}
