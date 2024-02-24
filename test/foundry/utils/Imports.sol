// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Importing interfaces
import "contracts/interfaces/base/IAccountConfig.sol";
import "contracts/interfaces/base/IAccountExecution.sol";
import "contracts/interfaces/base/IModuleManager.sol";
import "contracts/interfaces/IModule.sol";
import "contracts/interfaces/IStorage.sol";

// Importing contract implementations
import "contracts/base/AccountConfig.sol";
import "contracts/base/AccountExecution.sol";
import "contracts/base/ModuleManager.sol";
import "contracts/SmartAccount.sol";

// Importing Mock contracts
import "contracts/test/mocks/MockValidator.sol";

import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

contract Imports {
// This contract acts as a single point of import for Foundry tests.
// It does not require any logic, as its sole purpose is to consolidate imports.
// You can extend this contract in your test files to access all imported contracts.
}