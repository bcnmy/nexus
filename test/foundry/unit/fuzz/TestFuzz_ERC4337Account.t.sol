// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../utils/NexusTest_Base.t.sol";

/// @title TestFuzz_ERC4337Account
/// @notice This contract contains fuzz tests for ERC-4337 account operations.
contract TestFuzz_ERC4337Account is NexusTest_Base {
    address public userAddress = address(BOB.addr);

    /// @notice Initializes the test environment.
    function setUp() public {
        init(); // Initializes all required contracts and wallets
    }

    /// @notice Fuzz testing for ensuring the deposit balance is updated correctly.
    /// @param depositAmount The amount to be deposited.
    function testFuzz_AddDeposit(uint256 depositAmount) public {
        vm.assume(depositAmount <= 50 ether); // Restricting the deposit to a reasonable upper limit

        // Fund the BOB_ACCOUNT with more than just the deposit amount to cover potential transaction fees
        vm.deal(address(BOB_ACCOUNT), depositAmount + 1 ether);

        // Capture the initial balance before the deposit is made
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(BOB_ACCOUNT), value: depositAmount, callData: abi.encodeWithSignature("addDeposit()") });

        executeBatch(BOB, BOB_ACCOUNT, executions, EXECTYPE_DEFAULT);

        // Fetch the balance after the deposit is made
        uint256 balanceAfter = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        // Define a small tolerance (e.g., 0.001 ether)
        uint256 tolerance = 0.001 ether;

        // Check if the deposit balance is updated correctly within the tolerance
        bool isWithinTolerance = (balanceAfter >= balanceBefore + depositAmount - tolerance) && (balanceAfter <= balanceBefore + depositAmount + tolerance);
        assertTrue(isWithinTolerance, "Deposit balance should correctly reflect the new deposit amount within tolerance");
    }

    /// @notice Fuzz testing for ensuring nonce behavior across various operations.
    /// @param numOps The number of operations to perform.
    function testFuzz_NonceBehavior(uint256 numOps) public {
        vm.assume(numOps < 20); // Keep the number of operations manageable

        for (uint256 i = 0; i < numOps; i++) {
            uint256 nonceBefore = getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0));
            Execution[] memory executions = new Execution[](1);
            executions[0] = Execution({ target: address(BOB_ACCOUNT), value: 0, callData: abi.encodeWithSignature("incrementNonce()") });

            executeBatch(BOB, BOB_ACCOUNT, executions, EXECTYPE_DEFAULT);

            uint256 nonceAfter = getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0));
            assertEq(nonceAfter, nonceBefore + 1, "Nonce should increment after each operation");
        }
    }

    /// @notice Fuzz testing for withdrawing deposits to a specific address.
    /// @param to The address to withdraw to.
    /// @param amount The amount to withdraw.
    function testFuzz_WithdrawDepositTo(address to, uint256 amount) public {
        vm.assume(!isContract(to)); // Valid 'to' address and skip precompiles
        vm.assume(uint160(address(to)) > 0xff); // no precompiles
        vm.assume(amount > 0.01 ether && amount <= 50 ether); // Restricting the amount to a reasonable upper limit and ensuring it's greater than 0
        vm.assume(to.balance == 0);
        // Fund the BOB_ACCOUNT with more than just the deposit amount to cover potential transaction fees
        vm.deal(address(BOB_ACCOUNT), amount + 1 ether);

        // Deposit the amount to EntryPoint
        Execution[] memory depositExecutions = new Execution[](1);
        depositExecutions[0] = Execution({ target: address(BOB_ACCOUNT), value: amount, callData: abi.encodeWithSignature("addDeposit()") });
        executeBatch(BOB, BOB_ACCOUNT, depositExecutions, EXECTYPE_DEFAULT);

        // Capture the balance before withdrawal

        // Withdraw the amount to the 'to' address
        Execution[] memory withdrawExecutions = new Execution[](1);
        withdrawExecutions[0] =
            Execution({ target: address(BOB_ACCOUNT), value: 0, callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", to, amount) });
        executeBatch(BOB, BOB_ACCOUNT, withdrawExecutions, EXECTYPE_DEFAULT);

        assertEq(to.balance, amount, "Withdrawal amount should reflect in the 'to' address balance");
    }

    /// @notice Fuzz testing for withdrawing deposits with insufficient funds.
    /// @param amount The amount to withdraw.
    function testFuzz_WithdrawInsufficientFunds(uint256 amount) public {
        vm.assume(amount > 0.01 ether && amount <= 50 ether);

        vm.deal(address(BOB_ACCOUNT), 0.5 ether); // Fund less than the amount to withdraw

        Execution[] memory withdrawExecutions = new Execution[](1);
        withdrawExecutions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount)
        });

        PackedUserOperation[] memory withdrawUserOps =
            buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, withdrawExecutions, address(VALIDATOR_MODULE), 0);
        ENTRYPOINT.handleOps(withdrawUserOps, payable(BOB.addr));
    }
}
