// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../shared/TestAccountExecution_Base.t.sol"; // Ensure this import path matches your project structure

contract TestAccountExecution_TryExecuteSingle is TestAccountExecution_Base {
    function setUp() public {
        setUpTestAccountExecution_Base();
    }

    function test_TryExecuteSingle_Success() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Asserting the counter was incremented
        assertEq(counter.getNumber(), 1, "Counter should have been incremented");
    }

    function test_TryExecuteSingle_HandleFailure() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // Assuming you have a method to prepare a UserOperation for a single execution that should fail
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
    }

    function test_TryExecuteSingle_Empty() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(0), 0, "");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_TryExecuteSingle_ValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;

        // Fund BOB_ACCOUNT with 2 ETH to cover the value transfer
        payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund BOB_ACCOUNT

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(receiver, sendValue, "");

        assertEq(receiver.balance, 0, "Receiver should have 0 ETH");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(receiver.balance, 1 ether, "Receiver should have received 1 ETH");
    }

    function test_TryExecuteSingle_TokenTransfer() public {
        uint256 transferAmount = 100 * 10 ** token.decimals();
        // Assuming the Nexus has been funded with tokens in the setUp()

        // Encode the token transfer call
        Execution[] memory execution = new Execution[](1);
        execution[0] =
            Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, CHARLIE.addr, transferAmount));

        // Prepare and execute the UserOperation
        PackedUserOperation[] memory userOps = prepareUserOperation(
            BOB, // Sender of the operation
            BOB_ACCOUNT, // Nexus executing the operation
            EXECTYPE_TRY,
            execution
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify the token transfer
        assertEq(token.balanceOf(CHARLIE.addr), transferAmount, "Tokens were not transferred correctly");
    }

    function test_TryExecuteSingle_ApproveAndTransferFrom() public {
        uint256 approvalAmount = 500 * 10 ** token.decimals();
        // Assume BOB_ACCOUNT is approving CHARLIE to spend tokens on its behalf

        // Encode the approve call
        Execution[] memory approvalExecution = new Execution[](1);
        approvalExecution[0] =
            Execution(address(token), 0, abi.encodeWithSelector(token.approve.selector, CHARLIE.addr, approvalAmount));

        // Prepare and execute the approve UserOperation
        PackedUserOperation[] memory approveOps =
            prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, approvalExecution);

        ENTRYPOINT.handleOps(approveOps, payable(BOB.addr));

        // Now CHARLIE can transfer tokens on behalf of BOB_ACCOUNT
        uint256 transferFromAmount = 200 * 10 ** token.decimals();
        prank(CHARLIE.addr);
        token.transferFrom(address(BOB_ACCOUNT), ALICE.addr, transferFromAmount);

        // Verify the final balances
        assertEq(token.balanceOf(ALICE.addr), transferFromAmount, "TransferFrom did not execute correctly");
        assertEq(
            token.allowance(address(BOB_ACCOUNT), CHARLIE.addr),
            approvalAmount - transferFromAmount,
            "Allowance not updated correctly"
        );
    }
}
