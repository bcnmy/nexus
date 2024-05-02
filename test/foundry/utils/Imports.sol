// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Standard library imports
import "forge-std/src/console2.sol";
import "forge-std/src/Test.sol";
import "forge-std/src/Vm.sol";

// Utility libraries
import "solady/src/utils/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
// import "@prb/test/src/PRBTest.sol";

// Account Abstraction imports
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
// import "account-abstraction/contracts/samples/VerifyingPaymaster.sol";

// ModeLib import
import "../../../contracts/lib/ModeLib.sol";
import "../../../contracts/lib/ExecLib.sol";
import "../../../contracts/lib/ModuleTypeLib.sol";

// Interface imports
import "../../../contracts/interfaces/base/IAccountConfig.sol";
import "../../../contracts/interfaces/base/IModuleManager.sol";
import "../../../contracts/interfaces/modules/IModule.sol";
import "../../../contracts/interfaces/base/IStorage.sol";
import "../../../contracts/interfaces/factory/IAccountFactory.sol";
import "../../../contracts/interfaces/INexus.sol";
import "../../../contracts/interfaces/IERC7484Registry.sol";

// Contract implementations
import "../../../contracts/Nexus.sol";
import "../../../contracts/factory/AccountFactory.sol";

// Mock contracts for testing
import "../../../contracts/mocks/MockValidator.sol";
import "../../../contracts/mocks/Counter.sol";
import { MockExecutor } from "../../../contracts/mocks/MockExecutor.sol";
import { MockHandler } from "../../../contracts/mocks/MockHandler.sol";
import { MockHook } from "../../../contracts/mocks/MockHook.sol";
import { MockRegistry } from "../../../contracts/mocks/MockRegistry.sol";
import "../../../contracts/mocks/NFT.sol";

// Sentinel list helper
import { SentinelListLib } from "sentinellist/src/SentinelList.sol";
import { SentinelListHelper } from "sentinellist/src/SentinelListHelper.sol";

// Helper and Struct imports
import "./Helpers.sol";

contract Imports {
// This contract acts as a single point of import for Foundry tests.
// It does not require any logic, as its sole purpose is to consolidate imports.
// You can extend this contract in your test files to access all imported contracts and libraries.
}
