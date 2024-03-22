// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
// import {UserOperation} from "path/to/UserOperation.sol"; // Update this path

contract TestERC4337Account_GetDeposit is Test, SmartAccountTestLab {

uint initialDeposit;
    function setUp() public {
        init();
        initialDeposit = BOB_ACCOUNT.getDeposit();
    }

        function test_InitialDeposit() public {
        assertEq(BOB_ACCOUNT.getDeposit(), initialDeposit, "Initial deposit should be 0");
    }

    function test_DepositAfterAddDepositCall() public {
        uint balanceBefore = ENTRYPOINT.balanceOf(address(BOB_ACCOUNT));
        uint256 depositAmount = 2 ether;
        payable(address(BOB_ACCOUNT)).call{value: 1.5 ether}(""); // Sending ether to the account contract directly
        BOB_ACCOUNT.addDeposit{value: depositAmount}(); // Function that triggers a deposit to the EntryPoint

        // Using almostEq to compare balances with a tolerance for gas costs
        uint256 maxPercentDelta = 100_000_000_000;
        almostEq(balanceBefore + depositAmount, ENTRYPOINT.balanceOf(address(BOB_ACCOUNT)), maxPercentDelta);
    }
}
