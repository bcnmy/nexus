// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { SentinelListLib } from "sentinellist/src/SentinelList.sol";

import { IHook } from "../modules/IHook.sol";
import { CallType } from "../../lib/ModeLib.sol";

/// @title Nexus - IStorage Interface
/// @notice Provides structured storage for Modular Smart Account under the Nexus suite, compliant with ERC-7579 and ERC-4337.
/// @dev Manages structured storage using SentinelListLib for validators and executors, and a mapping for fallback handlers.
/// This interface utilizes ERC-7201 storage location practices to ensure isolated and collision-resistant storage spaces within smart contracts.
/// It is designed to support dynamic execution and modular management strategies essential for advanced smart account architectures.
/// @custom:storage-location erc7201:biconomy.storage.Nexus
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
interface IStorage {
    /// @notice Struct storing validators and executors using Sentinel lists, and fallback handlers via mapping.
    struct AccountStorage {
        SentinelListLib.SentinelList validators; ///< List of validators, initialized upon contract deployment.
        SentinelListLib.SentinelList executors; ///< List of executors, similarly initialized.
        mapping(bytes4 => FallbackHandler) fallbacks; ///< Mapping of selectors to their respective fallback handlers.
        IHook hook; ///< Current hook module associated with this account.
    }

    /// @notice Defines a fallback handler with an associated handler address and a call type.
    struct FallbackHandler {
        address handler; ///< The address of the fallback function handler.
        CallType calltype; ///< The type of call this handler supports (e.g., static or delegatecall).
    }
}
