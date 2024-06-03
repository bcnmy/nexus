// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../../shared/TestModuleManagement_Base.t.sol";

contract TestModuleManager_UninstallModule is TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    /// @notice Tests successful installation of a module
    function test_ModuleInstallation_Success() public {
        // Check if the module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed initially");

        // Prepare call data for installing the module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for installing the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Check if the module is installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should be installed");
    }

    /// @notice Tests successful uninstallation of a module
    function test_ModuleUninstallation_Success() public {
        MockValidator newMockValidator = new MockValidator();

        // Install new mock validator module
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(newMockValidator),
            ""
        );
        installModule(installCallData, MODULE_TYPE_VALIDATOR, address(newMockValidator), EXECTYPE_DEFAULT);

        // Install the original mock validator module
        installCallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");
        installModule(installCallData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_DEFAULT);

        // Verify both modules are installed
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newMockValidator), ""),
            "New Mock Module should be installed initially"
        );
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Mock Module should be installed initially");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(VALIDATOR_MODULE);
        address prev = SentinelListHelper.findPrevious(array, remove);
        if (prev == address(0)) prev = address(0x01); // Default to sentinel address if not found

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(VALIDATOR_MODULE),
            abi.encode(prev, "")
        );

        uninstallModule(callData, EXECTYPE_DEFAULT);

        // Verify the module is uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should not be installed anymore");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newMockValidator), ""), "Module should be installed");
    }

    /// @notice Tests successful uninstallation of a newly installed module
    function test_NewModuleUninstallation_Success() public {
        MockValidator newMockValidator = new MockValidator();

        // Install new mock validator module
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(newMockValidator),
            ""
        );
        installModule(installCallData, MODULE_TYPE_VALIDATOR, address(newMockValidator), EXECTYPE_DEFAULT);

        // Verify the module is installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newMockValidator), ""), "Module should be installed initially");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(newMockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(newMockValidator),
            abi.encode(prev, "")
        );

        uninstallModule(callData, EXECTYPE_DEFAULT);

        // Verify the module is uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newMockValidator), ""), "Module should not be installed anymore");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should be installed");
    }

    /// @notice Tests successful uninstallation of an executor module
    function test_ExecutorModuleUninstallation_Success() public {
        MockExecutor newMockExecutor = new MockExecutor();

        // Install new mock executor module
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(newMockExecutor),
            ""
        );
        installModule(installCallData, MODULE_TYPE_EXECUTOR, address(newMockExecutor), EXECTYPE_DEFAULT);

        // Verify the module is installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""), "Module should not be installed initially");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
        address remove = address(mockExecutor);
        address prev = SentinelListHelper.findPrevious(array, remove);

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(mockExecutor),
            abi.encode(prev, "")
        );

        uninstallModule(callData, EXECTYPE_DEFAULT);

        // Verify the module is uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ""), "Module should not be installed anymore");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""), "Module should be installed");
    }

    /// @notice Tests failure to uninstall the last validator module
    function test_RevertIf_UninstallingLastValidator() public {
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should not be installed initially");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);
        if (prev == address(0)) prev = address(0x01); // Default to sentinel address if not found

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(VALIDATOR_MODULE),
            abi.encode(prev, "")
        );

        bytes memory expectedRevertReason = abi.encodeWithSignature("CannotRemoveLastValidator()");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for uninstalling the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Tests uninstallation with incorrect module type
    function test_RevertIf_IncorrectModuleTypeUninstallation() public {
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should not be installed initially");
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);

        // Prepare call data for uninstalling the module with incorrect type
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(VALIDATOR_MODULE),
            abi.encode(prev, "")
        );

        // Define expected revert reason
        bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId(uint256)", MODULE_TYPE_EXECUTOR);

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for uninstalling the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Tests uninstallation of a module that is not installed
    function test_RevertIf_UninstallingNonExistentModule() public {
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should not be installed initially");
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(mockValidator),
            abi.encode(prev, "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for uninstalling the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Define expected revert reason
        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)",
            MODULE_TYPE_VALIDATOR,
            address(mockValidator)
        );

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed");
    }

    /// @notice Tests successful uninstallation of the executor module
    function test_SuccessfulUninstallationOfExecutorModule() public {
        MockExecutor newMockExecutor = new MockExecutor();

        // Verify the module is not installed initially
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""), "Module should not be installed");

        // Prepare call data for installing the module
        bytes memory installData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(newMockExecutor), "");

        // Install the module
        installModule(installData, MODULE_TYPE_EXECUTOR, address(newMockExecutor), EXECTYPE_DEFAULT);

        // Verify the module is installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""), "Module should be installed");

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
        address remove = address(newMockExecutor);
        address prev = SentinelListHelper.findPrevious(array, remove);

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(newMockExecutor),
            abi.encode(prev, "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for uninstalling the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the module is uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(newMockExecutor), ""), "Module should not be installed");
    }

    /// @notice Tests uninstallation with incorrect previous module data
    function test_RevertIf_IncorrectPrevModuleData() public {
        // Setup: Install the module first
        test_ModuleInstallation_Success(); // Use the test case directly for setup
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should be installed initially");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should be installed initially");

        address remove = address(mockValidator);

        // Prepare call data for uninstalling the module with incorrect previous module data
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            remove,
            abi.encode(address(0x66), "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for uninstalling the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Define expected revert reason
        bytes memory expectedRevertReason = abi.encodeWithSignature("LinkedList_InvalidEntry(address)", remove);

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the module is still installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed");
    }

    /// @notice Tests reverting when uninstalling the last validator
    function test_RevertIf_UninstallingLastValidatorModule() public {
        bytes memory customData = abi.encode(GENERIC_FALLBACK_SELECTOR);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), customData),
            "Module should not be installed initially"
        );

        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(VALIDATOR_MODULE);
        address prev = SentinelListHelper.findPrevious(array, remove);

        // Prepare call data for uninstalling the last validator module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            remove,
            abi.encode(prev, customData)
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Prepare the user operation for uninstalling the module
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Define expected revert reason
        bytes memory expectedRevertReason = abi.encodeWithSignature("CannotRemoveLastValidator()");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        // Execute the user operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), customData), "Module should be installed");
    }

    /// @notice Tests successful uninstallation of the fallback handler module
    function test_SuccessfulUninstallationOfFallbackHandler() public {
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should be uninstalled initially"
        );
        installModule(
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData),
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
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            customData
        );

        Execution[] memory executionUninstall = new Execution[](1);
        executionUninstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataUninstall);

        PackedUserOperation[] memory userOpsUninstall = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executionUninstall,
            address(VALIDATOR_MODULE)
        );

        ENTRYPOINT.handleOps(userOpsUninstall, payable(address(BOB.addr)));

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should be uninstalled successfully"
        );
    }

    /// @notice Tests uninstallation of a fallback handler that is not installed
    function test_RevertIf_UninstallingNonExistentFallbackHandler() public {
        // Uninstall
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));

        bytes memory callDataUninstall = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            customData
        );

        Execution[] memory executionUninstall = new Execution[](1);
        executionUninstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataUninstall);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executionUninstall,
            address(VALIDATOR_MODULE)
        );

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)",
            MODULE_TYPE_FALLBACK,
            address(mockHandler)
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

        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData), "FallbackHandler should not be installed");
    }
}
