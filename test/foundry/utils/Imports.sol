// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ==========================
// Standard Library Imports
// ==========================
import "forge-std/console2.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

// ==========================
// Utility Libraries
// ==========================
import "solady/utils/ECDSA.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// ==========================
// Account Abstraction Imports
// ==========================
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import "account-abstraction/interfaces/PackedUserOperation.sol";

// ==========================
// ModeLib Import
// ==========================
import "../../../contracts/lib/ModeLib.sol";
import "../../../contracts/lib/ExecLib.sol";
import "../../../contracts/lib/ModuleTypeLib.sol";

// ==========================
// Interface Imports
// ==========================
import "../../../contracts/interfaces/base/IAccountConfig.sol";
import "../../../contracts/interfaces/base/IModuleManager.sol";
import "../../../contracts/interfaces/modules/IModule.sol";
import "../../../contracts/interfaces/modules/IExecutor.sol";
import "../../../contracts/interfaces/base/IStorage.sol";
import "../../../contracts/interfaces/INexus.sol";

// ==========================
// Contract Implementations
// ==========================
import "../../../contracts/Nexus.sol";
import "../../../contracts/factory/NexusAccountFactory.sol";
import "./../../../contracts/modules/validators/K1Validator.sol";
import "../../../contracts/common/Stakeable.sol";
import "../../../contracts/mocks/ExposedNexus.sol";

// ==========================
// Mock Contracts for Testing
// ==========================
import { MockPaymaster } from "../../../contracts/mocks/MockPaymaster.sol";
import { MockInvalidModule } from "./../../../contracts/mocks/MockInvalidModule.sol";
import { MockExecutor } from "../../../contracts/mocks/MockExecutor.sol";
import { MockHandler } from "../../../contracts/mocks/MockHandler.sol";
import { MockValidator } from "../../../contracts/mocks/MockValidator.sol";
import { MockHook } from "../../../contracts/mocks/MockHook.sol";
import { MockToken } from "../../../contracts/mocks/MockToken.sol";
import { MockMultiModule } from "contracts/mocks/MockMultiModule.sol";
import { MockSafe1271Caller } from "../../../contracts/mocks/MockSafe1271Caller.sol";
import { MockPreValidationHook } from "../../../contracts/mocks/MockPreValidationHook.sol";

import "../../../contracts/mocks/MockNFT.sol";
import "../../../contracts/mocks/Counter.sol";

// ==========================
// Additional Contract Imports
// ==========================
import "contracts/utils/NexusBootstrap.sol";
import "../../../test/foundry/utils/BootstrapLib.sol";
import "../../../contracts/mocks/MockNFT.sol";
import "../../../contracts/mocks/MockToken.sol";

// ==========================
// Sentinel List Helper
// ==========================
import { SentinelListLib } from "sentinellist/SentinelList.sol";
import { SentinelListHelper } from "sentinellist/SentinelListHelper.sol";

// ==========================
// Helper and Struct Imports
// ==========================
import "./TestHelper.t.sol";

contract Imports {
// This contract acts as a single point of import for Foundry tests.
// It does not require any logic, as its sole purpose is to consolidate imports.
}
