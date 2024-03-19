// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";

contract TestAccountExecution_Execute is Test, SmartAccountTestLab {
    ModeCode singleMode;
    ModeCode batchMode;
    ModeCode unsupportedMode;
    Counter counter;

    function setUp() public {
        init();
        singleMode = ModeLib.encodeSimpleSingle();
        batchMode = ModeLib.encodeSimpleBatch();

        // Assume 0x02 is an unsupported CallType for demonstration
        unsupportedMode = ModeLib.encode(CallType.wrap(0x02), EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));
        counter = new Counter();
    }

    function test_ExecuteSingle() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            address(counter),
            0,
            abi.encodeWithSelector(Counter.incrementNumber.selector)
        );

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Asserting the counter was incremented
        assertEq(counter.getNumber(), 1, "Counter should have been incremented");
    }

    function test_ExecuteBatch() public {
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Preparing a batch execution with two operations: increment and decrement
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[1] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Execute batch operation
        PackedUserOperation[] memory userOps = prepareBatchExecutionUserOp(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Assert the counter value remains unchanged after increment and decrement
        assertEq(counter.getNumber(), 2, "Counter value should remain unchanged after batch execution");
    }

    receive() external payable { } // To allow receiving ether
}
