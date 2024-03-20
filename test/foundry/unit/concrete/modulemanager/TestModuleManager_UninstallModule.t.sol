// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import { MockValidator } from "../../../mocks/MockValidator.sol";

/**
 * An event emitted if the UserOperation "callData" reverted with non-zero length.
 * @param userOpHash   - The request unique identifier.
 * @param sender       - The sender of this request.
 * @param nonce        - The nonce used in the request.
 * @param revertReason - The return bytes from the (reverted) call to "callData".
 */
event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

contract TestModuleManager_UninstallModule is Test, SmartAccountTestLab {
    MockValidator public mockValidator;

    function setUp() public {
        init();
        // New copy of mock validator
        // Different address than one already installed as part of smart account deployment
        mockValidator = new MockValidator();
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
        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should be installed"
        );
    }

    function test_UninstallModule_Success() public {
        // Setup: Install the module first
        test_InstallModule_Success(); // Use the test case directly for setup
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed initially"
        );

        (address[] memory array, address next) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);
        address prev = SentinelListHelper.findPrevious(array, remove);
        console2.log("prev is %s ", prev);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR, // Todo: Test what if you pass MODULE_TYPE_EXECUTOR here
            address(mockValidator),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed anymore"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );
    }

    function test_UninstallModule_NotInstalled() public {
        MockValidator newValidatorModule = new MockValidator();
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newValidatorModule), ""),
            "Module should not be installed"
        );

        (address[] memory array, address next) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(newValidatorModule);
        address prev = SentinelListHelper.findPrevious(array, remove);
        console2.log("prev for never installed is %s ", prev);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(newValidatorModule),
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(prev, "")
        );

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)", MODULE_TYPE_VALIDATOR, address(newValidatorModule)
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
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(newValidatorModule), ""),
            "Module should not be installed"
        );
    }

    function test_UninstallModule_IncorrectPrevModuleData() public {
        // Setup: Install the module first
        test_InstallModule_Success(); // Use the test case directly for setup
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed initially"
        );

        (address[] memory array, address next) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(mockValidator);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_VALIDATOR, remove, abi.encode(address(0x66), "")
        );

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

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

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should not be installed"
        );
    }

    function test_UninstallLastValidator_Reverted() public {
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should not be installed initially"
        );

        (address[] memory array, address next) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        console2.log("array length is %s ", array.length);
        address remove = address(VALIDATOR_MODULE);
        address prev = SentinelListHelper.findPrevious(array, remove);
        console2.log("prev for last validator module is %s ", prev);

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_VALIDATOR, remove, abi.encode(prev, "")
        );

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

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
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            "Module should be installed"
        );
    }
}
