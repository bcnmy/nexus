// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/BaseInvariantTest.t.sol";

// DepositManagementInvariantHandler manages deposit operations for a Nexus account,
// ensuring invariants remain intact throughout the process.
contract InvariantDepositManagementHandler is BaseInvariantTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;

    // Initializes the handler with a Nexus account and wallet used for signing transactions
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    // Handles a deposit operation while verifying that the state remains consistent
    function invariant_handleDeposit(uint256 amount) external {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: amount,
            callData: abi.encodeWithSignature("addDeposit()")
        });

        // Execute deposit through the ENTRYPOINT with invariant checks
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Ensure deposit is reflected accurately, accounting for transaction fees
        assertGe(nexusAccount.getDeposit(), amount, "Invariant failed: Deposit operation state inconsistency.");
    }

    // Handles a withdrawal operation while ensuring the post-withdrawal state is correct
    function invariant_handleWithdrawal(uint256 amount) external {
        bytes memory callData = abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        // Execute withdrawal through the ENTRYPOINT and verify the remaining deposit
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Check that the remaining deposit is accurate after the withdrawal
        assertLe(nexusAccount.getDeposit(), amount, "Invariant failed: Withdrawal operation state inconsistency.");
    }
}
