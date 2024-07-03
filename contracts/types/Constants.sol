// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

bytes4 constant ERC1271_MAGICVALUE = 0x1626ba7e;
bytes4 constant ERC1271_INVALID = 0xFFFFFFFF;
uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;
uint256 constant MULTITYPE_MODULE = 0;
uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR = 2;
uint256 constant MODULE_TYPE_FALLBACK = 3;
uint256 constant MODULE_TYPE_HOOK = 4;
bytes32 constant MODULE_ENABLE_MODE_TYPE_HASH = keccak256("ModuleEnableMode(address module, bytes32 initDataHash)");

bytes1 constant MODE_VALIDATION = 0x00;
bytes1 constant MODE_MODULE_ENABLE = 0x01;