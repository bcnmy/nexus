// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../shared/TestAccountExecution_Base.t.sol"; // Ensure this import path matches your project structure

contract TestAccountExecution_TryExecuteSingle is TestAccountExecution_Base {
    function setUp() public {
        setUpTestAccountExecution_Base();
    }
    function test_TryExecuteBatch_Success() public {
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Preparing a batch execution with three operations: increment, increment, increment
        Execution[] memory executions = new Execution[](3);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[1] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[2] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Execute batch operation
        PackedUserOperation[] memory userOps = prepareBatchExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(counter.getNumber(), 3, "Counter should have been incremented three times in batch execution");
    }

    function test_TryExecuteBatch_HandleFailure() public {
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Preparing a batch execution with three operations: increment, revert, increment
        Execution[] memory executions = new Execution[](3);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[1] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));
        executions[2] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Execute batch operation
        PackedUserOperation[] memory userOps = prepareBatchExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(counter.getNumber(), 2, "Counter should have been incremented even after revert operation in batch execution");
    }

    function test_TryExecuteBatch_Empty() public {
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Preparing a batch execution with three empty operations
        Execution[] memory executions = new Execution[](3);

        executions[0] = Execution(address(0), 0, "");
        executions[1] = Execution(address(0), 0, "");
        executions[2] = Execution(address(0), 0, "");

        // Execute batch operation
        PackedUserOperation[] memory userOps = prepareBatchExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

}
