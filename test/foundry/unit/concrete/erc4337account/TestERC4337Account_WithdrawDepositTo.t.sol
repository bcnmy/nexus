// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC4337Account_WithdrawDepositTo
/// @notice Tests for the withdrawDepositTo function in the ERC4337 account.
contract TestERC4337Account_WithdrawDepositTo is NexusTest_Base {
    uint256 private defaultDepositAmount;
    uint256 private defaultTolerance;

    /// @notice Sets up the testing environment.
    function setUp() public {
        init();
        BOB_ACCOUNT = BOB_ACCOUNT;
        defaultDepositAmount = 1 ether;
        defaultTolerance = 0.001 ether; // Tolerance for relative approximation
        // Prefund the account with initial deposit
        BOB_ACCOUNT.addDeposit{ value: defaultDepositAmount }();
    }

    /// @notice Tests successful withdrawal of deposit to a specified address.
    function test_WithdrawDepositTo_Success() public {
        address to = address(0x123);
        uint256 amount = 0.5 ether;
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 balanceBefore = to.balance;

        console.log("Deposit Before:", depositBefore);
        console.log("Balance Before:", balanceBefore);

        // Prepare and execute the user operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", to, amount)
        });
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        uint256 depositAfter = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 balanceAfter = to.balance;

        console.log("Deposit After:", depositAfter);
        console.log("Balance After:", balanceAfter);

        // Check balances after the operation
        assertApproxEqRel(balanceAfter, balanceBefore + amount, defaultTolerance, "Withdrawal amount should reflect in the 'to' address balance");
        assertApproxEqRel(
            depositAfter,
            depositBefore - amount - gasUsed * tx.gasprice,
            defaultTolerance,
            "Deposit should be reduced by the withdrawal amount and gas cost"
        );
    }

    /// @notice Tests withdrawal of deposit to an authorized address from the EntryPoint.
    function test_WithdrawDepositTo_AuthorizedAddress() public {
        address to = BOB.addr;
        uint256 amount = 0.5 ether;
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 balanceBefore = to.balance;

        console.log("Deposit Before:", depositBefore);
        console.log("Balance Before:", balanceBefore);

        // Prepare and execute the user operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", to, amount)
        });
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BUNDLER.addr);

        uint256 depositAfter = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 balanceAfter = to.balance;

        console.log("Deposit After:", depositAfter);
        console.log("Balance After:", balanceAfter);

        // Check balances after the operation
        assertApproxEqRel(balanceAfter, balanceBefore + amount, defaultTolerance, "Withdrawal amount should reflect in the 'to' address balance");
        assertApproxEqRel(
            depositAfter,
            depositBefore - amount - gasUsed * tx.gasprice,
            defaultTolerance,
            "Deposit should be reduced by the withdrawal amount and gas cost"
        );
    }

    /// @notice Tests withdrawal of deposit from the account itself.
    function test_WithdrawDepositTo_Self() public {
        address to = BOB.addr;
        uint256 amount = 0.5 ether;
        uint256 depositBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 balanceBefore = to.balance;

        console.log("Deposit Before:", depositBefore);
        console.log("Balance Before:", balanceBefore);

        // Prepare and execute the user operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", to, amount)
        });
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        uint256 gasUsed = handleUserOpAndMeasureGas(userOps, BOB.addr);

        uint256 depositAfter = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 balanceAfter = to.balance;

        console.log("Deposit After:", depositAfter);
        console.log("Balance After:", balanceAfter);

        // Check balances after the operation
        assertApproxEqRel(balanceAfter, balanceBefore + amount, defaultTolerance, "Withdrawal amount should reflect in BOB's address balance");
        assertApproxEqRel(
            depositAfter,
            depositBefore - amount - gasUsed * tx.gasprice,
            defaultTolerance,
            "Deposit should be reduced by the withdrawal amount and gas cost"
        );
    }

    /// @notice Tests withdrawal of deposit from an unauthorized address, expecting failure.
    function test_RevertIf_WithdrawDepositTo_UnauthorizedAddress() public {
        startPrank(ALICE.addr);

        // Prepare the user operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", BOB.addr, 0.5 ether)
        });

        // Expect revert due to unauthorized access
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.withdrawDepositTo(ALICE.addr, 0.5 ether);
        stopPrank();
    }

    /// @notice Tests withdrawal of deposit to a contract address, expecting failure.
    function test_RevertIf_WithdrawDepositTo_ContractAddress() public {
        startPrank(address(BOB_ACCOUNT));

        // Expect revert due to invalid target address
        vm.expectRevert();
        BOB_ACCOUNT.withdrawDepositTo(address(VALIDATOR_MODULE), 0.5 ether);
        stopPrank();
    }

    /// @notice Tests withdrawal of deposit exceeding available amount, expecting failure.
    function test_RevertIf_WithdrawDepositTo_ExceedsAvailable() public {
        address to = address(0x123);
        uint256 amount = 10000 ether; // Exceeding the available deposit

        startPrank(address(BOB_ACCOUNT));

        // Expect revert due to exceeding deposit
        vm.expectRevert();
        BOB_ACCOUNT.withdrawDepositTo(to, amount);
        stopPrank();
    }

    /// @notice Tests withdrawal of zero deposit.
    function test_WithdrawDepositTo_ZeroAmount() public {
        address to = address(0x123);
        uint256 amount = 0; // Zero amount

        // Prepare the user operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(BOB_ACCOUNT),
            value: 0,
            callData: abi.encodeWithSignature("withdrawDepositTo(address,uint256)", to, amount)
        });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Tests withdrawal of deposit to an address with insufficient gas, expecting failure.
    function test_RevertIf_WithdrawDepositTo_InsufficientGas() public {
        address to = address(0x123);
        uint256 amount = 0.5 ether;

        // Expect revert due to insufficient gas
        prank(address(BOB_ACCOUNT));
        vm.expectRevert();
        BOB_ACCOUNT.withdrawDepositTo{ gas: 1000 }(to, amount);
    }
}
