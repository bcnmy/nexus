// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../../utils/NexusTest_Base.t.sol";

/// @title ExecutorInvariantTest
/// @notice This contract tests invariants related to the execution of operations by installed and non-installed executors in the Nexus system.
contract ExecutorInvariantTest is NexusTest_Base {
    MockExecutor public validExecutor;
    MockExecutor public invalidExecutor; // Another executor which is not installed

    /// @notice Sets up the test environment by initializing the Nexus account and installing the valid executor module
    function setUp() public {
        init(); // Initialize environment which includes deploying Nexus as BOB_ACCOUNT
        
        // Deploy the executors
        validExecutor = new MockExecutor();
        invalidExecutor = new MockExecutor();

        // Install the valid executor module
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(validExecutor), "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Build the user operation and execute it to install the valid executor
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Invariant to ensure only installed executors can call executeViaAccount
    function invariant_onlyInstalledExecutorCanExecute() public {
        // Attempt to execute via the valid executor
        bytes memory execCallData = abi.encodeWithSelector(MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(0), 0, "");
        (bool success, ) = address(validExecutor).call(execCallData);
        assertTrue(success, "Valid executor should execute successfully.");

        // Attempt to execute via the invalid executor, expecting it to fail
        execCallData = abi.encodeWithSelector(MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(0), 0, "");
        (success, ) = address(invalidExecutor).call(execCallData);
        assertFalse(success, "Invalid executor should not be able to execute.");
    }
}
