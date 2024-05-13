// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";

contract TestModuleManager_InstallModule is Test, TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    // TODO:
    // Should be moved in upgrades tests
    function test_upgradeSA() public {
        Nexus newSA = new Nexus();
        bytes32 slot = ACCOUNT_IMPLEMENTATION.proxiableUUID();
        assertEq(slot, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
        address currentImpl = BOB_ACCOUNT.getImplementation();
        assertEq(currentImpl, address(ACCOUNT_IMPLEMENTATION));

        bytes memory callData = abi.encodeWithSelector(Nexus.upgradeToAndCall.selector, address(newSA), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Preparing UserOperation for installing the module
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        address newImpl = BOB_ACCOUNT.getImplementation();
        assertEq(newImpl, address(newSA));
    }

    function test_InstallModule_Success() public {
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed initially"
        );

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        // Preparing UserOperation for installing the module
        installModule(callData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_DEFAULT);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should be installed"
        );
    }

    function test_InstallModule_Try_Success() public {
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed initially"
        );

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        // Preparing UserOperation for installing the module
        installModule(callData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_TRY);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should be installed"
        );
    }

    function test_InstallModule_Success_Validator() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        installModule(callData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_DEFAULT);
    }

    function test_InstallModule_Success_Executor() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), ""
        );
        installModule(callData, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), EXECTYPE_DEFAULT);
    }

    function test_InstallModule_Revert_AlreadyInstalled() public {
        // Setup: Install the module first
        test_InstallModule_Success(); // Use the test case directly for setup
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should be installed initially"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should be installed initially"
        );

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleAlreadyInstalled(uint256,address)", MODULE_TYPE_VALIDATOR, address(mockValidator)
        );

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

    function test_InstallModule_Revert_InvalidModuleTypeId() public {
        MockValidator newMockValidator = new MockValidator();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            99, // Invalid module id
            newMockValidator, // valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId(uint256)", 99);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

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

    function test_InstallModule_InvalidModuleAddress() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR, // Using Validator module type for this test
            address(0), // Invalid module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expected revert reason encoded
        bytes memory expectedRevertReason = abi.encodeWithSignature("ModuleAddressCanNotBeZero()");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    // Installing a module as an executor which does not support executor module type
    function test_InstallModule_IncompatibleModule() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(mockValidator), ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expected revert reason encoded
        bytes memory expectedRevertReason =
            abi.encodeWithSignature("MismatchModuleTypeId(uint256)", MODULE_TYPE_EXECUTOR);

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_InstallModule_Revert_IncompatibleExecutorModule() public {
        MockValidator newMockValidator = new MockValidator();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR, // Invalid module id
            address(newMockValidator), // valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes memory expectedRevertReason =
            abi.encodeWithSignature("MismatchModuleTypeId(uint256)", MODULE_TYPE_EXECUTOR);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

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

    function test_InstallModule_Revert_IncompatibleValidatorModule() public {
        MockExecutor newMockExecutor = new MockExecutor();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR, // Invalid module id
            address(newMockExecutor), // valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes memory expectedRevertReason =
            abi.encodeWithSignature("MismatchModuleTypeId(uint256)", MODULE_TYPE_VALIDATOR);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

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

    function test_InstallFallbackHandler_WithCustomData() public {
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should not be installed initially"
        );

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler with custom data should be installed"
        );
    }

    function test_ReinstallFallbackHandler_Failure() public {
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));
        // First install
        bytes memory callDataFirstInstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData
        );

        Execution[] memory executionFirstInstall = new Execution[](1);
        executionFirstInstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataFirstInstall);

        PackedUserOperation[] memory userOpsFirstInstall =
            preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionFirstInstall);
        ENTRYPOINT.handleOps(userOpsFirstInstall, payable(address(BOB.addr)));

        // Attempt to reinstall
        bytes memory callDataReinstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData
        );

        Execution[] memory executionReinstall = new Execution[](1);
        executionReinstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataReinstall);

        PackedUserOperation[] memory userOps =
            preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionReinstall);

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleAlreadyInstalled(uint256,address)", MODULE_TYPE_FALLBACK, address(mockHandler)
        );

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
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

    function test_InstallHookModule_Success() public {
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ""),
            "Hook module should not be installed initially"
        );

        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ""),
            "Hook module should be installed successfully"
        );
    }

    function test_ReinstallHookModule_Failure() public {
        // Install the hook module first
        test_InstallHookModule_Success();

        // Attempt to reinstall
        bytes memory callDataReinstall =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");

        Execution[] memory executionReinstall = new Execution[](1);
        executionReinstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataReinstall);

        PackedUserOperation[] memory userOps =
            preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionReinstall);

        bytes memory expectedRevertReason =
            abi.encodeWithSignature("ModuleAlreadyInstalled(uint256,address)", MODULE_TYPE_HOOK, address(mockHook));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

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
}
