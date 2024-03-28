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

    receive() external payable { }
}
