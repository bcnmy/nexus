// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/NexusTest_Base.t.sol";

/// @title AccountDepositBalanceInvariantTest
/// @notice Tests the consistency of the deposit balance on the ENTRYPOINT contract
contract AccountDepositBalanceInvariantTest is NexusTest_Base {
    uint256 private initialBalance;

    /// @notice Initializes the test environment and records the initial balance
    function setUp() public {
        init();
        initialBalance = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
    }

    /// @notice Tests the invariant that the deposit balance on the ENTRYPOINT must always closely match the expected amounts after transactions
    function invariant_depositBalanceConsistency() public {
        uint256 depositAmount = uint256(keccak256(abi.encodePacked(block.number, block.prevrandao))) % 50 ether;
        vm.deal(address(BOB_ACCOUNT), depositAmount + 1 ether); // Ensure account has enough ether

        // Prepare the deposit execution
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(BOB_ACCOUNT), value: depositAmount, callData: abi.encodeWithSignature("addDeposit()") });

        // Execute the deposit operation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Calculate the expected balance
        uint256 expectedBalance = initialBalance + depositAmount;
        uint256 actualBalance = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        // Use a small delta for balance checks to account for discrepancies
        uint256 allowedDelta = 0.001 ether;
        assertTrue(
            actualBalance >= expectedBalance - allowedDelta && actualBalance <= expectedBalance + allowedDelta,
            "Invariant failed: Deposit balance mismatch"
        );
    }
}
