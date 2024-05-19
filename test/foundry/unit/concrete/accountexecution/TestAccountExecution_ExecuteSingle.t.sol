// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../shared/TestAccountExecution_Base.t.sol";

/// @title TestAccountExecution_ExecuteSingle
/// @notice Tests for single execution in the account execution module
contract TestAccountExecution_ExecuteSingle is TestAccountExecution_Base {
    function setUp() public {
        setUpTestAccountExecution_Base();
    }

    /// @notice Tests successful single execution
    function test_ExecuteSingle_Success() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Execute the single operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter was incremented
        assertEq(counter.getNumber(), 1, "Counter should have been incremented after single execution");
    }

    /// @notice Tests execution with a reverting operation
    function test_RevertIf_ExecuteSingle_Failure() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // The method should fail
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Counter: Revert operation");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
    }

    /// @notice Tests execution with a zero address
    function test_RevertIf_ExecuteSingle_ZeroAddress() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(0), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // The method should fail
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
    }

    /// @notice Tests execution with empty calldata
    function test_ExecuteSingle_Empty_Success() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(0), 0, "");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests value transfer in single execution
    function test_ExecuteSingle_ValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;

        // Fund BOB_ACCOUNT with 2 ETH to cover the value transfer
        (bool res, ) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund BOB_ACCOUNT
        assertEq(res, true, "Funding BOB_ACCOUNT should succeed");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(receiver, sendValue, "");

        assertEq(receiver.balance, 0, "Receiver should have 0 ETH");

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(receiver.balance, 1 ether, "Receiver should have received 1 ETH");
    }

    /// @notice Tests token transfer in single execution
    function test_ExecuteSingle_TokenTransfer() public {
        uint256 transferAmount = 100 * 10 ** token.decimals();
        // Assuming the Nexus has been funded with tokens in the setUp()

        // Encode the token transfer call
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, CHARLIE.addr, transferAmount));

        // Prepare and execute the UserOperation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB, // Sender of the operation
            BOB_ACCOUNT, // Nexus executing the operation
            EXECTYPE_DEFAULT,
            execution,
            address(VALIDATOR_MODULE)
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify the token transfer
        assertEq(token.balanceOf(CHARLIE.addr), transferAmount, "Tokens were not transferred correctly");
    }

    /// @notice Tests approve and transferFrom in single execution
    function test_ExecuteSingle_ApproveAndTransferFrom() public {
        uint256 approvalAmount = 500 * 10 ** token.decimals();
        // Assume BOB_ACCOUNT is approving CHARLIE to spend tokens on its behalf

        // Encode the approve call
        Execution[] memory approvalExecution = new Execution[](1);
        approvalExecution[0] = Execution(address(token), 0, abi.encodeWithSelector(token.approve.selector, CHARLIE.addr, approvalAmount));

        // Prepare and execute the approve UserOperation
        PackedUserOperation[] memory approveOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            approvalExecution,
            address(VALIDATOR_MODULE)
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
}
