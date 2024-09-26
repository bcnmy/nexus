// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestModuleManagement_Base.t.sol";
import "../../../../../contracts/mocks/MockHook.sol";

/// @title TestNexus_Hook_Uninstall
/// @notice Tests for handling hooks emergency uninstall
contract TestNexus_Hook_Emergency_Uninstall is TestModuleManagement_Base {
    /// @notice Sets up the base module management environment.
    function setUp() public {
        setUpModuleManagement_Base();
    }

    /// @notice Tests the successful installation of the hook module, then tests initiate emergency uninstall.
    function test_EmergencyUninstallHook_Initiate_Success() public {
        // 1. Install the hook

        // Ensure the hook module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should not be installed initially");

        // Prepare call data for installing the hook module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");

        // Install the hook module
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);

        // Assert that the hook module is now installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should be installed");

        uint256 prevTimeStamp = block.timestamp;



        // 2. Request to uninstall the hook
        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, address(HOOK_MODULE), "");

        // Initialize the userOps array with one operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook MUST still be installed");
    }

    function test_EmergencyUninstallHook_Fail_AfterInitiated() public {
        // 1. Install the hook

        // Ensure the hook module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should not be installed initially");

        // Prepare call data for installing the hook module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");

        // Install the hook module
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);

        // Assert that the hook module is now installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should be installed");

        uint256 prevTimeStamp = block.timestamp;



        // 2. Request to uninstall the hook
        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, address(HOOK_MODULE), "");

        // Initialize the userOps array with one operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));


        // 3. Try without waiting for time to pass
        PackedUserOperation[] memory newUserOps = new PackedUserOperation[](1);
        newUserOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        newUserOps[0].callData = emergencyUninstallCalldata;
        bytes32 newUserOpHash = ENTRYPOINT.getUserOpHash(newUserOps[0]);
        newUserOps[0].signature = signMessage(BOB, newUserOpHash);

        bytes memory expectedRevertReason = abi.encodeWithSelector(EmergencyTimeLockNotExpired.selector);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            newUserOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            newUserOps[0].nonce, // nonce
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(newUserOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook MUST still be installed");
    }

    function test_EmergencyUninstallHook_Success_LongAfterInitiated() public {
        // 1. Install the hook

        // Ensure the hook module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should not be installed initially");

        // Prepare call data for installing the hook module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");

        // Install the hook module
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);

        // Assert that the hook module is now installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should be installed");

        uint256 prevTimeStamp = block.timestamp;



        // 2. Request to uninstall the hook
        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, address(HOOK_MODULE), "");

        // Initialize the userOps array with one operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));


        // 3. Wait for time to pass
        // not more than 3 days
        vm.warp(prevTimeStamp + 2 days);

        PackedUserOperation[] memory newUserOps = new PackedUserOperation[](1);
        newUserOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        newUserOps[0].callData = emergencyUninstallCalldata;
        bytes32 newUserOpHash = ENTRYPOINT.getUserOpHash(newUserOps[0]);
        newUserOps[0].signature = signMessage(BOB, newUserOpHash);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit ModuleUninstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE));
        ENTRYPOINT.handleOps(newUserOps, payable(BOB.addr));

        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should not be installed anymore");
    }

    function test_EmergencyUninstallHook_Success_Reset_SuperLongAfterInitiated() public {
        // 1. Install the hook

        // Ensure the hook module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should not be installed initially");

        // Prepare call data for installing the hook module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");

        // Install the hook module
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);

        // Assert that the hook module is now installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should be installed");

        uint256 prevTimeStamp = block.timestamp;



        // 2. Request to uninstall the hook
        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, address(HOOK_MODULE), "");

        // Initialize the userOps array with one operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));


        // 3. Wait for time to pass
        // more than 3 days
        vm.warp(prevTimeStamp + 4 days);

        PackedUserOperation[] memory newUserOps = new PackedUserOperation[](1);
        newUserOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        newUserOps[0].callData = emergencyUninstallCalldata;
        bytes32 newUserOpHash = ENTRYPOINT.getUserOpHash(newUserOps[0]);
        newUserOps[0].signature = signMessage(BOB, newUserOpHash);

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequestReset(address(HOOK_MODULE), block.timestamp);
        ENTRYPOINT.handleOps(newUserOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), "Hook module should still be installed");
    }

}
