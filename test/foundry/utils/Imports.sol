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
import "../../../contracts/interfaces/modules/IExecutor.sol";

import "../../../contracts/interfaces/base/IStorage.sol";
import "../../../contracts/interfaces/factory/INexusAccountFactory.sol";
import "../../../contracts/interfaces/INexus.sol";

// Contract implementations
import "../../../contracts/Nexus.sol";
import "../../../contracts/factory/NexusAccountFactory.sol";

// Mock contracts for testing
import "../../../contracts/mocks/Counter.sol";
import { MockInvalidModule } from "./../../../contracts/mocks/MockInvalidModule.sol";

import { MockValidator } from "../../../contracts/mocks/MockValidator.sol";
import { MockExecutor } from "../../../contracts/mocks/MockExecutor.sol";
import { MockHandler } from "../../../contracts/mocks/MockHandler.sol";
import { MockHook } from "../../../contracts/mocks/MockHook.sol";

import "../../../contracts/mocks/NFT.sol";
import "../../../contracts/mocks/MockToken.sol";

// Sentinel list helper
import { SentinelListLib } from "sentinellist/src/SentinelList.sol";
import { SentinelListHelper } from "sentinellist/src/SentinelListHelper.sol";

// Helper and Struct imports
import "./TestHelper.t.sol";

contract Imports {
    // This contract acts as a single point of import for Foundry tests.
    // It does not require any logic, as its sole purpose is to consolidate imports.
}
