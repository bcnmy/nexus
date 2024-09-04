// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../utils/NexusTest_Base.t.sol";
import { ModeLib, ExecutionMode, ExecType, CallType, CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXECTYPE_TRY } from "../../../../contracts/lib/ModeLib.sol";

contract TestFuzz_Execute is NexusTest_Base {
    // Fixture arrays for CallType and ExecType
    CallType[] public fixtureCallType = [CALLTYPE_SINGLE, CALLTYPE_BATCH];
    ExecType[] public fixtureExecType = [EXECTYPE_DEFAULT, EXECTYPE_TRY];

    Counter internal counter;
    MockToken internal token;

    /// @notice Initializes the test environment.
    function setUp() public {
        init(); // Initializes all required contracts and wallets
        counter = new Counter(); // Deploy a new Counter contract
        token = new MockToken("Test Token", "TST"); // Deploy a new MockToken contract
    }

    /// @notice Tests a generic execution with fuzzing.
    /// @param target The target address for the execution.
    /// @param value The ether value to send with the execution.
    /// @param callData The calldata for the execution.
    function testFuzz_GenericExecute(address target, uint256 value, bytes calldata callData) public {
        vm.assume(target != address(0)); // Ensure target is valid

        vm.deal(address(BOB_ACCOUNT), value); // Ensure the account has enough ether

        executeSingle(BOB, BOB_ACCOUNT, target, value, callData, EXECTYPE_DEFAULT);
    }

    /// @notice Tests a single default execution with fuzzing.
    /// @param target The target address for the execution.
    /// @param value The ether value to send with the execution.
    /// @param callData The calldata for the execution.
    function testFuzz_ExecuteSingleDefault(address target, uint256 value, bytes calldata callData) public {
        vm.assume(target != address(0));
        vm.deal(address(BOB_ACCOUNT), value);

        executeSingle(BOB, BOB_ACCOUNT, target, value, callData, EXECTYPE_DEFAULT);
    }

    /// @notice Tests a single try execution with fuzzing.
    /// @param target The target address for the execution.
    /// @param value The ether value to send with the execution.
    /// @param callData The calldata for the execution.
    function testFuzz_ExecuteSingleTry(address target, uint256 value, bytes calldata callData) public {
        vm.assume(target != address(0));
        vm.deal(address(BOB_ACCOUNT), value);

        executeSingle(BOB, BOB_ACCOUNT, target, value, callData, EXECTYPE_TRY);
    }

    /// @notice Tests a batch default execution with fuzzing.
    /// @param executions The array of execution details.
    function testFuzz_ExecuteBatchDefault(Execution[] calldata executions) public {
        vm.assume(executions.length > 0);

        executeBatch(BOB, BOB_ACCOUNT, executions, EXECTYPE_DEFAULT);
    }

    /// @notice Tests a batch try execution with fuzzing.
    /// @param executions The array of execution details.
    function testFuzz_ExecuteBatchTry(Execution[] calldata executions) public {
        vm.assume(executions.length > 0);

        executeBatch(BOB, BOB_ACCOUNT, executions, EXECTYPE_TRY);
    }

    /// @notice Tests incrementing a counter multiple times.
    /// @param numIncrements The number of increments to perform.
    function testFuzz_IncrementCounter(uint256 numIncrements) public {
        vm.assume(numIncrements < 100);

        bytes memory callData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        for (uint256 i = 0; i < numIncrements; i++) {
            executeSingle(BOB, BOB_ACCOUNT, address(counter), 0, callData, EXECTYPE_DEFAULT);
        }
        assertEq(counter.getNumber(), numIncrements, "Counter increments mismatch");
    }

    /// @notice Tests decrementing a counter multiple times.
    /// @param initialCount The initial count of the counter.
    function testFuzz_DecrementCounter(uint256 initialCount) public {
        vm.assume(initialCount < 100);
        testFuzz_IncrementCounter(initialCount);

        uint256 numDecrements = initialCount / 2;

        bytes memory callData = abi.encodeWithSelector(Counter.decrementNumber.selector);
        for (uint256 i = 0; i < numDecrements; i++) {
            executeSingle(BOB, BOB_ACCOUNT, address(counter), 0, callData, EXECTYPE_TRY);
        }
        assertEq(counter.getNumber(), initialCount - numDecrements, "Counter decrements mismatch");
    }

    /// @notice Tests token transfer with fuzzing.
    /// @param to The recipient address.
    /// @param amount The amount of tokens to transfer.
    function testFuzz_TokenTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount < ~uint(0) / 0xff); // Ensure amount is manageable
        vm.assume(token.balanceOf(to) == 0);
        token.mint(address(BOB_ACCOUNT), amount); // Mint tokens to BOB_ACCOUNT

        bytes memory transferCallData = abi.encodeWithSelector(ERC20.transfer.selector, address(to), amount);

        executeSingle(BOB, BOB_ACCOUNT, address(token), 0, transferCallData, EXECTYPE_DEFAULT);

        uint256 finalBalance = token.balanceOf(to);
        assertEq(finalBalance, amount, "Token transfer amount mismatch");
    }

    /// @notice Tests complex token operations with multiple receivers.
    /// @param receivers The array of receiver addresses.
    /// @param amount The amount of tokens to transfer to each receiver.
    function testFuzz_ComplexTokenOperations(address[] calldata receivers, uint256 amount) public {
        vm.assume(receivers.length > 0 && receivers.length < 50);
        vm.assume(amount < ~uint(0) / 0xff); // Ensure baseAmount is manageable

        token.mint(address(BOB_ACCOUNT), amount * receivers.length); // Mint enough tokens to cover all transfers

        Execution[] memory executions = new Execution[](receivers.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bytes memory transferCallData = abi.encodeWithSelector(token.transfer.selector, receivers[i], amount);
            executions[i] = Execution({ target: address(token), value: 0, callData: transferCallData });
        }

        executeBatch(BOB, BOB_ACCOUNT, executions, EXECTYPE_TRY);

        for (uint256 i = 0; i < receivers.length; i++) {
            if (receivers[i] != address(0)) {
                uint256 finalBalance = token.balanceOf(receivers[i]);
                assertGe(finalBalance, amount, "Token transfer amount mismatch for receiver");
            }
        }
    }
}
