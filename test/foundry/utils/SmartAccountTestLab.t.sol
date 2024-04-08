// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Helpers.sol";
import "./EventsAndErrors.sol";

contract SmartAccountTestLab is Helpers {
    SmartAccount public implementation;
    SmartAccount public smartAccount;

    function init() internal {
        initializeTestingEnvironment();
    }

    function _prefundSmartAccountAndAssertSuccess(address smartAccount, uint256 prefundAmount) internal {
        (bool res,) = smartAccount.call{ value: prefundAmount }(""); // Pre-funding the account contract
        assertTrue(res, "Pre-funding account should succeed");
    }

    receive() external payable { }
}
