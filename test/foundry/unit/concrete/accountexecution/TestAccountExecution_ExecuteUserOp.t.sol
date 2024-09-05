// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestAccountExecution_Base.t.sol";
import "account-abstraction/interfaces/IAccountExecute.sol";

/// @title TestAccountExecution_ExecuteUserOp
/// @notice Unit tests for the executeUserOp function in the Account contract
contract TestAccountExecution_ExecuteUserOp is TestAccountExecution_Base {
    function setUp() public {
        setUpTestAccountExecution_Base();
    }

    /// @notice Ensures the setUp function works as expected
    function test_SetUpState() public {
        // Ensure base setup is correct
        assertEq(counter.getNumber(), 0, "Counter should start at 0");
    }

    /// @notice Tests the executeUserOp function to ensure it correctly executes the user operation
    function test_ExecuteUserOp_ShouldExecute() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Build the inner call data
        bytes memory innerCall =
            prepareERC7579SingleExecuteCallData(EXECTYPE_DEFAULT, address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Build the callData for the user operation
        bytes memory callData = abi.encodePacked(IAccountExecute.executeUserOp.selector, innerCall);

        // Create a PackedUserOperation
        PackedUserOperation memory userOp = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        userOp.callData = callData;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOp);
        bytes memory signature = signMessage(BOB, userOpHash);
        userOp.signature = signature;

        // Prepare the user operations array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Handle operations through EntryPoint
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter was incremented
        assertEq(counter.getNumber(), 1, "Counter should have been incremented after execution");
    }

    /// @notice Tests the executeUserOp function with zero address to ensure it handles this edge case
    function test_ExecuteUserOp_ZeroAddress() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Build the inner call data with zero address
        bytes memory innerCall = abi.encode(address(0), abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Build the callData for the user operation
        bytes memory callData = abi.encodePacked(IAccountExecute.executeUserOp.selector, innerCall);

        // Create a PackedUserOperation
        PackedUserOperation memory userOp = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        userOp.callData = callData;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOp);
        bytes memory signature = signMessage(BOB, userOpHash);
        userOp.signature = signature;

        // Prepare the user operations array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Handle operations through EntryPoint
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter was not incremented
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented with zero address");
    }

    /// @notice Tests the executeUserOp function with empty calldata to ensure it handles this edge case
    function test_ExecuteUserOp_EmptyCalldata() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Build the callData for the user operation with empty calldata
        bytes memory callData = abi.encodePacked(IAccountExecute.executeUserOp.selector);

        // Create a PackedUserOperation
        PackedUserOperation memory userOp = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        userOp.callData = callData;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOp);
        bytes memory signature = signMessage(BOB, userOpHash);
        userOp.signature = signature;

        // Prepare the user operations array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Handle operations through EntryPoint
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter was not incremented
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented with empty calldata");
    }

    /// @notice Tests the executeUserOp function with an invalid signature to ensure it handles this edge case
    function test_RevertIf_ExecuteUserOp_InvalidSignature() public {
        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        // Build the inner call data
        bytes memory innerCall = abi.encode(address(counter), abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Build the callData for the user operation
        bytes memory callData = abi.encodePacked(IAccountExecute.executeUserOp.selector, innerCall);

        // Create a PackedUserOperation
        PackedUserOperation memory userOp = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        userOp.callData = callData;

        // Use an invalid signature
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOp);
        bytes memory invalidSignature = abi.encodePacked(userOpHash); // Not a valid signature
        userOp.signature = invalidSignature;

        // Prepare the user operations array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Handle operations through EntryPoint
        vm.expectRevert();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
