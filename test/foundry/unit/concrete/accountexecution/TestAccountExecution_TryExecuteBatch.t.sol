// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../shared/TestAccountExecution_Base.t.sol"; // Ensure this import path matches your project structure

contract TestAccountExecution_TryExecuteBatch is TestAccountExecution_Base {
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
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

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
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

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
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function test_TryExecuteBatch_ValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;

        // Fund BOB_ACCOUNT with 10 ETH to cover the value transfer
        payable(address(BOB_ACCOUNT)).call{ value: 10 ether }(""); // Fund BOB_ACCOUNT


        assertEq(receiver.balance, 0, "Receiver should have 0 ETH");

        // Initial state assertion
        Execution[] memory executions = new Execution[](3);

        // Preparing a batch execution with two empty operations
        executions[0] = Execution(receiver, sendValue, "");
        executions[1] = Execution(receiver, sendValue, "");
        executions[2] = Execution(receiver, sendValue, "");

        // Execute batch operation
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(receiver.balance, 3 ether, "Receiver should have received 3 ETH");
    }

    function test_TryExecuteBatch_TokenTransfers() public {
        uint256 transferAmount = 100 * 10 ** token.decimals();
        // Prepare batch token transfer operations from BOB_ACCOUNT to ALICE and CHARLIE
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, ALICE.addr, transferAmount));
        executions[1] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, CHARLIE.addr, transferAmount));

        // Execute batch operations
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Assertions
        assertEq(token.balanceOf(ALICE.addr), transferAmount, "Alice should receive tokens");
        assertEq(token.balanceOf(CHARLIE.addr), transferAmount, "Charlie should receive tokens");
    }

    function test_TryExecuteBatch_ApproveAndTransfer_SeparateOps() public {
        uint256 approvalAmount = 1000 * 10 ** token.decimals();
        uint256 transferAmount = 500 * 10 ** token.decimals();

        uint256 aliceBalanceBefore = token.balanceOf(address(ALICE_ACCOUNT));

        // Execution for approval
        Execution[] memory approvalExecution = new Execution[](1);
        approvalExecution[0] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(token.approve.selector, address(ALICE_ACCOUNT), approvalAmount)
        );

        // Prepare UserOperation for approval
        PackedUserOperation[] memory approvalUserOps = prepareUserOperation(
            BOB, 
            BOB_ACCOUNT, 
            EXECTYPE_TRY, 
            approvalExecution
        );

        // Execution for transferFrom
        Execution[] memory transferExecution = new Execution[](1);
        transferExecution[0] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(token.transferFrom.selector, address(BOB_ACCOUNT), address(ALICE_ACCOUNT), transferAmount)
        );

        // Prepare UserOperation for transferFrom
        PackedUserOperation[] memory transferUserOps = prepareUserOperation(
            ALICE, 
            ALICE_ACCOUNT, 
            EXECTYPE_TRY, 
            transferExecution
        );

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

    function test_TryExecuteBatch_ApproveAndTransfer_SingleOp() public {
        uint256 approvalAmount = 1000 * 10 ** token.decimals();
        uint256 transferAmount = 500 * 10 ** token.decimals();

        uint256 aliceBalanceBefore = token.balanceOf(address(ALICE_ACCOUNT));

        // Execution for approval
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(token.approve.selector, address(BOB_ACCOUNT), approvalAmount)
        );

        executions[1] = Execution(
            address(token),
            0,
            abi.encodeWithSelector(token.transferFrom.selector, address(BOB_ACCOUNT), address(ALICE_ACCOUNT), transferAmount)
        );

        // Prepare UserOperation for transferFrom
        PackedUserOperation[] memory userOps = prepareUserOperation(
            BOB, 
            BOB_ACCOUNT, 
            EXECTYPE_TRY, 
            executions
        );

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
