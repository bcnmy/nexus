// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestAccountExecution_Base.t.sol";

/// @title TestAccountExecution_TryExecuteSingle
/// @notice This contract tests single execution attempts using the try method in the account execution system.
contract TestAccountExecution_TryExecuteSingle is TestAccountExecution_Base {
    /// @notice Sets up the testing environment.
    function setUp() public {
        setUpTestAccountExecution_Base();
    }

    /// @notice Tests successful execution of a single operation.
    function test_TryExecuteSingle_Success() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Asserting the counter was incremented
        assertEq(counter.getNumber(), 1, "Counter should have been incremented");
    }

    /// @notice Tests handling of failed execution.
    function test_RevertIf_TryExecuteSingle_Fails() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
    }

    /// @notice Tests handling of an empty execution.
    function test_TryExecuteSingle_Empty() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(0), 0, "");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests successful value transfer in a single execution.
    function test_TryExecuteSingle_ValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;

        // Fund BOB_ACCOUNT with 2 ETH to cover the value transfer
        (bool res, ) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund BOB_ACCOUNT
        assertEq(res, true, "Funding BOB_ACCOUNT should succeed");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(receiver, sendValue, "");

        assertEq(receiver.balance, 0, "Receiver should have 0 ETH");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(receiver.balance, 1 ether, "Receiver should have received 1 ETH");
    }

    /// @notice Tests successful token transfer in a single execution.
    function test_TryExecuteSingle_TokenTransfer() public {
        uint256 transferAmount = 100 * 10 ** token.decimals();
        // Assuming the Nexus has been funded with tokens in the setUp()

        // Encode the token transfer call
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, CHARLIE.addr, transferAmount));

        // Prepare and execute the UserOperation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB, // Sender of the operation
            BOB_ACCOUNT, // Nexus executing the operation
            EXECTYPE_TRY,
            execution,
            address(VALIDATOR_MODULE),
            0
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify the token transfer
        assertEq(token.balanceOf(CHARLIE.addr), transferAmount, "Tokens were not transferred correctly");
    }

    /// @notice Tests approval and transferFrom operation in a single execution.
    function test_TryExecuteSingle_ApproveAndTransferFrom() public {
        uint256 approvalAmount = 500 * 10 ** token.decimals();
        // Assume BOB_ACCOUNT is approving CHARLIE to spend tokens on its behalf

        // Encode the approve call
        Execution[] memory approvalExecution = new Execution[](1);
        approvalExecution[0] = Execution(address(token), 0, abi.encodeWithSelector(token.approve.selector, CHARLIE.addr, approvalAmount));

        // Prepare and execute the approve UserOperation
        PackedUserOperation[] memory approveOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_TRY,
            approvalExecution,
            address(VALIDATOR_MODULE),
            0
        );

        ENTRYPOINT.handleOps(approveOps, payable(BOB.addr));

        // Now CHARLIE can transfer tokens on behalf of BOB_ACCOUNT
        uint256 transferFromAmount = 200 * 10 ** token.decimals();
        prank(CHARLIE.addr);
        token.transferFrom(address(BOB_ACCOUNT), ALICE.addr, transferFromAmount);

        // Verify the final balances
        assertEq(token.balanceOf(ALICE.addr), transferFromAmount, "TransferFrom did not execute correctly");
        assertEq(token.allowance(address(BOB_ACCOUNT), CHARLIE.addr), approvalAmount - transferFromAmount, "Allowance not updated correctly");
    }

    /// @notice Tests if the TryExecuteUnsuccessful event is emitted correctly when execution fails.
    function test_TryExecuteSingle_EmitTryExecuteUnsuccessful() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

        // Expect the TryExecuteUnsuccessful event to be emitted with specific data
        vm.expectEmit(true, true, true, true);
        emit TryExecuteUnsuccessful(execution[0].callData, abi.encodeWithSignature("Error(string)", "Counter: Revert operation"));

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
    }

    /// @notice Tests if the TryDelegateCallUnsuccessful event is emitted correctly when delegate call execution fails.
    function test_TryExecuteDelegateCall_EmitTryDelegateCallUnsuccessful() public {
        // Create calldata for the account to execute a failing delegate call
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // Build UserOperation for delegate call execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

        // Create delegate call data
        bytes memory userOpCalldata = abi.encodeCall(
            Nexus.execute,
            (
                ModeLib.encode(CALLTYPE_DELEGATECALL, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00)),
                abi.encodePacked(address(counter), execution[0].callData)
            )
        );

        userOps[0].callData = userOpCalldata;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(BOB, userOpHash);

        // Expect the TryDelegateCallUnsuccessful event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TryDelegateCallUnsuccessful(execution[0].callData, abi.encodeWithSignature("Error(string)", "Counter: Revert operation"));

        // Execute the operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
