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
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

// Magic value for ERC-1271 valid signature
bytes4 constant ERC1271_MAGICVALUE = 0x1626ba7e;

// Value indicating an invalid ERC-1271 signature
bytes4 constant ERC1271_INVALID = 0xFFFFFFFF;

// Value indicating successful validation
uint256 constant VALIDATION_SUCCESS = 0;

// Value indicating failed validation
uint256 constant VALIDATION_FAILED = 1;

// Module type identifier for Multitype install
uint256 constant MODULE_TYPE_MULTI = 0;

// Module type identifier for validators
uint256 constant MODULE_TYPE_VALIDATOR = 1;

// Module type identifier for executors
uint256 constant MODULE_TYPE_EXECUTOR = 2;

// Module type identifier for fallback handlers
uint256 constant MODULE_TYPE_FALLBACK = 3;

// Module type identifier for hooks
uint256 constant MODULE_TYPE_HOOK = 4;
bytes32 constant MODULE_ENABLE_MODE_TYPE_HASH = keccak256("ModuleEnableMode(address module,uint256 moduleType,bytes32 userOpHash,bytes32 initDataHash)");

bytes1 constant MODE_VALIDATION = 0x00;
bytes1 constant MODE_MODULE_ENABLE = 0x01;