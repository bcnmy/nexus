// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";

/**
 * @title TestHookModule
 * @dev Tests for installing and uninstalling the hook module in a smart account.
 */
contract TestModuleManager_HookModule is TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    function test_InstallHookModule_Success() public {
        // Ensure the hook module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should not be installed initially");

        // Prepare call data for installing the hook module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");

        // Install the hook module
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);

        // Assert that the hook module is now installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should be installed");
    }

    function test_InstallHookModule_ReinstallationFailure() public {
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook Module should not be installed initially");
        test_InstallHookModule_Success();
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook Module should be installed");
        MockHook newHook = new MockHook();
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(newHook), ""), "Hook Module should not be installed initially");

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(newHook), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature("HookAlreadyInstalled(address)", address(HOOK_MODULE));

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);

        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_UninstallHookModule_Success() public {
        // Ensure the module is installed first
        test_InstallHookModule_Success();

        // Uninstall the hook module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        uninstallHook(callData, address(HOOK_MODULE), EXECTYPE_DEFAULT);

        // Verify hook module is uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should be uninstalled");
    }

    function test_HookTriggeredOnModuleInstallation() public {
        test_InstallHookModule_Success();
        // Install the hook module to trigger the hooks
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(EXECUTOR_MODULE),
            ""
        );

        // Prepare and execute the installation operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, installCallData);
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        // Expect the PreCheckCalled and PostCheckCalled events to be emitted
        vm.expectEmit(true, true, true, true);
        emit PreCheckCalled();
        vm.expectEmit(true, true, true, true);
        emit PostCheckCalled();

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_InstallHookModule_Success_GetActiveHook() public {
        test_InstallHookModule_Success();
        // Verify the hook module is installed
        address activeHook = BOB_ACCOUNT.getActiveHook();
        assertEq(activeHook, address(HOOK_MODULE), "getActiveHook did not return the correct hook address");
    }

    function uninstallHook(bytes memory callData, address module, ExecType execType) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, execType, execution);

        // Emitting an event to capture the uninstallation attempt for assertion in tests
        vm.expectEmit(true, true, true, true);
        emit ModuleUninstalled(MODULE_TYPE_HOOK, module);

        // Handling the operation which includes calling the uninstallModule function on the smart account
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }
}
