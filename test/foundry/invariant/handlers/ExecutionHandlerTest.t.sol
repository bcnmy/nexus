// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";

// ExecutionHandlerTest handles the execution of operations on a Nexus account,
// ensuring that the expected state changes occur as per the invariants defined.
contract ExecutionHandlerTest is InvariantBaseTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;
    uint256 private totalDeposits; // Ghost variable to track total deposits for invariant checking

    // Initializes the handler with a Nexus account and a wallet used for signing transactions
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
        totalDeposits = 0; // Initialize total deposits to zero
    }

    // Executes a deposit operation and verifies the post-operation state
    function invariant_handleIncrement(uint256 amount) external {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: amount, callData: abi.encodeWithSignature("addDeposit()") });

        // Execute operation through ENTRYPOINT and verify post-operation conditions
        PackedUserOperation[] memory userOps =  buildPackedUserOperation(signer, nexusAccount, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Function-level assertion to ensure the deposit amount reflects correctly
        assertEq(nexusAccount.getDeposit(), amount, "Invariant failed: Deposit amount mismatch after increment.");
    }

    // Attempts a failing operation to ensure proper error handling and state consistency
    function invariant_handleShouldFail(uint256 amount) external {
        vm.expectRevert("Expected failure");
        nexusAccount.withdrawDepositTo(address(this), amount);

        // Check for state consistency post-failure
        assertStateConsistency(nexusAccount);
    }

    // Ensures deposit operation remains within specified bounds and checks cumulative deposit correctness
    function invariant_handleBoundedDeposit(uint256 amount) external {
        amount = bound(amount, 1 ether, 1000 ether); // Ensure the deposit is within sensible bounds
        uint256 expectedTotal = totalDeposits + amount;
        nexusAccount.addDeposit{ value: amount }();

        // Post-operation assertions
        assertEq(nexusAccount.getDeposit(), expectedTotal, "Invariant failed: Total deposits mismatch.");
        totalDeposits = expectedTotal; // Update the ghost variable for further checks
    }

    // Method to retrieve the current deposit amount from the nexus account
    function getAccountDeposit() public view returns (uint256) {
        return nexusAccount.getDeposit();
    }

    // Additional utility function to verify state consistency in case of failures
    function assertStateConsistency(Nexus account) internal {
        assertGe(account.getDeposit(), 0, "Invariant failed: Deposit should never be negative.");
    }
}
