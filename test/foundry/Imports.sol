// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Importing interfaces
import "../../contracts/interfaces/IAccountConfig.sol";
import "../../contracts/interfaces/IExecution.sol";
import "../../contracts/interfaces/IModule.sol";
import "../../contracts/interfaces/IModuleConfig.sol";
import "../../contracts/interfaces/IStorage.sol";

// Importing contract implementations
import "../../contracts/base/AccountConfig.sol";
import "../../contracts/base/Execution.sol";
import "../../contracts/base/ModuleManager.sol";
import "../../contracts/base/Validator.sol";
import "../../contracts/SmartAccount.sol";

import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

contract Imports {
// This contract acts as a single point of import for Foundry tests.
// It does not require any logic, as its sole purpose is to consolidate imports.
// You can extend this contract in your test files to access all imported contracts.
}
