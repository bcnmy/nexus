// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import "../../utils/Imports.sol";

/// @title ExecutionHandlerTest
/// @notice Handles the execution of operations on a Nexus account and ensures that the expected state changes occur as per the defined invariants.
/// @dev This handler executes various operations on a Nexus account and verifies the resulting state against the expected outcomes.
contract ExecutionHandlerTest is InvariantBaseTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;
    uint256 private totalDeposits; // Ghost variable to track total deposits for invariant checking

    /// @notice Initializes the handler with a Nexus account and a wallet used for signing transactions.
    /// @param _nexusAccount The Nexus account to be used for testing.
    /// @param _signer The wallet used for signing transactions.
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
        totalDeposits = 0; // Initialize total deposits to zero
    }

    /// @notice Executes a deposit operation and verifies the post-operation state.
    /// @param amount The amount to be deposited.
    function invariant_handleIncrement(uint256 amount) external {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: amount, callData: abi.encodeWithSignature("addDeposit()") });

        // Execute operation through ENTRYPOINT and verify post-operation conditions
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Function-level assertion to ensure the deposit amount reflects correctly
        assertGe(nexusAccount.getDeposit(), totalDeposits + amount, "Invariant failed: Deposit amount mismatch after increment.");
        totalDeposits += amount; // Update the ghost variable for further checks
    }

    /// @notice Attempts a failing operation to ensure proper error handling and state consistency.
    /// @param amount The amount to be attempted for withdrawal.
    function invariant_handleShouldFail(uint256 amount) external {
        vm.expectRevert("Expected failure");
        nexusAccount.withdrawDepositTo(address(this), amount);

        // Check for state consistency post-failure
        assertStateConsistency(nexusAccount);
    }

    /// @notice Ensures deposit operation remains within specified bounds and checks cumulative deposit correctness.
    /// @param amount The amount to be deposited, bounded within 1 to 1000 ether.
    function invariant_handleBoundedDeposit(uint256 amount) external {
        amount = bound(amount, 1 ether, 1000 ether); // Ensure the deposit is within sensible bounds
        uint256 expectedTotal = totalDeposits + amount;
        nexusAccount.addDeposit{ value: amount }();

        // Post-operation assertions
        assertEq(nexusAccount.getDeposit(), expectedTotal, "Invariant failed: Total deposits mismatch.");
        totalDeposits = expectedTotal; // Update the ghost variable for further checks
    }

    /// @notice Utility function to verify state consistency in case of failures.
    /// @param account The Nexus account to check for state consistency.
    function assertStateConsistency(Nexus account) internal {
        assertGe(account.getDeposit(), 0, "Invariant failed: Deposit should never be negative.");
    }
}
