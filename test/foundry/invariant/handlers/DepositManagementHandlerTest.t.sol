// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import "../../utils/Imports.sol";

/// @title DepositManagementHandlerTest
/// @notice Manages deposit operations for a Nexus account, ensuring invariants remain intact throughout the process.
/// @dev This handler manages the deposit and withdrawal operations, checking for consistency and correctness of account balances.
contract DepositManagementHandlerTest is InvariantBaseTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;

    /// @notice Initializes the handler with a Nexus account and wallet used for signing transactions.
    /// @param _nexusAccount The Nexus account to manage deposits for.
    /// @param _signer The wallet used for signing transactions.
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    /// @notice Handles a deposit operation while verifying that the state remains consistent.
    /// @param amount The amount to deposit.
    function invariant_handleDeposit(uint256 amount) public {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: amount, callData: abi.encodeWithSignature("addDeposit()") });

        // Execute deposit through the ENTRYPOINT with invariant checks
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Ensure deposit is reflected accurately, accounting for transaction fees
        assertGe(nexusAccount.getDeposit(), amount, "Invariant failed: Deposit operation state inconsistency.");
    }

    /// @notice Handles a withdrawal operation while ensuring the post-withdrawal state is correct.
    /// @param amount The amount to withdraw.
    function invariant_handleWithdrawal(uint256 amount) public {
        bytes memory callData = abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        // Execute withdrawal through the ENTRYPOINT and verify the remaining deposit
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Check that the remaining deposit is accurate after the withdrawal
        assertLe(nexusAccount.getDeposit(), amount, "Invariant failed: Withdrawal operation state inconsistency.");
    }

    /// @notice Ensures zero-value deposits behave as expected.
    function invariant_testZeroValueDeposit() external {
        uint256 initialDeposit = nexusAccount.getDeposit();
        invariant_handleDeposit(0);
        assertEq(nexusAccount.getDeposit(), initialDeposit, "Deposit should be unchanged with zero-value input.");
    }

    /// @notice Tests system behavior when attempting to withdraw more than the balance.
    function invariant_testOverdraftWithdrawal() external {
        uint256 initialDeposit = nexusAccount.getDeposit();
        uint256 overdraftAmount = initialDeposit + 1 ether;
        vm.expectRevert("Insufficient funds");
        invariant_handleWithdrawal(overdraftAmount);
        assertEq(nexusAccount.getDeposit(), initialDeposit, "Balance should be unchanged after failed withdrawal.");
    }

    /// @notice Checks the account balance integrity after a simulated transaction failure.
    function invariant_checkBalancePostRevert() external {
        uint256 initialDeposit = nexusAccount.getDeposit();
        vm.expectRevert("Expected failure");
        invariant_handleWithdrawal(initialDeposit + 1 ether);
        assertEq(nexusAccount.getDeposit(), initialDeposit, "Deposit should not change after revert.");
    }
}
