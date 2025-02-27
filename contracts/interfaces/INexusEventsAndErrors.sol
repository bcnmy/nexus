// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";

/// @title Nexus - INexus Events and Errors
/// @notice Defines common errors for the Nexus smart account management interface.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface INexusEventsAndErrors {
    /// @notice Emitted when a user operation is executed from `executeUserOp`
    /// @param userOp The user operation that was executed.
    /// @param innerCallRet The return data from the inner call execution.
    event Executed(PackedUserOperation userOp, bytes innerCallRet);

    /// @notice Error thrown when an unsupported ModuleType is requested.
    /// @param moduleTypeId The ID of the unsupported module type.
    error UnsupportedModuleType(uint256 moduleTypeId);

    /// @notice Error thrown on failed execution.
    error ExecutionFailed();

    /// @notice Error thrown when the Factory fails to initialize the account with posted bootstrap data.
    error NexusInitializationFailed();

    /// @notice Error thrown when a zero address is provided as the Entry Point address.
    error EntryPointCanNotBeZero();

    /// @notice Error thrown when the provided implementation address is invalid.
    error InvalidImplementationAddress();

    /// @notice Error thrown when the provided implementation address is not a contract.
    error ImplementationIsNotAContract();

    /// @notice Error thrown when an inner call fails.
    error InnerCallFailed();

    /// @notice Error thrown when attempted to emergency-uninstall a hook
    error EmergencyTimeLockNotExpired();

    /// @notice Error thrown when attempted to upgrade an ERC7702 account via UUPS proxy upgrade mechanism
    error ERC7702AccountCannotBeUpgradedThisWay();

    /// @notice Error thrown when the provided initData is invalid.
    error InvalidInitData();
}
