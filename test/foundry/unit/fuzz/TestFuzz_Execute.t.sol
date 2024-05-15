// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/SmartAccountTestLab.t.sol";
import { ModeLib, ExecutionMode, ExecType, CallType, CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXECTYPE_TRY } from "../../../../contracts/lib/ModeLib.sol";

contract TestFuzz_Execute is SmartAccountTestLab {
    // Fixture arrays for CallType and ExecType
    CallType[] public fixtureCallType = [CALLTYPE_SINGLE, CALLTYPE_BATCH];
    ExecType[] public fixtureExecType = [EXECTYPE_DEFAULT, EXECTYPE_TRY];
    address public userAddress = address(BOB.addr);
    Counter internal counter;
    MockToken internal token;
    function setUp() public {
        init(); // Initializes all required contracts and wallets
        counter = new Counter(); // Deploy a new Counter contract
        token = new MockToken("Test Token", "TST"); // Deploy a new MockToken contract
    }

    function testFuzz_Execute(address target, uint256 value, bytes calldata callData) public {
        vm.assume(target != address(0)); // Ensure target is valid

        vm.deal(address(BOB_ACCOUNT), value); // Ensure the account has enough ether

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: target, value: value, callData: callData });

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function testFuzz_ExecuteSingleDefault(address target, uint256 value, bytes calldata callData) public {
        vm.assume(target != address(0));
        vm.deal(address(BOB_ACCOUNT), value);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: target, value: value, callData: callData });

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function testFuzz_ExecuteSingleTry(address target, uint256 value, bytes calldata callData) public {
        vm.assume(target != address(0));
        vm.deal(address(BOB_ACCOUNT), value);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: target, value: value, callData: callData });

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function testFuzz_ExecuteBatchDefault(Execution[] calldata executions) public {
        vm.assume(executions.length > 0);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function testFuzz_ExecuteBatchTry(Execution[] calldata executions) public {
        vm.assume(executions.length > 0);
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function testFuzz_ExecuteIncrement(uint256 numIncrements) public {
        vm.assume(numIncrements < 100);

        bytes memory callData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        for (uint256 i = 0; i < numIncrements; i++) {
            Execution[] memory executions = new Execution[](1);
            executions[0] = Execution({ target: address(counter), value: 0, callData: callData });

            PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        }
        assertEq(counter.getNumber(), numIncrements, "Counter increments mismatch");
    }

    function testFuzz_ExecuteDecrement(uint256 initialCount) public {
        vm.assume(initialCount < 100);
        testFuzz_ExecuteIncrement(initialCount);

        uint256 numDecrements = initialCount / 2;

        bytes memory callData = abi.encodeWithSelector(Counter.decrementNumber.selector);
        for (uint256 i = 0; i < numDecrements; i++) {
            Execution[] memory executions = new Execution[](1);
            executions[0] = Execution({ target: address(counter), value: 0, callData: callData });

            PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        }
        assertEq(counter.getNumber(), initialCount - numDecrements, "Counter decrements mismatch");
    }

    function testFuzz_TokenTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount < ~uint(0) / 0xff); // Ensure amount is manageable
        token.mint(address(BOB_ACCOUNT), amount); // Mint tokens to BOB_ACCOUNT
        // Set up the transfer operation
        bytes memory transferCallData = abi.encodeWithSelector(ERC20.transfer.selector, address(to), amount);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(token), value: 0, callData: transferCallData });

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Check final balances to ensure transfer was successful
        uint256 finalBalance = token.balanceOf(to);
        assertEq(finalBalance, amount, "Token transfer amount mismatch");
    }

    function testFuzz_ComplexTokenOperations(address[] calldata receivers, uint256 amount) public {
        vm.assume(receivers.length > 0 && receivers.length < 50);
        vm.assume(amount < ~uint(0) / 0xff); // Ensure baseAmount is manageable

        // Ensure BOB_ACCOUNT has enough tokens to transfer
        token.mint(address(BOB_ACCOUNT), amount * receivers.length); // Mint enough tokens to cover all transfers

        Execution[] memory executions = new Execution[](receivers.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bytes memory transferCallData = abi.encodeWithSelector(token.transfer.selector, receivers[i], amount);
            executions[i] = Execution({ target: address(token), value: 0, callData: transferCallData });
        }

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Optionally verify the results for each receiver
        for (uint256 i = 0; i < receivers.length; i++) {
            if (receivers[i] != address(0)) {
                uint256 finalBalance = token.balanceOf(receivers[i]);
                assertGe(finalBalance, amount, "Token transfer amount mismatch for receiver");
            }
        }
    }
}
