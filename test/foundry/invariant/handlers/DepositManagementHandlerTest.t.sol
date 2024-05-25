// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";

/// @title DepositManagementHandlerTest
/// @notice Manages deposit operations for a Nexus account, ensuring invariants remain intact throughout the process.
/// @dev This handler manages the deposit and withdrawal operations, checking for consistency and correctness of account balances.
contract DepositManagementHandlerTest is InvariantBaseTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;
    address internal validatorModule;

    /// @notice Initializes the handler with a Nexus account and wallet used for signing transactions.
    /// @param _nexusAccount The Nexus account to manage deposits for.
    /// @param _signer The wallet used for signing transactions.
    /// @param _validationModule The validation module address.
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer, address _validationModule) {
        nexusAccount = _nexusAccount;
        signer = _signer;
        validatorModule = _validationModule;
    }

    /// @notice Handles a deposit operation while verifying that the state remains consistent.
    /// @param amount The amount to deposit.
    function invariant_handleDeposit(uint256 amount) public {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: amount,
            callData: abi.encodeWithSignature("addDeposit()")
        });

        // Execute deposit through the ENTRYPOINT with invariant checks
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            validatorModule
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
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        // Execute withdrawal through the ENTRYPOINT and verify the remaining deposit
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            validatorModule
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Check that the remaining deposit is accurate after the withdrawal
        assertLe(nexusAccount.getDeposit(), amount, "Invariant failed: Withdrawal operation state inconsistency.");
    }

    /// @notice Tests system behavior for zero value deposits.
    function invariant_testZeroValueDeposit() public {
        uint256 amount = 0;

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: amount,
            callData: abi.encodeWithSignature("addDeposit()")
        });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            validatorModule
        );

        vm.expectRevert("Deposit amount cannot be zero");
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }

    /// @notice Tests system behavior for overdraft withdrawals.
    function invariant_testOverdraftWithdrawal() public {
        uint256 amount = nexusAccount.getDeposit() + 1;

        bytes memory callData = abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            validatorModule
        );

        vm.expectRevert("Insufficient deposit");
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }

    /// @notice Checks balance consistency after a revert across all actors.
    function invariant_checkBalancePostRevert() public {
        uint256 initialDeposit = nexusAccount.getDeposit();
        uint256 amount = initialDeposit + 1;

        bytes memory callData = abi.encodeWithSignature("withdrawDepositTo(address,uint256)", address(this), amount);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            validatorModule
        );

        vm.expectRevert("Insufficient deposit");
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        assertEq(nexusAccount.getDeposit(), initialDeposit, "Invariant failed: Deposit balance mismatch after revert.");
    }
}
