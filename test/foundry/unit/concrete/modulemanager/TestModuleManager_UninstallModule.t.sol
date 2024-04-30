// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";

contract TestModuleManager_UninstallModule is Test, TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    function test_InstallModule_Success() public {
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed initially"
        );

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Preparing UserOperation for installing the module
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should be installed"
        );
    }

    function test_UninstallModule_Success() public {
        MockValidator newMockValidator = new MockValidator();

        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(newMockValidator), ""
        );
        installModule(installCallData, MODULE_TYPE_VALIDATOR, address(newMockValidator), EXECTYPE_DEFAULT);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newMockValidator), ""),
            "Module should not be installed initially"
        );

        (address[] memory array,) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(mockValidator),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        uninstallModule(callData, EXECTYPE_DEFAULT);

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed anymore"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newMockValidator), ""),
            "Module should be installed"
        );
    }

    function test_UninstallModule_Executor_Success() public {
        MockExecutor newMockExecutor = new MockExecutor();

        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""
        );
        installModule(installCallData, MODULE_TYPE_EXECUTOR, address(newMockExecutor), EXECTYPE_DEFAULT);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""),
            "Module should not be installed initially"
        );

        (address[] memory array,) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
        address remove = address(mockExecutor);
        address prev = SentinelListHelper.findPrevious(array, remove);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(mockExecutor),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        uninstallModule(callData, EXECTYPE_DEFAULT);

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ""),
            "Module should not be installed anymore"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""),
            "Module should be installed"
        );
    }

    function test_UninstallModule_Try_Success() public {
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );

        (address[] memory array,) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR, // TODO: Test what if you pass MODULE_TYPE_EXECUTOR here
            address(VALIDATOR_MODULE),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        bytes memory expectedRevertReason = abi.encodeWithSignature("CannotRemoveLastValidator()");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Similar to installModule but for uninstallation
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
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

    function test_UninstallModule_NotInstalled() public {
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed"
        );

        (address[] memory array,) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(mockValidator),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)", MODULE_TYPE_VALIDATOR, address(mockValidator)
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

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed"
        );
    }

    function test_UninstallExecutorModule_Success() public {
        MockExecutor newMockExecutor = new MockExecutor();

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""),
            "Module should not be installed"
        );

        bytes memory installData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""
        );

        installModule(installData, MODULE_TYPE_EXECUTOR, address(newMockExecutor), EXECTYPE_DEFAULT);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""),
            "Module should be installed"
        );

        (address[] memory array,) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
        address remove = address(newMockExecutor);
        address prev = SentinelListHelper.findPrevious(array, remove);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(newMockExecutor),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""),
            "Module should not be installed"
        );
    }

    function test_UninstallModule_IncorrectPrevModuleData() public {
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

        (address[] memory array,) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_VALIDATOR, remove, abi.encode(address(0x66), "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature("LinkedList_InvalidEntry(address)", remove);

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);

        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Module should still be installed
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed"
        );
    }

    function test_UninstallLastValidator_Reverted() public {
        bytes memory customData = abi.encode(GENERIC_FALLBACK_SELECTOR);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), customData),
            "Module should not be installed initially"
        );

        (address[] memory array,) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(VALIDATOR_MODULE);
        address prev = SentinelListHelper.findPrevious(array, remove);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_VALIDATOR, remove, abi.encode(prev, customData)
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature("CannotRemoveLastValidator()");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);

        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), customData),
            "Module should be installed"
        );
    }

    function test_UninstallFallbackHandler_Success() public {
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should be uninstalled initially"
        );
        installModule(
            abi.encodeWithSelector(
                IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData
            ),
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            EXECTYPE_DEFAULT
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should be installed successfully"
        );
        // Uninstall
        bytes memory callDataUninstall = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData
        );

        Execution[] memory executionUninstall = new Execution[](1);
        executionUninstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataUninstall);

        PackedUserOperation[] memory userOpsUninstall =
            prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionUninstall);
        ENTRYPOINT.handleOps(userOpsUninstall, payable(address(BOB.addr)));

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should be uninstalled successfully"
        );
    }

    function test_UninstallFallbackHandler_NotInstalled() public {
        // Uninstall
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));

        bytes memory callDataUninstall = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData
        );

        Execution[] memory executionUninstall = new Execution[](1);
        executionUninstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataUninstall);

        PackedUserOperation[] memory userOps =
            prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionUninstall);

        bytes memory expectedRevertReason =
            abi.encodeWithSignature("ModuleNotInstalled(uint256,address)", MODULE_TYPE_FALLBACK, address(mockHandler));

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

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should be uninstalled successfully"
        );
    }
}
