// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/BaseInvariantTest.t.sol";

// DepositManagementInvariantHandler manages deposit operations for a Nexus account,
// ensuring invariants remain intact throughout the process.
contract DepositManagementHandler is BaseInvariantTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;

    // Initializes the handler with a Nexus account and wallet used for signing transactions
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    // Handles a deposit operation while verifying that the state remains consistent
    function invariant_handleDeposit(uint256 amount) public {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: amount, callData: abi.encodeWithSignature("addDeposit()") });

        // Execute deposit through the ENTRYPOINT with invariant checks
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Ensure deposit is reflected accurately, accounting for transaction fees
        assertGe(nexusAccount.getDeposit(), amount, "Invariant failed: Deposit operation state inconsistency.");
    }

    // Handles a withdrawal operation while ensuring the post-withdrawal state is correct
    function invariant_handleWithdrawal(uint256 amount) public {
        bytes memory callData = abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        // Execute withdrawal through the ENTRYPOINT and verify the remaining deposit
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Check that the remaining deposit is accurate after the withdrawal
        assertLe(nexusAccount.getDeposit(), amount, "Invariant failed: Withdrawal operation state inconsistency.");
    }

    // Ensures zero-value deposits behave as expected
    function invariant_testZeroValueDeposit() external {
        uint256 initialDeposit = nexusAccount.getDeposit();
        invariant_handleDeposit(0);
        assertEq(nexusAccount.getDeposit(), initialDeposit, "Deposit should be unchanged with zero-value input.");
    }

    // Tests system behavior when attempting to withdraw more than the balance
    function invariant_testOverdraftWithdrawal() external {
        uint256 initialDeposit = nexusAccount.getDeposit();
        uint256 overdraftAmount = initialDeposit + 1 ether;
        vm.expectRevert("Insufficient funds");
        invariant_handleWithdrawal(overdraftAmount);
        assertEq(nexusAccount.getDeposit(), initialDeposit, "Balance should be unchanged after failed withdrawal.");
    }

    // Checks the account balance integrity after a simulated transaction failure
    function invariant_checkBalancePostRevert() external {
        uint256 initialDeposit = nexusAccount.getDeposit();
        vm.expectRevert("Expected failure");
        invariant_handleWithdrawal(initialDeposit + 1 ether); // Assuming failure due to overdraft
        assertEq(nexusAccount.getDeposit(), initialDeposit, "Deposit should not change after revert.");
    }
}
