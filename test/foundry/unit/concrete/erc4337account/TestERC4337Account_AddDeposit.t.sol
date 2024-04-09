// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";

event DepositAdded(address indexed account, address indexed depositor, uint256 amount);

contract TestERC4337Account_addDeposit is Test, SmartAccountTestLab {
    SmartAccount private account;
    uint256 defaultMaxPercentDelta;
    uint256 defaultDepositAmount;

    function setUp() public {
        super.init();
        account = BOB_ACCOUNT;
        defaultMaxPercentDelta = 100_000_000_000;
        defaultDepositAmount = 1 ether;
    }

    function test_AddDeposit_Success() public {
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));
        account.addDeposit{ value: defaultDepositAmount }();
        assertEq(
            balanceBefore + defaultDepositAmount,
            ENTRYPOINT.balanceOf(address(account)),
            "Deposit should be added to EntryPoint"
        );
    }

    function test_AddDeposit_EventEmitted() public {
        _prefundSmartAccountAndAssertSuccess(address(account), defaultDepositAmount);

        vm.expectEmit(true, true, true, true);
        emit DepositAdded(address(account), address(this), defaultDepositAmount); // Assuming there's a DepositAdded event
        account.addDeposit{ value: defaultDepositAmount }();
    }

    function test_AddDeposit_Revert_NoValue() public {
        // Should we add zero value check to the addDeposit method?
        account.addDeposit();
    }

    function test_AddDeposit_DepositViaHandleOps() public {
        _prefundSmartAccountAndAssertSuccess(address(account), defaultDepositAmount + 1 ether);
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution[] memory executions = _prepareSingleExecution(address(account), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_DEFAULT, executions);
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        // Using almostEq to compare balances with a tolerance for gas costs
        almostEq(
            balanceBefore + defaultDepositAmount - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            defaultMaxPercentDelta
        );
    }

    function test_AddDeposit_BatchDepositViaHandleOps() public {
        uint256 executionsNumber = 5;
        _prefundSmartAccountAndAssertSuccess(address(account), defaultDepositAmount * 10);
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution memory execution = Execution(address(account), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        Execution[] memory executions = prepareSeveralIdenticalExecutions(execution, executionsNumber);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_DEFAULT, executions);
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);
        almostEq(
            balanceBefore + (defaultDepositAmount * executionsNumber) - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            defaultMaxPercentDelta
        );
    }

    function test_AddDeposit_Try_DepositViaHandleOps() public {
        _prefundSmartAccountAndAssertSuccess(address(account), defaultDepositAmount + 1 ether);
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution[] memory executions = _prepareSingleExecution(address(account), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_TRY, executions);
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        almostEq(
            balanceBefore + defaultDepositAmount - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            defaultMaxPercentDelta
        );
    }

    function test_AddDeposit_Try_BatchDepositViaHandleOps() public {
        _prefundSmartAccountAndAssertSuccess(address(account), defaultDepositAmount * 10);
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));
        uint256 executionsNumber = 5;

        Execution memory execution = Execution(address(account), defaultDepositAmount, abi.encodeWithSignature("addDeposit()"));
        Execution[] memory executions = prepareSeveralIdenticalExecutions(execution, executionsNumber);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_TRY, executions);
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        almostEq(
            balanceBefore + (defaultDepositAmount * executionsNumber) - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            defaultMaxPercentDelta
        );
    }
}
