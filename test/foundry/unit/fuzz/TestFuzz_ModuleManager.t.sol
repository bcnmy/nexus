// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../utils/Imports.sol";
import "../../shared/TestModuleManagement_Base.t.sol";

/// @title TestFuzz_ModuleManager - Fuzz testing for module management functionalities
/// @notice This contract inherits from TestModuleManagement_Base to provide common setup and utilities for fuzz testing
contract TestFuzz_ModuleManager is TestModuleManagement_Base {
    /// @notice Initializes the testing environment
    function setUp() public {
        setUpModuleManagement_Base();
        fixtureModuleAddress();
        fixtureModuleTypeId();
    }

    /// @notice Fuzz test for improper module installation with out-of-bounds parameters
    /// @param randomTypeId The random type ID for the module
    /// @param randomAddress The random address for the module
    function testFuzz_InstallModule_WithInvalidParameters(uint256 randomTypeId, address randomAddress) public {
        // Restrict the type ID and address to ensure they are intentionally incorrect for testing
        vm.assume(randomTypeId < 1000 && randomTypeId > 4); // Exclude valid type ID range
        vm.assume(randomAddress != address(0) && randomAddress != address(mockValidator)); // Exclude zero and known validator address

        // Simulate the erroneous installation attempt with randomized and invalid parameters
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, randomTypeId, randomAddress, "");

        // Prepare the module installation operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // Execute the operation and verify that the module fails to install due to type or address mismatches
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Ensure the module installation is unsuccessful
        assertFalse(BOB_ACCOUNT.isModuleInstalled(randomTypeId, randomAddress, ""), "Module installation should fail with invalid parameters");
    }

    /// @notice Fuzz test for installing fallback handlers with random function selectors
    /// @param selector The random function selector
    function testFuzz_InstallFallbackHandler_WithRandomSelector(bytes4 selector) public {
        vm.assume(selector != bytes4(0x6d61fe70) && selector != bytes4(0x8a91b0e3) && selector != bytes4(0)); // Exclude known selectors
        // Prepare data with a random selector to test dynamic input handling
        bytes memory customData = abi.encode(selector);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );

        // Prepare the module installation operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // Execute and check if the fallback handler installs correctly
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData),
            "Fallback handler should be correctly installed"
        );
    }

    /// @notice Fuzz test for correct module installation based on type
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param funcSig The function signature for the module
    function testFuzz_InstallModule_CorrectType(uint256 moduleTypeId, address moduleAddress, bytes4 funcSig) public {
        // Validate that the module type ID and address are correctly paired
        vm.assume(isValidModuleTypeId(moduleTypeId) && isValidModuleAddress(moduleAddress));
        vm.assume(funcSig != bytes4(0)); // Ensure the function signature is not empty for fallback modules

        // Setup module-specific initialization data
        bytes memory initData = (moduleTypeId == MODULE_TYPE_FALLBACK) ? abi.encode(bytes4(funcSig)) : abi.encode("");

        // Prepare the installation calldata
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, moduleTypeId, moduleAddress, initData);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // Perform the installation and handle possible mismatches
        if (!IModule(moduleAddress).isModuleType(moduleTypeId)) {
            // Expect failure if the module type does not match the expected type ID
            bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId(uint256)", moduleTypeId);
            bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
            vm.expectEmit(true, true, true, true);
            emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        } else {
            // Confirm installation if the module type matches
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
            assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be correctly installed");
        }
    }

    /// @notice Fuzz test for reinstallation of the same module, which should fail
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param funcSig The function signature for the module
    function testFuzz_ReinstallModule_ShouldFail(uint256 moduleTypeId, address moduleAddress, bytes4 funcSig) public {
        // Validate module type, module address and ensure non-empty function signature
        vm.assume(isValidModuleTypeId(moduleTypeId) && isValidModuleAddress(moduleAddress));
        vm.assume(funcSig != bytes4(0));

        bytes memory initData = (moduleTypeId == MODULE_TYPE_FALLBACK) ? abi.encode(bytes4(funcSig)) : abi.encode("");

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, moduleTypeId, moduleAddress, initData);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // First installation should succeed if the module type matches
        if (!IModule(moduleAddress).isModuleType(moduleTypeId)) {
            bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId(uint256)", moduleTypeId);
            bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
            vm.expectEmit(true, true, true, true);
            emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        } else {
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
            assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Initial installation should succeed");

            // Attempt to reinstall the same module should fail
            PackedUserOperation[] memory userOpsSecondAttempt = buildPackedUserOperation(
                BOB,
                BOB_ACCOUNT,
                EXECTYPE_DEFAULT,
                executions,
                address(VALIDATOR_MODULE),
                0
            );
            
            bytes memory expectedRevertReason = abi.encodeWithSignature("LinkedList_EntryAlreadyInList(address)", moduleAddress);
            if(moduleTypeId == MODULE_TYPE_FALLBACK) {
                expectedRevertReason = abi.encodeWithSignature("FallbackAlreadyInstalledForSelector(bytes4)", bytes4(funcSig));
            } else if (moduleTypeId == MODULE_TYPE_HOOK) {
                expectedRevertReason = abi.encodeWithSignature("HookAlreadyInstalled(address)", moduleAddress);
            }

            bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOpsSecondAttempt[0]);
            vm.expectEmit(true, true, true, true);
            emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOpsSecondAttempt[0].nonce, expectedRevertReason);
            ENTRYPOINT.handleOps(userOpsSecondAttempt, payable(BOB.addr));

            // Verify that the reinstallation attempt did not change the installation status
            assertTrue(
                BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData),
                "Module status should remain unchanged after failed reinstallation"
            );
        }
    }

    /// @notice Fuzz test for uninstalling a module
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param funcSig The function signature for the module
    function testFuzz_UninstallModule(uint256 moduleTypeId, address moduleAddress, bytes4 funcSig) public {
        vm.assume(isValidModuleTypeId(moduleTypeId) && isValidModuleAddress(moduleAddress));
        testFuzz_InstallModule_CorrectType(moduleTypeId, moduleAddress, funcSig);

        bytes memory initData = (moduleTypeId == MODULE_TYPE_FALLBACK) ? abi.encode(bytes4(funcSig)) : abi.encode("");
        vm.assume(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData));

        // Ensure the two modules are installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should be installed");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be installed");

        bytes memory callData;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            // Prepare the uninstallation calldata for Validation
            (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
            address remove = moduleAddress;
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, abi.encode(prev, ""));
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            // Prepare the uninstallation calldata for Executor
            (address[] memory array, ) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
            address remove = moduleAddress;
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, abi.encode(prev, ""));
        } else {
            // Prepare the uninstallation calldata for other module types
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, initData);
        }

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        // Verify that the module is uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be uninstalled");
    }

    /// @notice Fuzz test for uninstalling a previously installed module
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param funcSig The function signature for the module
    function testFuzz_UninstallPreviousModule(uint256 moduleTypeId, address moduleAddress, bytes4 funcSig) public {
        vm.assume(isValidModuleTypeId(moduleTypeId) && isValidModuleAddress(moduleAddress));
        testFuzz_InstallModule_CorrectType(moduleTypeId, moduleAddress, funcSig);

        // Install an additional executor module
        bytes memory installExecutorCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(EXECUTOR_MODULE),
            ""
        );
        installModule(installExecutorCallData, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), EXECTYPE_DEFAULT);

        bytes memory initData = (moduleTypeId == MODULE_TYPE_FALLBACK) ? abi.encode(bytes4(funcSig)) : abi.encodePacked("");
        vm.assume(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData));

        // Ensure the modules are installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Validator module should be installed");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(2, address(EXECUTOR_MODULE), ""), "Executor module should be installed");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be installed");

        bytes memory callData;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            // Prepare the uninstallation calldata for Validation
            (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
            address remove = address(VALIDATOR_MODULE);
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, address(VALIDATOR_MODULE), abi.encode(prev, ""));
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            // Prepare the uninstallation calldata for Executor
            (address[] memory array, ) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
            address remove = address(EXECUTOR_MODULE);
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, address(EXECUTOR_MODULE), abi.encode(prev, ""));
        } else {
            // Prepare the uninstallation calldata for other module types
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, initData);
        }

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        // Verify that the module is uninstalled based on the type
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, address(VALIDATOR_MODULE), initData), "Module should be uninstalled");
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, address(EXECUTOR_MODULE), initData), "Module should be uninstalled");
        } else {
            assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be uninstalled");
        }
    }

    /// @notice Fuzz test for uninstalling a module with mismatched type
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param funcSig The function signature for the module
    function testFuzz_UninstallWithMismatchedModuleType(uint256 moduleTypeId, address moduleAddress, bytes4 funcSig) public {
        // Check that the module type and address are valid and the function signature is not empty.
        vm.assume(isValidModuleTypeId(moduleTypeId) && isValidModuleAddress(moduleAddress));
        vm.assume(funcSig != bytes4(0));

        // Initialize data differently based on module type, especially for the fallback type.
        bytes memory initData = (moduleTypeId == MODULE_TYPE_FALLBACK) ? abi.encode(bytes4(funcSig)) : abi.encode("");

        // Preparing different call data for installing all types of modules.
        bytes memory installValidatorCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(mockValidator),
            ""
        );
        bytes memory installExecutorCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(mockExecutor),
            ""
        );
        bytes memory installHandlerCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            abi.encode(bytes4(funcSig))
        );
        bytes memory installHookCallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");

        // Install modules of all types to set up the test environment.
        installModule(installValidatorCallData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_DEFAULT);
        installModule(installExecutorCallData, MODULE_TYPE_EXECUTOR, address(mockExecutor), EXECTYPE_DEFAULT);
        installModule(installHandlerCallData, MODULE_TYPE_FALLBACK, address(mockHandler), EXECTYPE_DEFAULT);
        installModule(installHookCallData, MODULE_TYPE_HOOK, address(mockHook), EXECTYPE_DEFAULT);

        // Prepare call data for uninstallation based on the module type.
        bytes memory callData;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
            address remove = moduleAddress;
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, abi.encode(prev, ""));
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            (address[] memory array, ) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
            address remove = moduleAddress;
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, abi.encode(prev, ""));
        } else {
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, initData);
        }

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // If the module type does not match the installation, expect a revert
        if (!IModule(moduleAddress).isModuleType(moduleTypeId)) {
            bytes memory expectedRevertReason = abi.encodeWithSelector(ModuleNotInstalled.selector, moduleTypeId, moduleAddress);
            bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
            vm.expectEmit(true, true, true, true);
            emit UserOperationRevertReason(
                userOpHash, // userOpHash
                address(BOB_ACCOUNT), // sender
                userOps[0].nonce, // nonce
                expectedRevertReason
            );

            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        } else {
            assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be installed");
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
            assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should be uninstalled");
        }
    }

    /// @notice Fuzz test for uninstalling a non-installed module
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param funcSig The function signature for the module
    function testFuzz_UninstallNonInstalledModule(uint256 moduleTypeId, address moduleAddress, bytes4 funcSig) public {
        vm.assume(isValidModuleTypeId(moduleTypeId) && isValidModuleAddress(moduleAddress));
        vm.assume(funcSig != bytes4(0));
        vm.assume(IModule(moduleAddress).isModuleType(moduleTypeId));

        // Prepare initialization data based on module type
        bytes memory initData = (moduleTypeId == MODULE_TYPE_FALLBACK) ? abi.encode(bytes4(funcSig)) : abi.encode("");
        assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should not be installed initially");

        // Prepare call data for uninstallation
        bytes memory callData;
        if (moduleTypeId == MODULE_TYPE_VALIDATOR) {
            // Retrieve and paginate existing modules to find the correct one to uninstall
            (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
            address remove = moduleAddress;
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, abi.encode(prev, ""));
        } else if (moduleTypeId == MODULE_TYPE_EXECUTOR) {
            // Retrieve and paginate existing modules to find the correct one to uninstall
            (address[] memory array, ) = BOB_ACCOUNT.getExecutorsPaginated(address(0x1), 100);
            address remove = moduleAddress;
            address prev = SentinelListHelper.findPrevious(array, remove);
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, abi.encode(prev, ""));
        } else {
            // Direct uninstallation call for other types without list management
            callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, moduleTypeId, moduleAddress, initData);
        }
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // Expect the uninstallation to fail with a specific revert reason
        bytes memory expectedRevertReason = abi.encodeWithSignature("ModuleNotInstalled(uint256,address)", moduleTypeId, moduleAddress);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        // Verify that the module remains uninstalled after the operation
        assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, initData), "Module should remain uninstalled");
    }

    /// @notice Helper function to check if the provided moduleAddress is valid
    /// @param moduleAddress The address of the module
    /// @return isValid True if the module address is valid
    function isValidModuleAddress(address moduleAddress) internal view returns (bool isValid) {
        address[] memory moduleAddresses = fixtureModuleAddress();
        for (uint i = 0; i < moduleAddresses.length; i++) {
            if (moduleAddresses[i] == moduleAddress) {
                return true;
            }
        }
        return false;
    }

    /// @notice Helper function to check if the provided moduleTypeId is valid
    /// @param typeId The type ID of the module
    /// @return isValid True if the module type ID is valid
    function isValidModuleTypeId(uint256 typeId) internal pure returns (bool isValid) {
        uint[] memory moduleTypeIds = fixtureModuleTypeId();
        for (uint i = 0; i < moduleTypeIds.length; i++) {
            if (moduleTypeIds[i] == typeId) {
                return true;
            }
        }
        return false;
    }

    /// @notice Returns a list of fixture module addresses
    /// @return fixture The array of fixture module addresses
    function fixtureModuleAddress() public view returns (address[] memory) {
        address[] memory fixture = new address[](4);
        fixture[0] = address(mockValidator);
        fixture[1] = address(mockExecutor);
        fixture[2] = address(mockHandler);
        fixture[3] = address(mockHook);
        return fixture;
    }

    /// @notice Returns a list of fixture module type IDs
    /// @return fixture The array of fixture module type IDs
    function fixtureModuleTypeId() public pure returns (uint256[] memory) {
        uint256[] memory fixture = new uint256[](4);
        fixture[0] = 1;
        fixture[1] = 2;
        fixture[2] = 3;
        fixture[3] = 4;
        return fixture;
    }
}
