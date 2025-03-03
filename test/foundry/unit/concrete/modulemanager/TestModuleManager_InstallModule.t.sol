// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../utils/Imports.sol";
import { Solarray } from "solarray/Solarray.sol";
import "../../../utils/NexusTest_Base.t.sol";
import "../../../shared/TestModuleManagement_Base.t.sol";

/// @title TestModuleManager_InstallModule
/// @notice Tests for installing and managing modules in a smart account
contract TestModuleManager_InstallModule is TestModuleManagement_Base {
    /// @notice Sets up the base environment for the module management tests
    function setUp() public {
        setUpModuleManagement_Base();
    }

    /// @notice Tests successful installation of a module
    function test_InstallModule_Success() public {
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed initially");

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");

        installModule(callData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_DEFAULT);

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should be installed");
    }

    /// @notice Tests successful installation of a module with 'Try' execution type
    function test_InstallModule_TrySuccess() public {
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed initially");

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");

        installModule(callData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_TRY);

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should be installed");
    }

    /// @notice Tests successful installation of a validator module
    function test_InstallValidatorModule_Success() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");

        installModule(callData, MODULE_TYPE_VALIDATOR, address(mockValidator), EXECTYPE_DEFAULT);
    }

    /// @notice Tests successful installation of an executor module
    function test_InstallExecutorModule_Success() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");
        installModule(callData, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), EXECTYPE_DEFAULT);
    }

    /// @notice Tests reversion when trying to install an already installed module
    function test_RevertIf_ModuleAlreadyInstalled() public {
        // Setup: Install the module first
        test_InstallModule_Success(); // Use the test case directly for setup
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should be installed initially");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should be installed initially");

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "LinkedList_EntryAlreadyInList(address)", address(mockValidator)
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

    function test_InstallModule_MultiTypeInstall() public {

        bytes32 validatorConfig = bytes32(uint256(0x1111));
        bytes32 executorConfig = bytes32(uint256(0x2222));
        bytes32 fallbackConfig = bytes32(uint256(0x3333));
        bytes32 hookConfig = bytes32(uint256(0x4444));

        bytes memory validatorInstallData = abi.encodePacked(
            bytes1(uint8(MODULE_TYPE_VALIDATOR)),
            validatorConfig
        );

        bytes memory executorInstallData = abi.encodePacked(
            bytes1(uint8(MODULE_TYPE_EXECUTOR)),
            executorConfig
        );

        bytes memory fallbackInstallData = abi.encodePacked(
            bytes4(GENERIC_FALLBACK_SELECTOR), 
            CALLTYPE_SINGLE,
            bytes1(uint8(MODULE_TYPE_FALLBACK)),
            fallbackConfig
        );

        bytes memory hookInstallData = abi.encodePacked(
            bytes1(uint8(MODULE_TYPE_HOOK)),
            hookConfig
        );

        uint256[] memory types = Solarray.uint256s(MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, MODULE_TYPE_FALLBACK, MODULE_TYPE_HOOK);
        bytes[] memory initDatas = Solarray.bytess(validatorInstallData, executorInstallData, fallbackInstallData, hookInstallData);

        bytes memory multiInstallData = abi.encode(
            types,
            initDatas
        );

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_MULTI, address(mockMulti), multiInstallData
        );

        installModule(callData, MODULE_TYPE_MULTI, address(mockMulti), EXECTYPE_DEFAULT);

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockMulti), ""),
            "Module should be installed as validator"
        );
        assertEq(
            mockMulti.getConfig(address(BOB_ACCOUNT), MODULE_TYPE_VALIDATOR),
            validatorConfig,
            "Module should be properly configured as validator"
        );

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockMulti), ""),
            "Module should be installed as executor"
        );
        assertEq(
            mockMulti.getConfig(address(BOB_ACCOUNT), MODULE_TYPE_EXECUTOR),
            executorConfig,
            "Module should be properly configured as executor"
        );

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockMulti), abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR))),
            "Module should be installed as fallback"
        );
        assertEq(
            mockMulti.getConfig(address(BOB_ACCOUNT), MODULE_TYPE_FALLBACK),
            fallbackConfig,
            "Module should be properly configured as fallback"
        );

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockMulti), ""),
            "Module should be installed as hook"
        );
        assertEq(
            mockMulti.getConfig(address(BOB_ACCOUNT), MODULE_TYPE_HOOK),
            hookConfig,
            "Module should be properly configured as hook"
        );

    }

    /// @notice Tests reversion when trying to install a module with an invalid module type ID
    function test_RevertIf_InvalidModuleTypeId() public {
        MockValidator newMockValidator = new MockValidator();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            99, // Invalid module id
            newMockValidator, // valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes memory expectedRevertReason = abi.encodeWithSignature("InvalidModuleTypeId(uint256)", 99);
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

    /// @notice Tests reversion when trying to install a module with an invalid module address
    function test_RevertIf_InvalidModuleAddress() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR, // Using Validator module type for this test
            address(0), // Invalid module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expected revert reason encoded
        bytes memory expectedRevertReason = abi.encodeWithSignature("ModuleAddressCanNotBeZero()");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests reversion when trying to install an incompatible module as an executor
    function test_RevertIf_IncompatibleModuleAsExecutor() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(mockValidator), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expected revert reason encoded
        bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId()");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests reversion when trying to install an incompatible executor module
    function test_RevertIf_IncompatibleExecutorModule() public {
        MockValidator newMockValidator = new MockValidator();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR, // Invalid module type
            address(newMockValidator), // Valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId()");
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

    /// @notice Tests reversion when trying to install an incompatible validator module
    function test_RevertIf_IncompatibleValidatorModule() public {
        MockExecutor newMockExecutor = new MockExecutor();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR, // Invalid module type
            address(newMockExecutor), // Valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes memory expectedRevertReason = abi.encodeWithSignature("MismatchModuleTypeId()");
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

    /// @notice Tests installing a fallback handler with custom data
    function test_InstallFallbackHandler_WithCustomData() public {
        bytes memory customData = abi.encodePacked(
                bytes4(GENERIC_FALLBACK_SELECTOR), 
                CALLTYPE_SINGLE,
                "0x0000"
            );
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler should not be installed initially"
        );

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData);

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData),
            "FallbackHandler with custom data should be installed"
        );
    }

    /// @notice Tests reversion when trying to reinstall an already installed fallback handler
    function test_RevertIf_ReinstallFallbackHandler() public {
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));

        // First install
        bytes memory callDataFirstInstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            customData
        );

        Execution[] memory executionFirstInstall = new Execution[](1);
        executionFirstInstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataFirstInstall);

        PackedUserOperation[] memory userOpsFirstInstall = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executionFirstInstall,
            address(VALIDATOR_MODULE),
            0
        );
        ENTRYPOINT.handleOps(userOpsFirstInstall, payable(address(BOB.addr)));

        // Attempt to reinstall
        bytes memory callDataReinstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            customData
        );

        Execution[] memory executionReinstall = new Execution[](1);
        executionReinstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataReinstall);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executionReinstall,
            address(VALIDATOR_MODULE),
            0
        );

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "FallbackAlreadyInstalledForSelector(bytes4)", bytes4(GENERIC_FALLBACK_SELECTOR)
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

    /// @notice Tests successful installation of a hook module
    function test_InstallHookModule_Success() public {
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ""), "Hook module should not be installed initially");

        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ""), "Hook module should be installed successfully");
    }

    /// @notice Tests reversion when trying to reinstall an already installed hook module
    function test_RevertIf_ReinstallHookModule() public {
        // Install the hook module first
        test_InstallHookModule_Success();

        // Attempt to reinstall
        bytes memory callDataReinstall = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");

        Execution[] memory executionReinstall = new Execution[](1);
        executionReinstall[0] = Execution(address(BOB_ACCOUNT), 0, callDataReinstall);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executionReinstall,
            address(VALIDATOR_MODULE),
            0
        );

        bytes memory expectedRevertReason =
            abi.encodeWithSignature(
                "HookAlreadyInstalled(address)", address(mockHook)
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

    /// @notice Tests reversion when trying to install a module with an invalid type ID
    function test_RevertIf_InvalidModuleWithInvalidTypeId() public {
        MockInvalidModule newMockInvalidModule = new MockInvalidModule();
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            99, // Invalid module id
            newMockInvalidModule, // valid new module address
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes memory expectedRevertReason = abi.encodeWithSelector(InvalidModuleTypeId.selector, 99);
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
