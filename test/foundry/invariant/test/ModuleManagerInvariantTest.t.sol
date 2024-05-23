// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import { ModuleManagementHandlerTest } from "../handlers/ModuleManagementHandlerTest.t.sol";

/// @title ModuleManagerInvariantTest
/// @notice This contract tests invariants related to the installation and uninstallation of modules in the Nexus system.
contract ModuleManagerInvariantTest is InvariantBaseTest {
    ModuleManagementHandlerTest public handler;
    Nexus public nexusAccount;
    Vm.Wallet public signer;
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;
    MockHandler public mockHandler;
    MockHook public mockHook;

    /// @notice Sets up the test environment by initializing the necessary components and setting up the handler
    function setUp() public override {
        super.setUp();
        signer = newWallet("Signer");
        vm.deal(signer.addr, 100 ether);
        nexusAccount = deployNexus(signer, 1 ether, address(VALIDATOR_MODULE));

        handler = new ModuleManagementHandlerTest(nexusAccount, signer);

        // Setting up the test environment
        vm.deal(address(handler), 100 ether);

        // Define the selectors for the fuzzer to call
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ModuleManagementHandlerTest.invariant_installModule.selector;
        selectors[1] = ModuleManagementHandlerTest.invariant_uninstallModule.selector;

        // Set the fuzzer to only call the specified methods
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));

        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
        mockHandler = new MockHandler();
        mockHook = new MockHook();
    }

    /// @notice Ensures that a module remains installed after a test cycle
    function invariant_moduleInstallation() public {
        assertTrue(
            handler.invariant_checkModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE)),
            "Invariant failed: Module should be installed."
        );
    }

    /// @notice Ensures that a module remains uninstalled after a test cycle
    function invariant_moduleUninstallation() public {
        assertFalse(
            handler.invariant_checkModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor)),
            "Invariant failed: Module should be uninstalled."
        );
    }

    /// @notice Checks the persistent installation of the Validator module
    function invariantTest_ValidatorModuleInstalled() public {
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Validator Module should be consistently installed."
        );
    }

    /// @notice Ensures that no duplicate installations occur
    function invariantTest_NoDuplicateValidatorInstallation() public {
        // Attempt to reinstall the Validator module should revert
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleAlreadyInstalled(uint256,address)",
            MODULE_TYPE_VALIDATOR,
            address(VALIDATOR_MODULE)
        );

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Ensures that non-installed modules are not reported as installed
    function invariantTest_AbsenceOfNonInstalledModules() public {
        // Check that non-installed modules are not mistakenly installed
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ""),
            "Executor Module should not be installed initially."
        );
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ""), "Hook Module should not be installed initially.");
    }
}
