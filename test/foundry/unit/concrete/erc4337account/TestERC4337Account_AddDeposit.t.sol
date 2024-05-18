// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";

event Deposited(address indexed account, uint256 totalDeposit);

contract TestERC4337Account_addDeposit is Test, SmartAccountTestLab {
    uint256 defaultMaxPercentDelta;
    uint256 defaultDepositAmount;

    function setUp() public {
        super.init();
        BOB_ACCOUNT = BOB_ACCOUNT;
        defaultMaxPercentDelta = 100_000_000_000;
        defaultDepositAmount = 1 ether;
    }

    function test_AddDeposit_Success() public {
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        BOB_ACCOUNT.addDeposit{ value: defaultDepositAmount }();
        assertEq(depositBefore + defaultDepositAmount, ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)), "Deposit should be added to EntryPoint");
    }

    function test_AddDeposit_EventEmitted() public {
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), defaultDepositAmount);
        vm.expectEmit(true, true, true, true);
        uint256 expectedDeposit = ENTRYPOINT.getDepositInfo(address(BOB_ACCOUNT)).deposit + defaultDepositAmount;
        emit Deposited(address(BOB_ACCOUNT), expectedDeposit);
        BOB_ACCOUNT.addDeposit{ value: defaultDepositAmount }();
    }

    function test_AddDeposit_Revert_NoValue() public {
        // REVIEW: Should we add zero value check to the addDeposit method?
        BOB_ACCOUNT.addDeposit();
    }

    function test_AddDeposit_DepositViaHandleOps() public {
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), defaultDepositAmount + 1 ether);
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        Execution[] memory executions = prepareSingleExecution(address(BOB_ACCOUNT), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        // Using almostEq to compare balances with a tolerance for gas costs
        almostEq(depositBefore + defaultDepositAmount - (gasUsed * tx.gasprice), ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)), defaultMaxPercentDelta);
    }

    function test_AddDeposit_BatchDepositViaHandleOps() public {
        uint256 executionsNumber = 5;
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), defaultDepositAmount * 10);
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        Execution memory execution = Execution(address(BOB_ACCOUNT), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        Execution[] memory executions = prepareSeveralIdenticalExecutions(execution, executionsNumber);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);
        almostEq(
            depositBefore + (defaultDepositAmount * executionsNumber) - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)),
            defaultMaxPercentDelta
        );
    }

    function test_AddDeposit_Try_DepositViaHandleOps() public {
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), defaultDepositAmount + 1 ether);
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        Execution[] memory executions = prepareSingleExecution(address(BOB_ACCOUNT), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        almostEq(depositBefore + defaultDepositAmount - (gasUsed * tx.gasprice), ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)), defaultMaxPercentDelta);
    }

    function test_AddDeposit_Try_BatchDepositViaHandleOps() public {
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), defaultDepositAmount * 10);
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 executionsNumber = 5;

        Execution memory execution = Execution(address(BOB_ACCOUNT), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        Execution[] memory executions = prepareSeveralIdenticalExecutions(execution, executionsNumber);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        almostEq(
            depositBefore + (defaultDepositAmount * executionsNumber) - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)),
            defaultMaxPercentDelta
        );
    }
}
