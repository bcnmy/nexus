// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../../utils/SmartAccountTestLab.t.sol";

contract ExecutorInvariantTest is SmartAccountTestLab {
    MockExecutor public validExecutor;
    MockExecutor public invalidExecutor; // Another executor which is not installed

    function setUp() public {
        init(); // Initialize environment which includes deploying Nexus as BOB_ACCOUNT
        validExecutor = new MockExecutor();
        invalidExecutor = new MockExecutor();

        // Install the valid executor
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(validExecutor), "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    // Invariant to ensure only installed executors can call executeFromExecutor
    function invariant_onlyInstalledExecutorCanExecute() public {
        // Try to execute via the valid executor
        bytes memory execCallData = abi.encodeWithSelector(MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(0), 0, "");
        (bool success, ) = address(validExecutor).call(execCallData);
        assertTrue(success, "Valid executor should execute successfully.");

        // Try to execute via the invalid executor, expecting it to fail
        execCallData = abi.encodeWithSelector(MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(0), 0, "");
        (success, ) = address(invalidExecutor).call(execCallData);
        assertFalse(success, "Invalid executor should not be able to execute.");
    }
}
