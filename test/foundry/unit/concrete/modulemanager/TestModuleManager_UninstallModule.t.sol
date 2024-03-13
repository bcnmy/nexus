
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/BicoTestBase.t.sol";
import { MockValidator } from "../../../mocks/MockValidator.sol";

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param nonce        - The nonce used in the request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        uint256 nonce,
        bytes revertReason
    );


contract TestModuleManager_UninstallModule is Test, BicoTestBase {
    MockValidator public mockValidator;
    SmartAccount public BOB_ACCOUNT;

    function setUp() public {
        init();
        BOB_ACCOUNT = SmartAccount(deploySmartAccount(BOB));
        // New copy of mock validator
        // Different address than one already installed as part of smart account deployment
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

    function test_UninstallModule_Success() public {

        // Setup: Install the module first
        test_InstallModule_Success(); // Use the test case directly for setup
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""), "Module should not be installed initially");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ""), "Module should not be installed initially");


        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, 
            MODULE_TYPE_VALIDATOR, // Todo: Test what if you pass MODULE_TYPE_EXECUTOR here
            address(mockValidator), 
            // uninstallData needs to provide prev module address with data to uninstall
            abi.encode(VALIDATOR_MODULE,"") 
        );

        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            ModeLib.encodeSimpleSingle(),
            address(BOB_ACCOUNT),
            0,
            callData
        );

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    receive() external payable {} // To allow receiving ether
}
