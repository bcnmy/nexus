// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import { ModuleManagementHandlerTest } from "../handlers/ModuleManagementHandlerTest.t.sol";

contract ModuleManagerInvariantTest is InvariantBaseTest {
    ModuleManagementHandlerTest public handler;
    Nexus public nexusAccount;
    Vm.Wallet public signer;
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;
    MockHandler public mockHandler;
    MockHook public mockHook;

    function setUp() public override {
        super.setUp();
        signer = newWallet("Signer");
        vm.deal(signer.addr, 100 ether);
        nexusAccount = deployNexus(signer, 1 ether, address(VALIDATOR_MODULE));

        handler = new ModuleManagementHandlerTest(nexusAccount, signer);

        // Setting up the test environment
        vm.deal(address(handler), 100 ether);
        // targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ModuleManagementHandlerTest.installModule.selector;
        selectors[1] = ModuleManagementHandlerTest.uninstallModule.selector;

        // // Set the fuzzer to only call the specified methods
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));

        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
        mockHandler = new MockHandler();
        mockHook = new MockHook();
    }

    function invariant_moduleInstallation() public {
        // Ensuring a module remains installed after a test cycle
        assertTrue(handler.checkModuleInstalled(1, address(VALIDATOR_MODULE)), "Invariant failed: Module should be installed.");
    }

    function invariant_moduleUninstallation() public {
        // Ensuring a module remains uninstalled after a test cycle
        assertFalse(handler.checkModuleInstalled(1, address(EXECUTOR_MODULE)), "Invariant failed: Module should be uninstalled.");
    }

    /// @notice Invariant to check the persistent installation of the Validator module
    function invariantTest_ValidatorModuleInstalled() public {
        // Validator module should always be installed on BOB_ACCOUNT
        assertTrue(BOB_ACCOUNT.isModuleInstalled(1, address(VALIDATOR_MODULE), ""), "Validator Module should be consistently installed.");
    }

    /// @notice Invariant to ensure that no duplicate installations occur
    function invariantTest_NoDuplicateValidatorInstallation() public {
        // Attempt to reinstall the Validator module should revert
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, 1, address(VALIDATOR_MODULE), "");
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

        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Invariant to ensure that non-installed modules are not reported as installed
    function invariantTest_AbsenceOfNonInstalledModules() public {
        // Check that non-installed modules are not mistakenly installed
        assertFalse(BOB_ACCOUNT.isModuleInstalled(2, address(mockExecutor), ""), "Executor Module should not be installed initially.");
        assertFalse(BOB_ACCOUNT.isModuleInstalled(4, address(mockHook), ""), "Hook Module should not be installed initially.");
    }
}
