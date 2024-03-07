// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Standard library imports
import "forge-std/src/console2.sol";
import "forge-std/src/Test.sol";
import "forge-std/src/Vm.sol";

// Utility libraries
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";

// Account Abstraction imports
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

// Interface imports
import "contracts/interfaces/base/IAccountConfig.sol";
import "contracts/interfaces/base/IAccountExecution.sol";
import "contracts/interfaces/base/IModuleManager.sol";
import "contracts/interfaces/modules/IModule.sol";
import "contracts/interfaces/base/IStorage.sol";
import "contracts/interfaces/factory/IAccountFactory.sol";

// Contract implementations
import "contracts/base/AccountConfig.sol";
import "contracts/base/AccountExecution.sol";
import "contracts/base/ModuleManager.sol";
import "contracts/SmartAccount.sol";
import "contracts/factory/AccountFactory.sol";
import "contracts/SmartAccount.sol";

// Mock contracts for testing
import "contracts/test/mocks/MockValidator.sol";
import "contracts/test/mocks/Counter.sol";

// Helper and Struct imports
import "./Structs.sol";
import "./Helpers.sol";

contract Imports {
// This contract acts as a single point of import for Foundry tests.
// It does not require any logic, as its sole purpose is to consolidate imports.
// You can extend this contract in your test files to access all imported contracts and libraries.
}
