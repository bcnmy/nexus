// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../shared/TestAccountExecution_Base.t.sol"; // Ensure this import path matches your project structure

contract TestAccountExecution_ExecuteBatch is TestAccountExecution_Base {
    function setUp() public {
        setUpTestAccountExecution_Base();
    }

    function test_ExecuteBatch_Success() public {
        assertEq(counter.getNumber(), 0, "Counter should start at 0");
        uint256 executionsNumber = 2;

        Execution memory execution = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        Execution[] memory executions = _prepareSeveralIdenticalExecutions(execution, executionsNumber);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(counter.getNumber(), executionsNumber, "Counter value should increment twice after batch execution");
    }

    function test_ExecuteBatch_RevertsWithDefaultExecTypeIfOneOfActionsInBatchReverts() public {
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[1] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // Execute batch operation
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Counter: Revert operation");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(counter.getNumber(), 0, "Counter should remain unchanged after batch execution");
    }

    function test_ExecuteBatch_Empty() public {
        // Initial state assertion
        Execution[] memory executions = _prepareSeveralIdenticalExecutions(Execution(address(counter), 0, ""), 3);
        // Execute batch operation
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        assertEq(counter.getNumber(), 0);
    }

    function test_ExecuteBatch_ValueTransfer() public {
        address receiver = address(0x123);
        assertEq(receiver.balance, 0, "Receiver should have 0 ETH");
        uint256 valueToSend = 1 ether;
        uint256 numberOfExecutions = 3;

        payable(address(BOB_ACCOUNT)).call{ value: valueToSend * numberOfExecutions }(""); // Fund BOB_ACCOUNT
        Execution[] memory executions = _prepareSeveralIdenticalExecutions(Execution(receiver, valueToSend, ""), numberOfExecutions);
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        assertEq(receiver.balance, valueToSend * numberOfExecutions, "Receiver should have received proper amount of ETH");
    }

    function test_ExecuteBatch_TokenTransfers() public {
        uint256 transferAmount = 100 * 10 ** token.decimals();
        // Prepare batch token transfer operations from BOB_ACCOUNT to ALICE and CHARLIE
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, ALICE.addr, transferAmount));
        executions[1] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, CHARLIE.addr, transferAmount));

        // Execute batch operations
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Assertions
        assertEq(token.balanceOf(ALICE.addr), transferAmount, "Alice should receive tokens");
        assertEq(token.balanceOf(CHARLIE.addr), transferAmount, "Charlie should receive tokens");
    }

    function test_ExecuteBatch_ApproveAndTransfer_SeparateOps() public {
        uint256 approvalAmount = 1000 * 10 ** token.decimals();
        uint256 transferAmount = 500 * 10 ** token.decimals();

        uint256 aliceBalanceBefore = token.balanceOf(address(ALICE_ACCOUNT));

        // Execution for approval
        Execution[] memory approvalExecution = new Execution[](1);
        approvalExecution[0] = Execution(address(token), 0, abi.encodeWithSelector(token.approve.selector, address(ALICE_ACCOUNT), approvalAmount));

        // Prepare UserOperation for approval
        PackedUserOperation[] memory approvalUserOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, approvalExecution);

        // Execution for transferFrom
        Execution[] memory transferExecution = new Execution[](1);
        transferExecution[0] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(token.transferFrom.selector, address(BOB_ACCOUNT), address(ALICE_ACCOUNT), transferAmount)
        );

        // Prepare UserOperation for transferFrom
        PackedUserOperation[] memory transferUserOps = preparePackedUserOperation(ALICE, ALICE_ACCOUNT, EXECTYPE_DEFAULT, transferExecution);

        // Combine both user operations into a single array for the EntryPoint to handle
        PackedUserOperation[] memory combinedUserOps = new PackedUserOperation[](2);
        combinedUserOps[0] = approvalUserOps[0];
        combinedUserOps[1] = transferUserOps[0];

        combinedUserOps[0].nonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
        combinedUserOps[1].nonce = getNonce(address(ALICE_ACCOUNT), address(VALIDATOR_MODULE));

        combinedUserOps[0].signature = signUserOp(BOB, combinedUserOps[0]);
        combinedUserOps[1].signature = signUserOp(ALICE, combinedUserOps[1]);

        // Execute both operations
        ENTRYPOINT.handleOps(combinedUserOps, payable(BOB.addr));

        // Asserts to verify the outcome
        uint256 remainingAllowance = token.allowance(address(BOB_ACCOUNT), address(ALICE_ACCOUNT));
        assertEq(remainingAllowance, approvalAmount - transferAmount, "The remaining allowance should reflect the transferred amount");

        uint256 aliceBalanceAfter = token.balanceOf(address(ALICE_ACCOUNT));
        assertEq(aliceBalanceAfter, aliceBalanceBefore + transferAmount, "Alice should receive tokens via transferFrom");
    }

    function test_ExecuteBatch_ApproveAndTransfer_SingleOp() public {
        uint256 approvalAmount = 1000 * 10 ** token.decimals();
        uint256 transferAmount = 500 * 10 ** token.decimals();

        uint256 aliceBalanceBefore = token.balanceOf(address(ALICE_ACCOUNT));

        // Execution for approval
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(token.approve.selector, address(BOB_ACCOUNT), approvalAmount) // BOB_ACCOUNT is
            // approved to transfer
        );

        executions[1] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                address(BOB_ACCOUNT),
                address(ALICE_ACCOUNT),
                transferAmount // Transfer from BOB_ACCOUNT to ALICE ?! Does this make sense?
            )
        );

        // Prepare UserOperation for transferFrom
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        userOps[0].nonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        userOps[0].signature = signUserOp(BOB, userOps[0]);

        // Execute both operations
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserts to verify the outcome
        uint256 remainingAllowance = token.allowance(address(BOB_ACCOUNT), address(BOB_ACCOUNT));
        assertEq(remainingAllowance, approvalAmount - transferAmount, "The remaining allowance should reflect the transferred amount");

        uint256 aliceBalanceAfter = token.balanceOf(address(ALICE_ACCOUNT));
        assertEq(aliceBalanceAfter, aliceBalanceBefore + transferAmount, "Alice should receive tokens via transferFrom");
    }
}
