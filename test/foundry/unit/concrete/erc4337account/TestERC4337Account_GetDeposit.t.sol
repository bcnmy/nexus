// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC4337Account_GetDeposit
/// @notice Tests for the getDeposit function in the ERC4337 account.
contract TestERC4337Account_GetDeposit is NexusTest_Base {
    uint256 initialDeposit;
    uint256 defaultMaxPercentDelta;

    /// @notice Sets up the testing environment.
    function setUp() public {
        init();
        initialDeposit = BOB_ACCOUNT.getDeposit();
        defaultMaxPercentDelta = 100_000_000_000;
    }

    /// @notice Tests deposit amount after calling addDeposit.
    function test_DepositAfterAddDepositCall() public {
        uint256 depositAmount = 2 ether;
        BOB_ACCOUNT.addDeposit{ value: depositAmount }(); // Function that triggers a deposit to the EntryPoint
        almostEq(initialDeposit + depositAmount, ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)), defaultMaxPercentDelta);
    }
}
