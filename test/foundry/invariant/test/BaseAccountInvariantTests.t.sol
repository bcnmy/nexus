// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../../utils/SmartAccountTestLab.t.sol";

contract BaseAccountInvariantTests is SmartAccountTestLab {
    function setUp() public {
        init();
    }

    // Invariant to ensure deposit balance integrity with tolerance for gas costs
    function invariant_depositBalanceConsistency() public {
        uint256 initialBalance = BOB_ACCOUNT.getDeposit();
        uint256 depositAmount = 1 ether;
        uint256 tolerance = 0.02e18; // 2% tolerance expressed in terms of 1e18

        // Adjust balance with vm.deal to simulate deposit.
        vm.deal(address(BOB_ACCOUNT), initialBalance + depositAmount + 1 ether);

        // Deposit 1 ether to BOB_ACCOUNT from BOB.
        vm.prank(BOB.addr);
        BOB_ACCOUNT.addDeposit{ value: 1 ether }();

        // Check if the deposit reflects correctly within the tolerance
        uint256 postDepositBalance = BOB_ACCOUNT.getDeposit();
        assertApproxEqRel(postDepositBalance, initialBalance + depositAmount, tolerance, "Deposit balance invariant failed after deposit.");

        // Simulate withdrawal
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(
            address(BOB_ACCOUNT),
            0,
            abi.encodeWithSelector(BOB_ACCOUNT.withdrawDepositTo.selector, address(0x123), depositAmount)
        );

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the post-withdrawal balance within the tolerance
        uint256 finalBalance = BOB_ACCOUNT.getDeposit();
        assertApproxEqRel(finalBalance, initialBalance, tolerance, "Deposit balance invariant failed after withdrawal.");
    }

    // Invariant to test access control for withdrawal
    function invariant_accessControl() public {
        try BOB_ACCOUNT.withdrawDepositTo(address(this), 1 ether) {
            fail("withdrawDepositTo should fail when not called through ENTRYPOINT");
        } catch {}
    }

    // Invariant to ensure consistent nonce handling
    function invariant_nonceConsistency() public {
        uint256 initialNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Simulating a transaction that affects nonce
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, abi.encodeWithSelector(BOB_ACCOUNT.addDeposit.selector));

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        uint256 updatedNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
        assertEq(updatedNonce, initialNonce + 1, "Nonce should increment correctly.");
    }

    // Invariant to ensure consistent nonce handling with multiple operations
    function invariant_multiOperationNonceConsistency() public {
        uint256 initialNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Simulate multiple operations
        for (uint i = 0; i < 3; i++) {
            Execution[] memory executions = _prepareSingleExecution(address(BOB_ACCOUNT), 1, abi.encodeWithSelector(BOB_ACCOUNT.addDeposit.selector));
            PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
            ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        }

        uint256 finalNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
        assertEq(finalNonce, initialNonce + 3, "Nonce should increment by 3 after three operations.");
    }

    // Invariant to ensure consistent nonce handling with multiple operations in a single handleOps call
    function invariant_multiOperationNonceConsistency_SingleCall() public {
        uint256 initialNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Prepare multiple executions to be processed together
        Execution[] memory execution = _prepareSingleExecution(address(BOB_ACCOUNT), 1, abi.encodeWithSelector(BOB_ACCOUNT.addDeposit.selector));

        // Create an array of PackedUserOperations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](3);
        userOps[0] = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution)[0];
        userOps[1] = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution)[0];
        userOps[2] = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution)[0];

        // Set proper nonce values for each user operation
        for (uint i = 0; i < userOps.length; i++) {
            userOps[i].nonce = initialNonce + i;
            userOps[i].signature = signUserOp(BOB, userOps[i]);
        }

        // Process all operations in a single call
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        uint256 finalNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
        assertEq(finalNonce, initialNonce + 3, "Nonce should increment by 3 after three operations.");
    }
}
