// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";

event DepositAdded(address indexed account, address indexed depositor, uint256 amount);

contract TestERC4337Account_addDeposit is Test, SmartAccountTestLab {
    SmartAccount private account;

    function setUp() public {
        init();
        account = BOB_ACCOUNT;
    }

    function test_AddDeposit_Success() public {
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));
        uint256 depositAmount = 1 ether;

        account.addDeposit{ value: depositAmount }();

        assertEq(
            balanceBefore + depositAmount,
            ENTRYPOINT.balanceOf(address(account)),
            "Deposit should be added to EntryPoint"
        );
    }

    function test_AddDeposit_EventEmitted() public {
        uint256 depositAmount = 1 ether;
        (bool res,) = address(account).call{ value: depositAmount }(""); // Pre-funding the account contract
        assertTrue(res, "Pre-funding account should succeed");

        // vm.expectEmit(true, true, true, true);
        // Todo: emit the event used by EntryPoint

        account.addDeposit{ value: depositAmount }();
    }

    function test_AddDeposit_Revert_NoValue() public {
        account.addDeposit();
    }

    function test_AddDeposit_DepositViaHandleOps() public {
        (bool res,) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund account with 2 ETH
        assertTrue(res, "Pre-funding account should succeed");
        uint256 depositAmount = 1 ether;
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_DEFAULT, execution);
        uint256 gasStart = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        uint256 gasUsed = gasStart - gasleft();

        // Using almostEq to compare balances with a tolerance for gas costs
        uint256 maxPercentDelta = 100_000_000_000;
        almostEq(
            balanceBefore + depositAmount - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            maxPercentDelta
        );
    }

    function test_AddDeposit_BatchDepositViaHandleOps() public {
        (bool res,) = payable(address(BOB_ACCOUNT)).call{ value: 10 ether }(""); // Fund account with 2 ETH
        assertTrue(res, "Pre-funding account should succeed");
        uint256 depositAmount = 1 ether;
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution[] memory executions = new Execution[](5);
        executions[0] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[1] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[2] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[3] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[4] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_DEFAULT, executions);
        uint256 gasStart = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        uint256 gasUsed = gasStart - gasleft();

        // Using almostEq to compare balances with a tolerance for gas costs
        uint256 maxPercentDelta = 100_000_000_000;
        almostEq(
            balanceBefore + (depositAmount * 5) - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            maxPercentDelta
        );
    }

    function test_AddDeposit_Try_DepositViaHandleOps() public {
        (bool res,) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund account with 2 ETH
        assertTrue(res, "Pre-funding account should succeed");
        uint256 depositAmount = 1 ether;
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_TRY, execution);
        uint256 gasStart = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        uint256 gasUsed = gasStart - gasleft();

        // Using almostEq to compare balances with a tolerance for gas costs
        uint256 maxPercentDelta = 100_000_000_000;
        almostEq(
            balanceBefore + depositAmount - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            maxPercentDelta
        );
    }

    function test_AddDeposit_Try_BatchDepositViaHandleOps() public {
        (bool res,) = payable(address(BOB_ACCOUNT)).call{ value: 10 ether }(""); // Fund account with 2 ETH
        assertTrue(res, "Pre-funding account should succeed");

        uint256 depositAmount = 1 ether;
        uint256 balanceBefore = ENTRYPOINT.balanceOf(address(account));

        Execution[] memory executions = new Execution[](5);
        executions[0] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[1] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[2] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[3] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));
        executions[4] = Execution(address(account), depositAmount, abi.encodeWithSignature("addDeposit()"));

        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, account, EXECTYPE_TRY, executions);
        uint256 gasStart = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        uint256 gasUsed = gasStart - gasleft();

        // Using almostEq to compare balances with a tolerance for gas costs
        uint256 maxPercentDelta = 100_000_000_000;
        almostEq(
            balanceBefore + (depositAmount * 5) - (gasUsed * tx.gasprice),
            ENTRYPOINT.balanceOf(address(account)),
            maxPercentDelta
        );
    }
}
