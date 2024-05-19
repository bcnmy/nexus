// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC4337Account_OnlyEntryPointOrSelf
/// @notice Tests for operations that should be executed only by the EntryPoint or the account itself.
contract TestERC4337Account_OnlyEntryPointOrSelf is NexusTest_Base {
    /// @notice Sets up the testing environment and ensures BOB_ACCOUNT has ether.
    function setUp() public {
        init();
        BOB_ACCOUNT.addDeposit{ value: 1 ether }();
    }

    /// @notice Tests execution of user operations from the EntryPoint.
    function test_ExecuteUserOp_Valid_FromEntryPoint() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, "");
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Tests execution of user operations from a non-EntryPoint address, expecting failure.
    function test_ExecuteUserOp_Invalid_FromNonEntryPoint() public {
        startPrank(ALICE.addr);
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, "");
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.executeUserOp(userOps[0], bytes32(0));
        stopPrank();
    }

    /// @notice Tests installation of a module from the EntryPoint.
    function test_InstallModule_FromEntryPoint() public {
        startPrank(address(ENTRYPOINT));
        BOB_ACCOUNT.installModule(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");
        stopPrank();
    }

    /// @notice Tests installation of a module from the account itself.
    function test_InstallModule_FromSelf() public {
        startPrank(address(BOB_ACCOUNT));
        BOB_ACCOUNT.installModule(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");
    }

    /// @notice Tests uninstallation of a module from a non-EntryPoint or self address, expecting failure.
    function test_UninstallModule_FromNonEntryPointOrSelf() public {
        startPrank(ALICE.addr);
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.uninstallModule(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), new bytes(0));
        stopPrank();
    }

    /// @notice Tests withdrawal of deposit to an authorized address from the EntryPoint.
    function test_WithdrawDeposit_ToAuthorizedAddress() public {
        startPrank(address(ENTRYPOINT));
        BOB_ACCOUNT.withdrawDepositTo(BOB.addr, 0.5 ether);
        stopPrank();
    }

    /// @notice Tests withdrawal of deposit from the account itself.
    function test_WithdrawDeposit_FromSelf() public {
        startPrank(address(BOB_ACCOUNT));
        BOB_ACCOUNT.withdrawDepositTo(BOB.addr, 0.5 ether);
    }

    /// @notice Tests withdrawal of deposit from an unauthorized address, expecting failure.
    function test_WithdrawDeposit_FromUnauthorizedAddress() public {
        startPrank(ALICE.addr);
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.withdrawDepositTo(BOB.addr, 0.5 ether);
        stopPrank();
    }

    /// @notice Tests execution of the withdrawDepositTo function via the executor module.
    function test_ExecuteViaExecutor_WithdrawDepositTo() public {
        startPrank(address(ENTRYPOINT));
        BOB_ACCOUNT.installModule(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");
        stopPrank();
        uint256 depositBefore = BOB_ACCOUNT.getDeposit();
        bytes memory callData = abi.encodeWithSelector(BOB_ACCOUNT.withdrawDepositTo.selector, BOB.addr, 0.5 ether);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        EXECUTOR_MODULE.executeBatchViaAccount(BOB_ACCOUNT, executions);
        uint256 depositAfter = BOB_ACCOUNT.getDeposit();

        assertEq(depositAfter, depositBefore - 0.5 ether, "Deposit should be reduced by 0.5 ether");
    }

    /// @notice Tests withdrawal of deposit to an authorized address via user operations.
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

    /// @notice Tests installation of a module from the EntryPoint via user operations.
    function test_InstallModule_FromEntryPoint_WithUserOps() public {
        Execution[] memory executions = new Execution[](1);
        bytes memory callData = abi.encodeWithSelector(BOB_ACCOUNT.installModule.selector, 2, address(EXECUTOR_MODULE), "");
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
