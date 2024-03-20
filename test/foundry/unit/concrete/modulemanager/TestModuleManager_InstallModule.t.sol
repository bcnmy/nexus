// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import { MockValidator } from "../../../mocks/MockValidator.sol";
import { MockExecutor } from "../../../mocks/MockExecutor.sol";

event ModuleInstalled(uint256 moduleTypeId, address module);

event ModuleUninstalled(uint256 moduleTypeId, address module);

event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

contract TestModuleManager_InstallModule is Test, SmartAccountTestLab {
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;
    address constant INVALID_MODULE_ADDRESS = address(0);
    uint256 constant INVALID_MODULE_TYPE = 999;

    function setUp() public {
        init();
        // New copy of mock validator
        // Different address than one already installed as part of smart account deployment
        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
    }
    
    // TODO:
    // Should be moved in upgrades tests
    function test_upgradeSA() public {
        SmartAccount newSA = new SmartAccount();
        bytes32 slot = ACCOUNT_IMPLEMENTATION.proxiableUUID();
        assertEq(slot, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
        address currentImpl = BOB_ACCOUNT.getImplementation();
        assertEq(currentImpl, address(ACCOUNT_IMPLEMENTATION));

        bytes memory callData = abi.encodeWithSelector(
            IModularSmartAccount.upgradeToAndCall.selector, address(newSA), ""
        );

        // Preparing UserOperation for installing the module
        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

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
        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""),
            "Module should be installed"
        );
    }

    function test_InstallModule_Success_Validator() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );
        _installModule(
            callData, MODULE_TYPE_VALIDATOR, address(mockValidator), "Validator module should be installed successfully"
        );
    }

    function test_InstallModule_Success_Executor() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(mockExecutor), ""
        );
        _installModule(
            callData, MODULE_TYPE_EXECUTOR, address(mockExecutor), "Executor module should be installed successfully"
        );
    }

    function test_InstallModule_Revert_AlreadyInstalled() public {
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

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), ""
        );

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

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

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

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

    function test_InstallModule_InvalidModuleAddress() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR, // Using Validator module type for this test
            address(0), // Invalid module address
            ""
        );

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

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

        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expected revert reason encoded
        bytes memory expectedRevertReason =
            abi.encodeWithSignature("IncompatibleExecutorModule(address)", address(mockValidator));

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function _installModule(
        bytes memory callData,
        uint256 moduleTypeId,
        address moduleAddress,
        string memory message
    )
        private
    {
        PackedUserOperation[] memory userOps =
            prepareExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callData);

        vm.expectEmit(true, true, true, true);
        emit ModuleInstalled(moduleTypeId, moduleAddress);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, moduleAddress, ""), message);
    }

    receive() external payable { } // To allow receiving ether
}
