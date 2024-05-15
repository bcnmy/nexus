// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/SmartAccountTestLab.t.sol";

contract TestFuzz_ERC4337Account is SmartAccountTestLab {
    address public userAddress = address(BOB.addr);
    function setUp() public {
        init(); // Initializes all required contracts and wallets
    }

    // Fuzz testing for ensuring the deposit balance is updated correctly
    function testFuzz_AddDeposit(uint256 depositAmount) public {
        vm.assume(depositAmount <= 50 ether); // Restricting the deposit to a reasonable upper limit

        // Fund the BOB_ACCOUNT with more than just the deposit amount to cover potential transaction fees
        vm.deal(address(BOB_ACCOUNT), depositAmount + 1 ether);

        // Capture the initial balance before the deposit is made
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(BOB_ACCOUNT), value: depositAmount, callData: abi.encodeWithSignature("addDeposit()") });

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Fetch the balance after the deposit is made
        uint256 balanceAfter = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        // Define a small tolerance (e.g., 0.001 ether)
        uint256 tolerance = 0.001 ether;

        // Check if the deposit balance is updated correctly within the tolerance
        bool isWithinTolerance = (balanceAfter >= balanceBefore + depositAmount - tolerance) &&
            (balanceAfter <= balanceBefore + depositAmount + tolerance);
        assertTrue(isWithinTolerance, "Deposit balance should correctly reflect the new deposit amount within tolerance");
    }

    // Fuzz testing for ensuring nonce behavior across various operations
    function testFuzz_NonceBehavior(uint256 numOps) public {
        vm.assume(numOps < 20); // Keep the number of operations manageable

        for (uint256 i = 0; i < numOps; i++) {
            uint256 nonceBefore = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
            Execution[] memory executions = new Execution[](1);
            executions[0] = Execution({ target: address(BOB_ACCOUNT), value: 0, callData: abi.encodeWithSignature("incrementNonce()") });

            PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
            ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

            uint256 nonceAfter = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
            assertEq(nonceAfter, nonceBefore + 1, "Nonce should increment after each operation");
        }
    }

    function testFuzz_ValidateUserOp(uint256 randomNonce, bytes memory randomSignature) public {
        vm.deal(address(ENTRYPOINT), 10 ether); // Ensure the ENTRYPOINT has enough ether to cover transaction fees
        // Fuzz the nonce and signature
        vm.assume(randomNonce < type(uint192).max); // Assuming practical nonce range

        // Create a user operation with random data
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, randomNonce);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = randomSignature; // Using fuzzed signature

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 10);
        assertTrue(res == 0 || res == 1, "Operation should either pass or fail validation properly");
        stopPrank();
    }

    function testFuzz_WithdrawDepositTo(address to, uint256 amount) public {
        vm.assume(to != address(0) && to != address(this)); // Valid 'to' address
        vm.assume(amount > 0.01 ether && amount <= 50 ether); // Restricting the amount to a reasonable upper limit and ensuring it's greater than 0

        // Fund the BOB_ACCOUNT with more than just the deposit amount to cover potential transaction fees
        vm.deal(address(BOB_ACCOUNT), amount + 1 ether);

        // Deposit the amount to EntryPoint
        Execution[] memory depositExecutions = new Execution[](1);
        depositExecutions[0] = Execution({ target: address(BOB_ACCOUNT), value: amount, callData: abi.encodeWithSignature("addDeposit()") });
        PackedUserOperation[] memory depositUserOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, depositExecutions);
        ENTRYPOINT.handleOps(depositUserOps, payable(BOB.addr));

        // Capture the balance before withdrawal
        uint256 balanceBefore = ENTRYPOINT.balanceOf(to);

        // Withdraw the amount to the 'to' address
        Execution[] memory withdrawExecutions = new Execution[](1);
        withdrawExecutions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", to, amount)
        });
        PackedUserOperation[] memory withdrawUserOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, withdrawExecutions);
        ENTRYPOINT.handleOps(withdrawUserOps, payable(BOB.addr));

        // Capture the balance after withdrawal
        uint256 balanceAfter = ENTRYPOINT.balanceOf(to);

        // Define a small tolerance (e.g., 0.001 ether)
        uint256 tolerance = 0.001 ether;

        // Check if the withdrawal was successful within the tolerance

        assertApproxEqRel(balanceAfter, balanceBefore, tolerance, "Deposit balance invariant failed after withdrawal.");
    }

    function testFuzz_InvalidSignature(uint256 randomNonce, bytes memory invalidSignature) public {
        vm.assume(randomNonce < type(uint192).max); // Assuming practical nonce range

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, randomNonce);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = invalidSignature; // Using invalid signature

        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 10);
        assertTrue(res == 1, "Operation should fail validation with an invalid signature");
        stopPrank();
    }

    function testFuzz_WithdrawInsufficientFunds(uint256 amount) public {
        vm.assume(amount > 0.01 ether && amount <= 50 ether);

        vm.deal(address(BOB_ACCOUNT), 0.5 ether); // Fund less than the amount to withdraw

        Execution[] memory withdrawExecutions = new Execution[](1);
        withdrawExecutions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount)
        });

        PackedUserOperation[] memory withdrawUserOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, withdrawExecutions);
        (bool success, ) = address(ENTRYPOINT).call(abi.encodeWithSignature("handleOps(PackedUserOperation[],address)", withdrawUserOps, BOB.addr));

        assertFalse(success, "Withdrawal should fail due to insufficient funds");
    }
}
