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
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337,
// using Entrypoint version 0.7.0, developed by Biconomy. Learn more at https://biconomy.io/

// Note:
// To be able to compile foundry/mocks for typechain and use in hardhat tests

// solhint-disable-next-line no-unused-import
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
// solhint-disable-next-line no-unused-import
import { MockValidator } from "test/foundry/mocks/MockValidator.sol";
// solhint-disable-next-line no-unused-import
import { Counter } from "test/foundry/mocks/Counter.sol";
// solhint-disable-next-line no-unused-import
import { MockExecutor } from "test/foundry/mocks/MockExecutor.sol";
// solhint-disable-next-line no-unused-import
import { MockHook } from "test/foundry/mocks/MockHook.sol";
// solhint-disable-next-line no-unused-import
import { MockHandler } from "test/foundry/mocks/MockHandler.sol";
