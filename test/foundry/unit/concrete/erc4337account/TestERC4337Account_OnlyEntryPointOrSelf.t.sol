// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

contract TestERC4337Account_OnlyEntryPointOrSelf is Test, NexusTest_Base {
    function setUp() public {
        init();
        BOB_ACCOUNT.addDeposit{ value: 1 ether }(); // Ensure BOB_ACCOUNT has ether for operations requiring ETH transfers.
    }

    function test_ExecuteUserOp_Valid_FromEntryPoint() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, "");
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        // Simulate EntryPoint processing the operation
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function test_ExecuteUserOp_Invalid_FromNonEntryPoint() public {
        startPrank(ALICE.addr);
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, "");
        // This should fail as ALICE is not the EntryPoint
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));

        BOB_ACCOUNT.executeUserOp(userOps[0], bytes32(0)); // Example usage, ensure this matches actual expected call
        stopPrank();
    }

    function test_InstallModule_FromEntryPoint() public {
        startPrank(address(ENTRYPOINT));
        // Attempt to install a module from the EntryPoint, should succeed
        BOB_ACCOUNT.installModule(2, address(EXECUTOR_MODULE), "");
        stopPrank();
    }

    function test_InstallModule_FromSelf() public {
        // Install module from the account itself, should succeed
        startPrank(address(BOB_ACCOUNT));
        BOB_ACCOUNT.installModule(2, address(EXECUTOR_MODULE), "");
    }

    function test_UninstallModule_FromNonEntryPointOrSelf() public {
        startPrank(ALICE.addr);
        // This call should fail because ALICE is neither EntryPoint nor the BOB_ACCOUNT itself
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.uninstallModule(2, address(EXECUTOR_MODULE), new bytes(0));
        stopPrank();
    }

    function test_WithdrawDeposit_ToAuthorizedAddress() public {
        startPrank(address(ENTRYPOINT));
        // EntryPoint attempts to withdraw funds to a specified address, should succeed
        BOB_ACCOUNT.withdrawDepositTo(BOB.addr, 0.5 ether);
        stopPrank();
    }

    function test_WithdrawDeposit_FromSelf() public {
        // The account itself initiates withdrawal, should succeed
        startPrank(address(BOB_ACCOUNT));
        BOB_ACCOUNT.withdrawDepositTo(BOB.addr, 0.5 ether);
    }

    function test_WithdrawDeposit_FromUnauthorizedAddress() public {
        startPrank(ALICE.addr);
        // Attempting to withdraw from an unauthorized address (not EntryPoint or self), should fail
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.withdrawDepositTo(BOB.addr, 0.5 ether);
        stopPrank();
    }

    function test_ExecuteViaExecutor_WithdrawDepositTo() public {
        // Install Executor module first
        startPrank(address(ENTRYPOINT));
        BOB_ACCOUNT.installModule(2, address(EXECUTOR_MODULE), "");
        stopPrank();
        uint256 depositBefore = BOB_ACCOUNT.getDeposit();
        // Prepare the call data for the withdrawDepositTo function
        bytes memory callData = abi.encodeWithSelector(BOB_ACCOUNT.withdrawDepositTo.selector, BOB.addr, 0.5 ether);

        // Set up the Execution structure to use the installed executor module
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Use the executor module to perform the operation via BOB_ACCOUNT
        EXECUTOR_MODULE.executeBatchViaAccount(BOB_ACCOUNT, executions);
        uint256 depositAfter = BOB_ACCOUNT.getDeposit();

        assertEq(depositAfter, depositBefore - 0.5 ether, "Deposit should be reduced by 0.5 ether");
    }

    function test_WithdrawDeposit_ToAuthorizedAddress_WithUserOps() public {
        uint256 depositBefore = BOB_ACCOUNT.getDeposit();

        Execution[] memory executions = new Execution[](1);
        bytes memory callData = abi.encodeWithSelector(BOB_ACCOUNT.withdrawDepositTo.selector, BOB.addr, 0.5 ether);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        uint256 depositAfter = BOB_ACCOUNT.getDeposit();
        assertApproxEqAbs(depositAfter, depositBefore - 0.5 ether, 0.0001 ether, "Deposit should be reduced by 0.5 ether");
    }

    function test_InstallModule_FromEntryPoint_WithUserOps() public {
        Execution[] memory executions = new Execution[](1);
        bytes memory callData = abi.encodeWithSelector(BOB_ACCOUNT.installModule.selector, 2, address(EXECUTOR_MODULE), "");
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
