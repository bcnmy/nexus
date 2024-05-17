// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/SmartAccountTestLab.t.sol";

contract AccountDepositBalanceInvariantTest is Test, SmartAccountTestLab {
    uint256 private initialBalance;

    function setUp() public {
        init();
        initialBalance = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
    }

    /// @notice Tests invariant that the deposit balance on the ENTRYPOINT must always closely match the expected amounts after transactions
    function invariantTest_depositBalanceConsistency() public {
        // Simulate a deposit operation
        uint256 depositAmount = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % 50 ether;
        vm.deal(address(BOB_ACCOUNT), depositAmount + 1 ether); // Ensure account has enough ether

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(BOB_ACCOUNT), value: depositAmount, callData: abi.encodeWithSignature("addDeposit()") });

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        uint256 expectedBalance = initialBalance + depositAmount;
        uint256 actualBalance = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));

        // Use a small delta for balance checks to account for discrepancies
        uint256 allowedDelta = 0.001 ether;
        assertTrue(
            actualBalance >= expectedBalance - allowedDelta && actualBalance <= expectedBalance + allowedDelta,
            "Invariant failed: Deposit balance mismatch"
        );

        // Update the initial balance for the next test run
        initialBalance = actualBalance;
    }
}
