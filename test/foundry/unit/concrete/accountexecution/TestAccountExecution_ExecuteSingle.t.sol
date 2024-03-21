// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../shared/TestAccountExecution_Base.t.sol"; // Ensure this import path matches your project structure

contract TestAccountExecution_ExecuteSingle is TestAccountExecution_Base {
    function setUp() public {
        setUpTestAccountExecution_Base();
    }

    function test_ExecuteSingle_Success() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Assuming you have a method to prepare a UserOperation for a single execution
        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB, // Assuming `BOB` is defined in your base test setup
            BOB_ACCOUNT, // Assuming `BOB_ACCOUNT` is defined in your base test setup
            EXECTYPE_DEFAULT,
            address(counter),
            0,
            abi.encodeWithSelector(Counter.incrementNumber.selector)
        );

        // Execute the single operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter was incremented
        assertEq(counter.getNumber(), 1, "Counter should have been incremented after single execution");
    }

    function test_ExecuteSingle_Revert() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Assuming you have a method to prepare a UserOperation for a single execution that should fail
        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            address(counter),
            0,
            abi.encodeWithSelector(Counter.revertOperation.selector) // Assuming `revertOperation` causes a revert
        );
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Counter: Revert operation");


        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);

        emit UserOperationRevertReason(
            userOpHash,
            address(BOB_ACCOUNT),
            userOps[0].nonce,
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
    }

    function test_ExecuteSingle_Empty() public {
        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            address(0),
            0,
            ""
        );

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_ExecuteSingle_ValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;

        // Fund BOB_ACCOUNT with 2 ETH to cover the value transfer
        payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund BOB_ACCOUNT


        assertEq(receiver.balance, 0, "Receiver should have 0 ETH");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            receiver,
            sendValue,
            ""
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(receiver.balance, 1 ether, "Receiver should have received 1 ETH");
    }
}
