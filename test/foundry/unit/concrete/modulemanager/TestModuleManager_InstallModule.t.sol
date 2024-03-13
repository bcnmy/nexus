// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/BicoTestBase.t.sol";
import { MockValidator } from "../../../mocks/MockValidator.sol";

contract TestModuleManager_InstallModule is Test, BicoTestBase {
    MockValidator public mockValidator;
    SmartAccount public BOB_ACCOUNT;
    uint256 constant MODULE_TYPE_VALIDATOR = 1;
    uint256 constant MODULE_TYPE_EXECUTOR = 2;
    uint256 constant MODULE_TYPE_FALLBACK = 3;
    uint256 constant MODULE_TYPE_HOOK = 4;

    function setUp() public {
        init();
        BOB_ACCOUNT = SmartAccount(deploySmartAccount(BOB));
        mockValidator = new MockValidator();
    }

    function test_InstallModule_Success() public {
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed initially");

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            MODULE_TYPE_VALIDATOR, 
            address(mockValidator), 
            ""
        );

        // Preparing UserOperation for installing the module
        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            ModeLib.encodeSimpleSingle(),
            address(BOB_ACCOUNT),
            0,
            callData
        );

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should be installed");
    }

    function test_InstallModule_Revert_Unauthorized() public {
        // Assuming ALICE is not authorized to perform this action
        vm.expectRevert("Unauthorized");

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            MODULE_TYPE_VALIDATOR, 
            address(mockValidator), 
            ""
        );

        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            ALICE, // Changing the signer to ALICE
            BOB_ACCOUNT,
            ModeLib.encodeSimpleSingle(),
            address(BOB_ACCOUNT),
            0,
            callData
        );

        ENTRYPOINT.handleOps(userOps, payable(address(ALICE.addr)));
    }

    function test_InstallModule_Revert_AlreadyInstalled() public {

        // Setup: Install the module first
        test_InstallModule_Success(); // Use the test case directly for setup
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed initially");


        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            MODULE_TYPE_VALIDATOR, 
            address(mockValidator), 
            ""
        );

        PackedUserOperation[] memory userOpsAgain = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            ModeLib.encodeSimpleSingle(),
            address(BOB_ACCOUNT),
            0,
            callData
        );


        ENTRYPOINT.handleOps(userOpsAgain, payable(address(BOB.addr)));
    }

    // function test_InstallModule_Revert_InvalidModule() public {
    //     vm.expectRevert("InvalidModuleAddress");

    //     bytes memory callData = abi.encodeWithSelector(
    //         IModuleManager.installModule.selector, 
    //         MODULE_TYPE_VALIDATOR, 
    //         address(0), // Invalid module address
    //         ""
    //     );

    //     PackedUserOperation[] memory userOps = prepareExecutionUserOp(
    //         BOB,
    //         BOB_ACCOUNT,
    //         ModeLib.encodeSimpleSingle(),
    //         address(BOB_ACCOUNT),
    //         0,
    //         callData
    //     );

    //     ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    // }

    receive() external payable {} // To allow receiving ether
}
