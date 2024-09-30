// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../utils/NexusTest_Base.t.sol";

/// @title TestFuzz_ExecuteFromExecutor
/// @notice This contract tests various functionalities executed from a MockExecutor in fuzzing scenarios
contract TestFuzz_ExecuteFromExecutor is NexusTest_Base {
    MockExecutor public mockExecutor;
    Counter public counter;
    MockToken public token;

    /// @notice Sets up the environment before each test
    function setUp() public {
        init(); // Initializes all required contracts and wallets
        mockExecutor = new MockExecutor();
        counter = new Counter();
        token = new MockToken("Test Token", "TST");

        // Install MockExecutor as an executor module on BOB_ACCOUNT
        bytes memory installExecModuleData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(mockExecutor),
            ""
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution({ target: address(BOB_ACCOUNT), value: 0, callData: installExecModuleData });

        PackedUserOperation[] memory userOpsInstall = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            execution,
            address(VALIDATOR_MODULE),
            0
        );
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));

        require(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ""), "Executor module installation failed.");
    }

    /// @notice Fuzz test for executing a single operation from the executor
    /// @param target The target address for the execution
    /// @param value The value to be transferred in the execution
    function testFuzz_ExecuteSingleFromExecutor(address target, uint256 value) public {
        vm.assume(uint160(address(target)) > 10);
        vm.assume(!isContract(target));
        vm.assume(value < 1_000_000_000 ether);
        vm.deal(address(BOB_ACCOUNT), value);

        // Execute a single operation via MockExecutor directly without going through ENTRYPOINT.handleOps
        mockExecutor.executeViaAccount(BOB_ACCOUNT, target, value, "");
    }

    /// @notice Fuzz test for incrementing the counter multiple times
    /// @param numIncrements The number of times to increment the counter
    function testFuzz_ExecuteIncrementCounter(uint256 numIncrements) public {
        vm.assume(numIncrements < 100);
        bytes memory callData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        for (uint256 i = 0; i < numIncrements; i++) {
            mockExecutor.executeViaAccount(BOB_ACCOUNT, address(counter), 0, callData);
        }
        assertEq(counter.getNumber(), numIncrements, "Counter increments mismatch");
    }

    /// @notice Fuzz test for executing multiple increment and decrement operations
    /// @param incrementTimes The number of times to increment and then decrement the counter
    function testFuzz_MultiFunctionCall(uint256 incrementTimes) public {
        vm.assume(incrementTimes < 50); // Reasonable operation counts
        bytes memory callDataInc = abi.encodeWithSelector(Counter.incrementNumber.selector);
        bytes memory callDataDec = abi.encodeWithSelector(Counter.decrementNumber.selector);

        for (uint256 i = 0; i < incrementTimes; i++) {
            mockExecutor.executeViaAccount(BOB_ACCOUNT, address(counter), 0, callDataInc);
        }

        for (uint256 i = 0; i < incrementTimes; i++) {
            mockExecutor.executeViaAccount(BOB_ACCOUNT, address(counter), 0, callDataDec);
        }
        uint256 expectedValue = 0;
        assertEq(counter.getNumber(), expectedValue, "Counter value mismatch after operations");
    }

    /// @notice Fuzz test for token transfers via the executor
    /// @param to The recipient address
    /// @param amount The amount of tokens to transfer
    function testFuzz_TokenTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0) && amount > 0);
        vm.assume(amount < ~uint(0) / 0xff); // Ensure amount is manageable
        vm.assume(token.balanceOf(to) == 0);
        bytes memory callData = abi.encodeWithSelector(token.transfer.selector, to, amount);

        // Mint tokens to BOB_ACCOUNT to ensure there are enough tokens to transfer
        token.mint(address(BOB_ACCOUNT), amount);

        // Execute the transfer via the installed MockExecutor
        mockExecutor.executeViaAccount(BOB_ACCOUNT, address(token), 0, callData);

        // Check the final balance of the receiver
        uint256 finalBalance = token.balanceOf(to);
        assertEq(finalBalance, amount, "Token transfer amount mismatch");
    }
}
